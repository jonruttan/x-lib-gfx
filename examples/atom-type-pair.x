; atom-type-pair.x -- How an object says what it is, and the two smallest
; objects: the atom, its type object, and the pair (gfx/figure, gfx/scene)
;
; Usage:
;   x -f examples/atom-type-pair.x
;       draws the last frame and prints how many figures it holds and one
;       pixel of it
;
;   SCENES=web x -f examples/atom-type-pair.x
;       plays it in a browser; the page's address is printed on stderr
;
;   SCENES=sdl x -f examples/atom-type-pair.x
;       plays it in a window, on a host with SDL3
;
; What it shows is x-expr's include/x-obj.h: the atom and pair layouts, the
; type slot, and the built-in ATOM and PAIR type objects (src/x-obj.c).

(include-once "./stage.x")
(import x/num/float f-add f-sub f-div)

; --- Rows ------------------------------------------------------------------
;
; A row is a list of (NAME X COLOUR), its cells SIDE across on one Y.  VERB is
; the action each cell is placed with.

(def atp-row
  (fn (_ verb y side cells)
    (stage-all (List map (fn (_ c) (verb (first c) (stage-cell (first (rest c)) y side (first (rest (rest c)))))) cells))))

(def atp-gone (fn (_ names) (stage-all (List map stage-out names))))

(def atp-slide (fn (_ name fig) (stage-from name fig 3)))

; The header's three cells pressed into a strip from X0 to X1, Y0 to Y1: the
; data cell the strip stands left of is unchanged.
(def atp-strip
  (fn (_ names x0 x1 y0 y1)
    ((fn (_ third)
       (stage-all
         (List map (fn (_ c) (stage-to (first c) (stage-box (first (rest c)) y0 (f-add (first (rest c)) third) y1 stage-gold)))
                   (list (list (first names) x0)
                         (list (first (rest names)) (f-add x0 third))
                         (list (first (rest (rest names))) (f-add x0 (f-add third third)))))))
     (f-div (f-sub x1 x0) 3.0))))

; --- The beats -------------------------------------------------------------
;
; The refresher's row stands as episode 1 left it: units at x = -3, -1.8,
; -0.6 and 0.6, each 1.2 across.  From step 5 on the cells are 0.9 across:
; the type objects along y 2.5, the atoms along 0.3, the pair along -1.9.

(def atp-big
  (list (list "u0" -3 stage-gold) (list "u1" -1.8 stage-gold) (list "u2" -0.6 stage-gold) (list "u3" 0.6 stage-blue)))

(def atp-reading
  (fn (_ value tag)
    (stage-beat 0.5 (stage-swap "content" (stage-text value 0.6 0.5 0.36)) (stage-swap "tag" (stage-text tag 0.6 -0.45 0.2)))))

(def atp-part1
  (list
    ; 1: refresher, an object is a header and then data.
    (stage-beat 1.5)
    (stage-beat 0.8 (atp-row stage-in 0.5 1.2 atp-big) (stage-say "last time: an object"))
    (stage-beat 0.5 (stage-in "heap" (stage-text "heap" -3 1.45 0.2)) (stage-in "type" (stage-text "type" -1.8 1.45 0.2))
             (stage-in "flags" (stage-text "flags" -0.6 1.45 0.2)) (stage-in "data" (stage-text "data" 0.6 1.45 0.2)))
    (stage-beat 0.8 (stage-say "a header, then data")
             (stage-draw "pointer" (stage-arrow -3 -1.7 -3 -0.25 stage-pink))
             (stage-in "pointer-name" (stage-text "object pointer" -3 -2.05 0.2)))
    (stage-beat 0.6 (stage-in "at0" (stage-text "0" -3 2 0.2)) (stage-in "at1" (stage-text "1" -1.8 2 0.2))
             (stage-in "at2" (stage-text "2" -0.6 2 0.2)) (stage-in "at3" (stage-text "3" 0.6 2 0.2))
             (stage-draw "edge" (Figure stroke (Figure line 0 1.3 0 -0.3) stage-pink 0.06)))
    (stage-beat 1.4)))
(Heap collect)

(def atp-part2
  (list
    ; 2: episode 1's two rows; the shorter first.
    (stage-beat 0.6 (atp-gone (list "pointer" "pointer-name" "at0" "at1" "at2" "at3" "edge"))
             (stage-say "one unit of data, or two")
             (atp-row stage-to -1.6 1.2
                      (list (list "v0" -3 stage-gold) (list "v1" -1.8 stage-gold) (list "v2" -0.6 stage-gold)
                            (list "v3" 0.6 stage-blue) (list "v4" 1.8 stage-blue))))
    (stage-beat 1.3)
    (stage-beat 0.6 (atp-gone (list "v0" "v1" "v2" "v3" "v4")) (stage-say "the shorter one first"))
    (stage-beat 0.8)))
(Heap collect)

(def atp-part3
  (list
    ; 3: an atom is one unit of data.
    (atp-reading "42" "i  integer")
    (stage-beat 0.5 (stage-say "an atom: one unit of data") (stage-in "name" (stage-text "atom" -4.8 0.5 0.3)))
    (stage-beat 1.3)))
(Heap collect)

(def atp-part4
  (list
    ; 4: it holds any one reading, and nothing in it says which.
    (stage-beat 0.5 (stage-say "it can hold any one reading"))
    (atp-reading "'a'" "c  character")
    (stage-beat 1)
    (stage-beat 0.5 (stage-out "content") (stage-swap "tag" (stage-text "s  string" 0.6 -0.45 0.2))
             (stage-draw "reach" (stage-arrow 0.6 0.5 2.6 0.5 stage-grey))
             (stage-in "target" (stage-text "\"hello\"" 3.5 0.5 0.24)))
    (stage-beat 1)
    (stage-beat 0.5 (atp-gone (list "reach" "target")) (stage-say "nothing in it says which"))
    (atp-reading "42" "i  integer")
    (stage-beat 1.3)))
(Heap collect)

(def atp-part5
  (list
    ; 5: the type unit points at another object.
    (stage-beat 1 (stage-say "the type unit points at another object")
             (atp-gone (list "tag" "name"))
             (atp-row stage-to 0.3 0.9
                      (list (list "u0" -4 stage-gold) (list "u1" -3.1 stage-gold) (list "u2" -2.2 stage-gold)
                            (list "u3" -1.3 stage-blue)))
             (stage-to "content" (stage-text "42" -1.3 0.3 0.27))
             (stage-to "heap" (stage-text "heap" -4 -0.4 0.16)) (stage-to "type" (stage-text "type" -3.1 -0.4 0.16))
             (stage-to "flags" (stage-text "flags" -2.2 -0.4 0.16)) (stage-to "data" (stage-text "data" -1.3 -0.4 0.16)))
    (stage-beat 0.4 (stage-to "u1" (stage-cell -3.1 0.3 0.9 stage-pink)))
    (stage-beat 0.9 (stage-draw "u-type" (stage-arrow -3.1 0.75 1.25 2.05 stage-pink)))
    (stage-beat 0.6 (stage-to "u1" (stage-cell -3.1 0.3 0.9 stage-gold))
             (atp-row stage-in 2.5 0.9
                      (list (list "t0" 1.4 stage-gold) (list "t1" 2.3 stage-gold) (list "t2" 3.2 stage-gold)
                            (list "t3" 4.1 stage-blue))))
    (stage-beat 1)))
(Heap collect)

(def atp-part6
  (list
    ; 6: the type object is an atom; its one datum is the type's name.
    (stage-beat 0.5 (stage-say "a type object: an atom, its datum a name"))
    (stage-beat 0.8 (stage-draw "t-reach" (stage-arrow 4.1 2.5 5.05 2.5 stage-grey))
             (stage-in "t-name" (stage-text "\"ATOM\"" 5.8 2.5 0.22)))
    (stage-beat 1.3)))
(Heap collect)

(def atp-part7
  (list
    ; 7: built in, its own type and heap units are empty.
    (stage-beat 0.5 (stage-say "built in: its own type unit is empty")
             (stage-to "t0" (stage-cell 1.4 2.5 0.9 stage-pink)) (stage-to "t1" (stage-cell 2.3 2.5 0.9 stage-pink)))
    (stage-beat 1.5)
    (stage-beat 0.5 (stage-say "what empty is comes later")
             (stage-to "t0" (stage-cell 1.4 2.5 0.9 stage-gold)) (stage-to "t1" (stage-cell 2.3 2.5 0.9 stage-gold)))
    (stage-beat 1.2)))
(Heap collect)

(def atp-part8
  (list
    ; 8: every atom points at the one type object.
    (stage-beat 0.8 (stage-say "every atom points at the same type object")
             (atp-row atp-slide 0.3 0.9
                      (list (list "w0" 0 stage-gold) (list "w1" 0.9 stage-gold) (list "w2" 1.8 stage-gold)
                            (list "w3" 2.7 stage-blue)))
             (stage-in "w-content" (stage-text "'a'" 2.7 0.3 0.27)))
    (stage-beat 0.9 (stage-draw "w-type" (stage-arrow 0.9 0.75 1.55 2.05 stage-pink)))
    (stage-beat 1.2)
    (stage-beat 0.5 (stage-say "found by where it is, not by its name") (stage-to "t0" (stage-cell 1.4 2.5 0.9 stage-pink)))
    (stage-beat 1.3)))
(Heap collect)

(def atp-part9
  (list
    ; 9: a pair is two units of data, first and rest, with its own type.
    (stage-beat 0.6 (stage-say "a pair: two units of data") (stage-to "t0" (stage-cell 1.4 2.5 0.9 stage-gold))
             (atp-gone (list "heap" "type" "flags" "data")))
    (stage-beat 0.8 (atp-row atp-slide -1.9 0.9
                             (list (list "p0" -6 stage-gold) (list "p1" -5.1 stage-gold) (list "p2" -4.2 stage-gold)
                                   (list "p3" -3.3 stage-blue) (list "p4" -2.4 stage-blue))))
    (stage-beat 0.5 (stage-say "first and rest")
             (stage-in "first" (stage-text "first" -3.3 -2.6 0.16)) (stage-in "rest" (stage-text "rest" -2.4 -2.6 0.16)))
    (stage-beat 1)
    (stage-beat 0.6 (stage-say "and its own type object, PAIR")
             (atp-row stage-in 2.5 0.9
                      (list (list "q0" -6 stage-gold) (list "q1" -5.1 stage-gold) (list "q2" -4.2 stage-gold)
                            (list "q3" -3.3 stage-blue))))
    (stage-beat 0.9 (stage-draw "p-type" (stage-arrow -5.1 -1.45 -6 2.05 stage-pink))
             (stage-draw "q-reach" (stage-arrow -3.3 2.5 -2.35 2.5 stage-grey))
             (stage-in "q-name" (stage-text "\"PAIR\"" -1.6 2.5 0.22)))
    (stage-beat 1.3)))
(Heap collect)

(def atp-part10
  (list
    ; 10: each half of a pair can point at any object.
    (stage-beat 0.5 (stage-say "each half can point at any object"))
    (stage-beat 0.8 (stage-in "first-dot" (stage-dot -3.3 -1.9 stage-pink))
             (stage-draw "first-to" (stage-arrow -3.3 -1.9 -4 -0.15 stage-pink)))
    (stage-beat 0.8 (stage-in "rest-dot" (stage-dot -2.4 -1.9 stage-pink))
             (stage-draw "rest-to" (stage-arrow -2.4 -1.9 0 -0.15 stage-pink)))
    (stage-beat 1.5)))
(Heap collect)

(def atp-part11
  (list
    ; 11: the box-and-pointer drawing: each header pressed into a strip.
    (stage-beat 0.6 (stage-say "drawn small, the header is still there"))
    (stage-beat 1.2 (atp-gone (list "t0" "t1" "t2" "t3" "t-reach" "t-name" "q0" "q1" "q2" "q3" "q-reach" "q-name"
                                    "u-type" "w-type" "p-type" "first" "rest"))
             (atp-strip (list "u0" "u1" "u2") -2.11 -1.75 -0.15 0.75)
             (atp-strip (list "w0" "w1" "w2") 1.89 2.25 -0.15 0.75)
             (atp-strip (list "p0" "p1" "p2") -4.11 -3.75 -2.35 -1.45)
             (stage-to "first-to" (stage-arrow -3.3 -1.9 -1.93 -0.15 stage-pink))
             (stage-to "rest-to" (stage-arrow -2.4 -1.9 2.07 -0.15 stage-pink)))
    (stage-beat 1.5)))
(Heap collect)

(def atp-part12
  (list
    ; 12: a pair can point at a pair.
    (stage-beat 0.6 (stage-say "a pair can point at a pair")
             (stage-from "r3" (stage-cell 1.2 -1.9 0.9 stage-blue) 2) (stage-from "r4" (stage-cell 2.1 -1.9 0.9 stage-blue) 2)
             (stage-from "r0" (stage-box 0.39 -2.35 0.51 -1.45 stage-gold) 2)
             (stage-from "r1" (stage-box 0.51 -2.35 0.63 -1.45 stage-gold) 2)
             (stage-from "r2" (stage-box 0.63 -2.35 0.75 -1.45 stage-gold) 2))
    (stage-beat 1 (stage-to "rest-to" (stage-arrow -2.4 -1.9 0.39 -1.9 stage-pink)))
    (stage-beat 0.5 (stage-in "next" (stage-text "next" 4.2 -1.9 0.24)))
    (stage-beat 3)))
(Heap collect)

; A part is made, then the heap collected, so that making the figures of the
; whole script never holds more than one part of garbage.
(def atp-steps
  (List append atp-part1 atp-part2 atp-part3 atp-part4 atp-part5 atp-part6
               atp-part7 atp-part8 atp-part9 atp-part10 atp-part11 atp-part12))

; With no window, the last frame drawn 160 by 90: how many figures it holds,
; and a pixel inside the pair's first cell.
(stage-main "atom, type and pair" atp-steps
  (fn (_ figures)
    (do (display "figures ")
        (write (List length figures))
        (newline)
        (display "first ")
        (write (Canvas pixel (Scene frame figures () 1 160 90) 39 69))
        (newline))))
