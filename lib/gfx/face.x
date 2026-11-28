; # x-lib-gfx -- the graphics library for x-lang
;
; ## gfx/face.x -- Face: text set from a TrueType font's outlines
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; A face is a TrueType file read for its outlines.  Opening one reads the
; tables every glyph needs: head (the units an em is divided into and how
; loca is kept), hhea (the ascent, descent and line gap, and how many
; advances hmtx holds), hmtx, loca and cmap's Unicode subtable of format
; 4; and the capitals' height, OS/2's sCapHeight from its version 2, else
; the top of H.  A glyph's outline is read from glyf the first time it is
; asked for, with a read of its own bytes, and kept.
;
; An outline is contours of points in font units, y up, each point on the
; curve or a quadratic control point between two that are; two controls in
; a row have an on-curve point midway between them.  A composite glyph is
; its parts' outlines, each moved by its offset and scaled by its 2.14
; fixed-point scale when it has one.
;
; Text is set at a size in pixels to the em.  Each glyph's curves are
; flattened at that size into lines within a quarter pixel of them, its
; points in 1/256 of a pixel, and the whole string is filled at once by
; gfx/shape: non-zero winding, each pixel by the share of it inside.  The
; pen moves by each glyph's advance, kept in 1/256 of a pixel so the
; spacing does not drift; the baseline is on a whole pixel.  There is no
; hinting and no kerning: Roboto keeps its kerning in GPOS, which is not
; read.
;
; The fonts in fonts/ are Roboto, Roboto Bold and Roboto Mono, by
; Christian Robertson for Google, under the Apache License 2.0 beside
; them.

(module gfx/face)

(import gfx/canvas)
(import gfx/shape)
(import x/sys/file)
(import x/sys/bundle)
(import x/core/doors char->int int& int* int+ int- int/ int< int= str-byte-len str-byte-ref str-make)

(def %fail (fn (_ what) (Err raise (lit value) (Str8 append "Face: " what) ())))

; --- bytes ----------------------------------------------------------------------------

(def %u8 (fn (_ s i) (int& (char->int (str-byte-ref s i)) 255)))
(def %u16 (fn (_ s i) (int+ (int* 256 (%u8 s i)) (%u8 s (int+ i 1)))))
(def %s16 (fn (_ s i) ((fn (_ u) (if (int< u 32768) u (int- u 65536))) (%u16 s i))))
(def %u32 (fn (_ s i) (int+ (int* 65536 (%u16 s i)) (%u16 s (int+ i 2)))))

; N bytes of the file at PATH from byte AT.
(def %read
  (fn (_ path at n)
    (def fd (File open path (lit rdonly)))
    (when (int< fd 0) (%fail (Str8 append "cannot open " path)))
    (def buf (str-make (if (int< n 1) 1 n)))
    (File seek fd at)
    (def got (if (int< n 1) 0 (File read fd buf n)))
    (File close fd)
    (unless (int= got n) (%fail (Str8 append "short read in " path)))
    buf))

; The table directory: ((TAG OFFSET LENGTH) ...).
(def %tables
  (fn (_ path)
    (def head (%read path 0 12))
    (def n (%u16 head 4))
    (def dir (%read path 12 (int* 16 n)))
    ((fn (self i acc)
       (if (int= i n) acc
         (self (int+ i 1)
           (pair (list (%u32 dir (int* 16 i)) (%u32 dir (int+ (int* 16 i) 8)) (%u32 dir (int+ (int* 16 i) 12))) acc))))
     0 ())))

; A table's tag as the number its four bytes make.
(def %tag (fn (_ tag) (%u32 tag 0)))

; The directory's entry for TAG.
(def %entry
  (fn (_ path dir tag)
    (def t (List find (fn (_ e) (int= (first e) (%tag tag))) dir))
    (when (null? t) (%fail (Str8 append "no " tag " table in " path)))
    t))

(def %table
  (fn (_ path dir tag)
    ((fn (_ t) (%read path (List ref 1 t) (List ref 2 t))) (%entry path dir tag))))

; cmap's subtable of format 4 for Unicode: platform 3 encoding 1, or
; platform 0.
(def %cmap4
  (fn (_ path dir)
    (def from (List ref 1 (%entry path dir "cmap")))
    (def cmap (%table path dir "cmap"))
    (def n (%u16 cmap 2))
    (def at
      ((fn (self i)
         (if (int= i n) ()
           ((fn (_ rec)
              (def pid (%u16 cmap rec))
              (def eid (%u16 cmap (int+ rec 2)))
              (def off (%u32 cmap (int+ rec 4)))
              (if (if (if (int= pid 3) (int= eid 1) (int= pid 0)) (int= 4 (%u16 cmap off)) #f) off (self (int+ i 1))))
            (int+ 4 (int* 8 i)))))
       0))
    (when (null? at) (%fail (Str8 append "no Unicode cmap of format 4 in " path)))
    (%read path (int+ from at) (%u16 cmap (int+ at 2)))))

; The glyph index of CODE by a format 4 subtable, 0 when there is none.
(def %index
  (fn (_ t code)
    (def segs (int/ (%u16 t 6) 2))
    (def ends 14)
    (def starts (int+ 16 (int* 2 segs)))
    (def deltas (int+ starts (int* 2 segs)))
    (def ranges (int+ deltas (int* 2 segs)))
    ((fn (self i)
       (if (int= i segs) 0
         (if (int< (%u16 t (int+ ends (int* 2 i))) code) (self (int+ i 1))
           ((fn (_ start delta range)
              (match
                ((int< code start) 0)
                ((int= range 0) (int& (int+ code delta) 65535))
                (#t ((fn (_ g) (if (int= g 0) 0 (int& (int+ g delta) 65535)))
                     (%u16 t (int+ (int+ ranges (int* 2 i)) (int+ range (int* 2 (int- code start)))))))))
            (%u16 t (int+ starts (int* 2 i))) (%u16 t (int+ deltas (int* 2 i))) (%u16 t (int+ ranges (int* 2 i)))))))
     0)))

; --- the face -------------------------------------------------------------------------
;
; A face is a vector: its path, units an em, ascent, descent, line gap,
; cmap's subtable, hmtx, how many advances hmtx holds, loca, whether loca
; is long, glyf's offset, the glyphs read, in 64 buckets of
; (INDEX . (ADVANCE CONTOURS)), and the capitals' height.

(def %path 0) (def %upm 1) (def %ascent 2) (def %descent 3) (def %gap 4) (def %cmap 5)
(def %hmtx 6) (def %advances 7) (def %loca 8) (def %long 9) (def %glyf 10) (def %read-glyphs 11)
(def %cap 12)

(def %get (fn (_ f k) (Vector ref k f)))

(def %advance
  (fn (_ f g)
    (def n (%get f %advances))
    (%u16 (%get f %hmtx) (int* 4 (if (int< g n) g (int- n 1))))))

; Where glyph G's bytes start in glyf, and how many there are.
(def %span
  (fn (_ f g)
    (def l (%get f %loca))
    (if (%get f %long)
      (pair (%u32 l (int* 4 g)) (int- (%u32 l (int* 4 (int+ g 1))) (%u32 l (int* 4 g))))
      (pair (int* 2 (%u16 l (int* 2 g))) (int* 2 (int- (%u16 l (int* 2 (int+ g 1))) (%u16 l (int* 2 g))))))))

; A simple glyph's contours from its bytes S, N of them: each a list of
; (X Y ON).
(def %simple
  (fn (_ s n)
    (def ends (List map (fn (_ i) (%u16 s (int+ 10 (int* 2 i)))) (List range 0 n)))
    (def count (int+ 1 (List last ends)))
    (def at (int+ (int+ 10 (int* 2 n)) (int+ 2 (%u16 s (int+ 10 (int* 2 n))))))
    ; the flags, each repeated as its repeat byte says; the byte after them
    (def flags
      ((fn (self i k acc)
         (if (int< k count)
           ((fn (_ f)
              (if (int= 0 (int& f 8))
                (self (int+ i 1) (int+ k 1) (pair f acc))
                ((fn (_ r) (self (int+ i 2) (int+ k (int+ r 1))
                             (List append (List map (fn (_ j) f) (List range 0 (int+ r 1))) acc)))
                 (%u8 s (int+ i 1)))))
            (%u8 s i))
           (pair (List reverse acc) i)))
       at 0 ()))
    ; coordinates by SHORT and SAME bits: the values and the byte after them
    (def coords
      (fn (_ from short same)
        ((fn (self fs i v acc)
           (if (null? fs) (pair (List reverse acc) i)
             ((fn (_ f)
                (match
                  ((int< 0 (int& f short))
                    ((fn (_ d) (self (rest fs) (int+ i 1) d (pair d acc)))
                     (if (int< 0 (int& f same)) (int+ v (%u8 s i)) (int- v (%u8 s i)))))
                  ((int< 0 (int& f same)) (self (rest fs) i v (pair v acc)))
                  (#t ((fn (_ d) (self (rest fs) (int+ i 2) d (pair d acc))) (int+ v (%s16 s i))))))
              (first fs))))
         (List take count (first flags)) from 0 ())))
    (def xs (coords (rest flags) 2 16))
    (def ys (coords (rest xs) 4 32))
    (def points
      ((fn (self fs xl yl acc)
         (if (null? fs) (List reverse acc)
           (self (rest fs) (rest xl) (rest yl)
             (pair (list (first xl) (first yl) (int< 0 (int& (first fs) 1))) acc))))
       (List take count (first flags)) (first xs) (first ys) ()))
    ((fn (self ps es k cur acc)
       (match
         ((null? es) (List reverse acc))
         ((int< (first es) k) (self ps (rest es) k () (pair (List reverse cur) acc)))
         (#t (self (rest ps) es (int+ k 1) (pair (first ps) cur) acc))))
     points ends 0 () ())))

; A composite glyph's contours from its bytes S: each part's, moved and
; scaled.
(def %composite
  (fn (_ f s)
    ((fn (self i acc)
       (def flags (%u16 s i))
       (def g (%u16 s (int+ i 2)))
       (def words (int< 0 (int& flags 1)))
       (def dx (if words (%s16 s (int+ i 4)) ((fn (_ b) (if (int< b 128) b (int- b 256))) (%u8 s (int+ i 4)))))
       (def dy (if words (%s16 s (int+ i 6)) ((fn (_ b) (if (int< b 128) b (int- b 256))) (%u8 s (int+ i 5)))))
       (def after (int+ i (if words 8 6)))
       ; the scale, x and y, in 2.14; and where the next part starts
       (def scale
         (match
           ((int< 0 (int& flags 8)) (list (%s16 s after) (%s16 s after) (int+ after 2)))
           ((int< 0 (int& flags 64)) (list (%s16 s after) (%s16 s (int+ after 2)) (int+ after 4)))
           ((int< 0 (int& flags 128)) (list (%s16 s after) (%s16 s (int+ after 6)) (int+ after 8)))
           (#t (list 16384 16384 after))))
       (def sx (first scale))
       (def sy (List ref 1 scale))
       (def part
         (List map
           (fn (_ c) (List map (fn (_ p) (list (int+ dx (int/ (int* (first p) sx) 16384)) (int+ dy (int/ (int* (List ref 1 p) sy) 16384)) (List ref 2 p))) c))
           (List ref 1 (%glyph f g))))
       (def all (List append acc part))
       (if (int< 0 (int& flags 32)) (self (List ref 2 scale) all) all))
     10 ())))

; Glyph G: (ADVANCE CONTOURS), read and kept the first time.
(def %glyph
  (fn (_ f g)
    (def buckets (%get f %read-glyphs))
    (def b (int& g 63))
    (def hit (List find (fn (_ e) (int= (first e) g)) (Vector ref b buckets)))
    (if (not (null? hit)) (rest hit)
      ((fn (_ sp)
         (def s (if (int= (rest sp) 0) () (%read (%get f %path) (int+ (%get f %glyf) (first sp)) (rest sp))))
         (def contours
           (match ((null? s) ())
                  ((int< (%s16 s 0) 0) (%composite f s))
                  (#t (%simple s (%s16 s 0)))))
         (def gl (list (%advance f g) contours))
         (Vector set! b (pair (pair g gl) (Vector ref b buckets)) buckets)
         gl)
       (%span f g)))))

; The top of H: its highest point, in font units.
(def %top
  (fn (_ f)
    (List fold (fn (_ m c) (List fold (fn (_ m p) (if (int< m (List ref 1 p)) (List ref 1 p) m)) m c))
      0 (List ref 1 (%glyph f (%index (%get f %cmap) 72))))))

; The capitals' height: OS/2's sCapHeight, which its version 2 added, else
; the top of H.
(def %cap-height
  (fn (_ f path dir)
    (def os2 (List find (fn (_ e) (int= (first e) (%tag "OS/2"))) dir))
    (def given
      (if (if (null? os2) #f (int< 89 (List ref 2 os2)))
        ((fn (_ t) (if (int< 1 (%u16 t 0)) (%s16 t 88) 0)) (%read path (List ref 1 os2) 90))
        0))
    (if (int< 0 given) given (%top f))))

; --- setting --------------------------------------------------------------------------

; The characters of UTF-8 TEXT as codes.
(def %codes
  (fn (_ text)
    (def n (str-byte-len text))
    (def b (fn (_ i) (if (int< i n) (%u8 text i) 0)))
    (def cont (fn (_ i) (int& (b i) 63)))
    ((fn (self i acc)
       (match
         ((not (int< i n)) (List reverse acc))
         ((int< (b i) 128) (self (int+ i 1) (pair (b i) acc)))
         ((int< (b i) 192) (self (int+ i 1) acc))
         ((int< (b i) 224) (self (int+ i 2) (pair (int+ (int* 64 (int& (b i) 31)) (cont (int+ i 1))) acc)))
         ((int< (b i) 240) (self (int+ i 3) (pair (int+ (int* 4096 (int& (b i) 15)) (int+ (int* 64 (cont (int+ i 1))) (cont (int+ i 2)))) acc)))
         (#t (self (int+ i 4) (pair (int+ (int* 262144 (int& (b i) 7)) (int+ (int* 4096 (cont (int+ i 1))) (int+ (int* 64 (cont (int+ i 2))) (cont (int+ i 3))))) acc)))))
     0 ())))

(def %isqrt
  (fn (_ n) ((fn (self r) (if (int< n (int* (int+ r 1) (int+ r 1))) r (self (int+ r 1)))) 0)))

(def %abs (fn (_ v) (if (int< v 0) (int- 0 v) v)))

; The points after P0 of the quadratic from P0 through control C to P2,
; within a quarter pixel of it: (X . Y) in 1/256 of a pixel.
(def %quad
  (fn (_ p0 c p2)
    (def dev (int+ (%abs (int+ (int- (first p0) (int* 2 (first c))) (first p2)))
                   (%abs (int+ (int- (rest p0) (int* 2 (rest c))) (rest p2)))))
    (def n (int+ 1 (%isqrt (int/ dev 128))))
    (List map
      (fn (_ k)
        (def a (int* (int- n k) (int- n k)))
        (def m (int* 2 (int* k (int- n k))))
        (def z (int* k k))
        (def nn (int* n n))
        (pair (int/ (int+ (int* a (first p0)) (int+ (int* m (first c)) (int* z (first p2)))) nn)
              (int/ (int+ (int* a (rest p0)) (int+ (int* m (rest c)) (int* z (rest p2)))) nn)))
      (List range 1 (int+ n 1)))))

(def %mid (fn (_ a b) (pair (int/ (int+ (first a) (first b)) 2) (int/ (int+ (rest a) (rest b)) 2))))

; A contour of (P . ON) points flattened into (X . Y) points.
(def %flatten
  (fn (_ pts)
    (def on (List find rest pts))
    ; begin at an on-curve point, or midway between the first two controls
    (def ring
      (if (null? on)
        (pair (pair (%mid (first (first pts)) (first (List ref 1 pts))) #t) pts)
        ((fn (self l pre) (if (rest (first l)) (List append l (List reverse pre)) (self (rest l) (pair (first l) pre)))) pts ())))
    (def start (first (first ring)))
    ((fn (self l prev ctrl acc)
       (if (null? l)
         (List reverse (if (null? ctrl) acc (List append (List reverse (%quad prev ctrl start)) acc)))
         ((fn (_ p on?)
            (match
              ((if on? (null? ctrl) #f) (self (rest l) p () (pair p acc)))
              (on? (self (rest l) p () (List append (List reverse (%quad prev ctrl p)) acc)))
              ((null? ctrl) (self (rest l) prev p acc))
              (#t ((fn (_ m) (self (rest l) m p (List append (List reverse (%quad prev ctrl m)) acc))) (%mid ctrl p)))))
          (first (first l)) (rest (first l)))))
     (rest ring) start () (list start))))

; The outline of the codes CODES at PX pixels an em, the pen starting at
; X0 Y0 (the baseline) in 1/256 of a pixel: (CONTOURS . ADVANCE).
(def %outline
  (fn (_ f codes px x0 y0)
    (def upm (%get f %upm))
    (def k (int* px 256))
    ((fn (self cs x acc)
       (if (null? cs) (pair acc (int- x x0))
         ((fn (_ gl)
            (def placed
              (List map
                (fn (_ c)
                  (%flatten (List map (fn (_ p) (pair (pair (int+ x (int/ (int* (first p) k) upm)) (int- y0 (int/ (int* (List ref 1 p) k) upm))) (List ref 2 p))) c)))
                (List ref 1 gl)))
            (self (rest cs) (int+ x (int/ (int* (first gl) k) upm)) (List append placed acc)))
          (%glyph f (%index (%get f %cmap) (first cs))))))
     codes x0 ())))

(def %up (fn (_ v d) (int/ (int+ v (int- d 1)) d)))

(def-class Face ()
  (doc "Text set from a TrueType font's outlines, filled with anti-aliased edges. A face is opened from a .ttf file; its glyphs are read as they are first used. Text is set at a size in pixels to the em, on a whole-pixel baseline, with no hinting and no kerning. Roboto, Roboto Bold and Roboto Mono ship with the library."
    (sample "(Face mask (Face shipped \"Roboto-Regular\") \"Hello\" 16)" "(CANVAS PAD BASELINE ADVANCE)")
    (see open) (see shipped) (see mask) (see width))
  (static
    (method open (self (param path STRING "A TrueType (.ttf) file"))
      (doc "Read a face's tables from a TrueType file: what every glyph needs; the glyphs themselves are read when first used. Raises a label 'value when the file cannot be read or lacks head, hhea, hmtx, loca, glyf or a Unicode cmap of format 4."
        (returns VECTOR "The face")
        (sample "(Face open \"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf\")" "a face"))
      (def dir (%tables path))
      (def head (%table path dir "head"))
      (def hhea (%table path dir "hhea"))
      (def glyf (%entry path dir "glyf"))
      (def f (Vector make 13 ()))
      (Vector set! %path path f)
      (Vector set! %upm (%u16 head 18) f)
      (Vector set! %ascent (%s16 hhea 4) f)
      (Vector set! %descent (%s16 hhea 6) f)
      (Vector set! %gap (%s16 hhea 8) f)
      (Vector set! %cmap (%cmap4 path dir) f)
      (Vector set! %hmtx (%table path dir "hmtx") f)
      (Vector set! %advances (%u16 hhea 34) f)
      (Vector set! %loca (%table path dir "loca") f)
      (Vector set! %long (int= 1 (%s16 head 50)) f)
      (Vector set! %glyf (List ref 1 glyf) f)
      (Vector set! %read-glyphs (Vector make 64 ()) f)
      (Vector set! %cap (%cap-height f path dir) f)
      f)

    (method shipped (self (param name STRING "Roboto-Regular, Roboto-Bold or RobotoMono-Regular"))
      (doc "Open one of the faces that ship with the library, by its file's name without .ttf."
        (returns VECTOR "The face")
        (sample "(Face shipped \"Roboto-Regular\")" "a face"))
      (def root (Bundle root "gfx"))
      (when (null? root) (%fail "the gfx bundle is not loaded"))
      (Face open (Str8 append root "/lib/gfx/fonts/" name ".ttf")))

    (method metrics (self (param face VECTOR "A face") (param px INTEGER "Pixels an em"))
      (doc "The face's ascent above the baseline, descent below it, line gap and capitals' height, at PX pixels an em, in 1/256 of a pixel. At 1 pixel an em CAP is the capitals' share of the em, for the size that gives capitals of a height."
        (returns LIST "(ASCENT DESCENT GAP CAP)")
        (sample "(Face metrics (Face shipped \"Roboto-Regular\") 16)" "(3800 1000 0 2912)"))
      (def u (%get face %upm))
      (List map (fn (_ v) (int/ (int* (%abs v) (int* px 256)) u))
        (list (%get face %ascent) (%get face %descent) (%get face %gap) (%get face %cap))))

    (method glyph (self (param face VECTOR "A face") (param code INTEGER "A character's code"))
      (doc "The character's glyph in font units, y up: its advance and its contours, each a list of (X Y ON), ON #f for a quadratic control point. A character the face has not is its glyph 0, the missing-glyph box."
        (returns LIST "(ADVANCE CONTOURS)")
        (sample "(Face glyph (Face shipped \"Roboto-Regular\") 108)" "(479 (((...) ...)))"))
      (%glyph face (%index (%get face %cmap) code)))

    (method width (self (param face VECTOR "A face") (param text STRING "UTF-8 text") (param px INTEGER "Pixels an em"))
      (doc "How far TEXT moves the pen at PX pixels an em, in 1/256 of a pixel."
        (returns INTEGER "The advance")
        (sample "(Face width (Face shipped \"Roboto-Regular\") \"Hello\" 16)" "the advance"))
      (def u (%get face %upm))
      (def k (int* px 256))
      (List fold (fn (_ x c) (int+ x (int/ (int* (first (%glyph face (%index (%get face %cmap) c))) k) u))) 0 (%codes text)))

    (method mask (self (param face VECTOR "A face") (param text STRING "UTF-8 text") (param px INTEGER "Pixels an em"))
      (doc "TEXT set at PX pixels an em as a mask: a canvas whose alpha is each pixel's share of ink, the pen starting PAD pixels in and the baseline BASELINE pixels down. ADVANCE is how far the pen moved, in 1/256 of a pixel. Stamp it with (Canvas stamp!) in a colour."
        (returns LIST "(CANVAS PAD BASELINE ADVANCE)")
        (sample "(Face mask (Face shipped \"Roboto-Regular\") \"Hello\" 16)" "(CANVAS 1 16 ...)"))
      (def m (Face metrics face px))
      (def pad (int+ 1 (int/ px 8)))
      (def base (int+ pad (%up (first m) 256)))
      (def o (%outline face (%codes text) px (int* pad 256) (int* base 256)))
      (def c (Canvas make (int+ (int* 2 pad) (int+ 1 (%up (rest o) 256))) (int+ base (int+ pad (%up (List ref 1 m) 256)))))
      (unless (null? (first o)) (Shape fill! c (first o) (list 255 255 255)))
      (list c pad base (rest o)))))

(doc (provide gfx/face Face)
  "Text from TrueType outlines: (Face shipped \"Roboto-Regular\") opens a face, (Face mask face text px) sets text as an anti-aliased mask, (Face width face text px) measures it."
  (sample "(Face width (Face shipped \"Roboto-Regular\") \"Hi\" 16)" "the advance"))
