; unit-and-object.x -- What every value is made of: the unit, and the object
; as a row of units, a header and then data (gfx/figure, gfx/scene)
;
; Usage:
;   x -f examples/unit-and-object.x
;       draws the last frame and prints how many figures it holds and one
;       pixel of it
;
;   SCENES=web x -f examples/unit-and-object.x
;       plays it in a browser; the page's address is printed on stderr
;
;   SCENES=sdl x -f examples/unit-and-object.x
;       plays it in a window, on a host with SDL3
;
; What it shows is x-expr's include/x-obj.h: the datum union, the object
; layout and the metadata accessors.

(include-once "./stage.x")

; --- The beats -------------------------------------------------------------
;
; The row's units stand at x = -3, -1.8, -0.6 and 0.6, each 1.2 across.

(def uo-reading
  (fn (_ value tag)
    (stage-beat 0.5 (stage-swap "content" (stage-text value 0 0.5 0.36)) (stage-swap "tag" (stage-text tag 0 -1.2 0.2)))))

(def uo-part1
  (list
    ; 1: one kind of cell.
    (stage-beat 1.5)
    (stage-beat 1.2 (stage-draw "u0" (stage-cell 0 0.5 1.2 stage-blue)))
    (stage-beat 0.5 (stage-in "name" (stage-text "unit" 0 -0.55 0.24)) (stage-say "one kind of cell"))
    (stage-beat 1.2)

    ))
(Heap collect)

(def uo-part2
  (list
    ; 2: six ways to read it.
    (stage-beat 0.5 (stage-say "six ways to read it"))
    (uo-reading "42" "i  integer")
    (stage-beat 1.3)
    (uo-reading "'a'" "c  character")
    (stage-beat 1.3)
    (stage-beat 0.5 (stage-out "content") (stage-swap "tag" (stage-text "s  string" 0 -1.2 0.2))
             (stage-draw "reach" (stage-arrow 0 0.5 2.3 0.5 stage-grey))
             (stage-in "target" (stage-text "\"hello\"" 3.2 0.5 0.24)))
    (stage-beat 1.3)
    (stage-beat 0.5 (stage-swap "tag" (stage-text "p  object" 0 -1.2 0.2))
             (stage-swap "target" (stage-cell 2.9 0.5 0.8 stage-blue)))
    (stage-beat 1.3)
    (stage-beat 0.5 (stage-swap "tag" (stage-text "fn  function" 0 -1.2 0.2))
             (stage-swap "target" (stage-text "code" 3.0 0.5 0.24)))
    (stage-beat 1.3)
    (stage-beat 0.5 (stage-swap "tag" (stage-text "v  opaque pointer" 0 -1.2 0.2)) (stage-out "target"))
    (stage-beat 1.3)

    ))
(Heap collect)

(def uo-part3
  (list
    ; 3: unit, the cell counted; datum, the cell read.
    (stage-beat 0.5 (stage-out "reach") (stage-out "tag") (stage-in "content" (stage-text "42" 0 0.5 0.36))
             (stage-say "datum: the cell read"))
    (stage-beat 0.4 (stage-swap "name" (stage-text "datum" 0 -0.55 0.24)))
    (stage-beat 1.2)
    (stage-beat 0.4 (stage-swap "name" (stage-text "unit" 0 -0.55 0.24)) (stage-say "unit: the cell counted"))
    (stage-beat 1.2)
    (stage-beat 0.5 (stage-say "nothing in the cell says which reading"))
    (stage-beat 1.6)

    ))
(Heap collect)

(def uo-part4
  (list
    ; 4: an object is a row of units.
    (stage-beat 0.5 (stage-out "content") (stage-out "name") (stage-say "an object: a row of units"))
    (stage-beat 0.8 (stage-to "u0" (stage-cell -3 0.5 1.2 stage-blue)))
    (stage-beat 0.5 (stage-from "u1" (stage-cell -1.8 0.5 1.2 stage-blue) 4))
    (stage-beat 0.5 (stage-from "u2" (stage-cell -0.6 0.5 1.2 stage-blue) 4))
    (stage-beat 0.5 (stage-from "u3" (stage-cell 0.6 0.5 1.2 stage-blue) 4))
    (stage-beat 1)

    ))
(Heap collect)

(def uo-part5
  (list
    ; 5: a header, then data.
    (stage-beat 0.8 (stage-say "a header, then data")
             (stage-to "u0" (stage-cell -3 0.5 1.2 stage-gold))
             (stage-to "u1" (stage-cell -1.8 0.5 1.2 stage-gold))
             (stage-to "u2" (stage-cell -0.6 0.5 1.2 stage-gold)))
    (stage-beat 0.5 (stage-in "heap" (stage-text "heap" -3 1.45 0.2)))
    (stage-beat 0.5 (stage-in "type" (stage-text "type" -1.8 1.45 0.2)))
    (stage-beat 0.5 (stage-in "flags" (stage-text "flags" -0.6 1.45 0.2)))
    (stage-beat 0.5 (stage-in "data" (stage-text "data" 0.6 1.45 0.2)))
    (stage-beat 1)

    ))
(Heap collect)

(def uo-part6
  (list
    ; 6: the pointer lands on the header; data starts at 3.
    (stage-beat 0.8 (stage-say "the pointer lands on the header")
             (stage-draw "pointer" (stage-arrow -3 -1.7 -3 -0.25 stage-pink))
             (stage-in "pointer-name" (stage-text "object pointer" -3 -2.05 0.2)))
    (stage-beat 0.8)
    (stage-beat 0.4 (stage-in "at0" (stage-text "0" -3 2 0.2)))
    (stage-beat 0.4 (stage-in "at1" (stage-text "1" -1.8 2 0.2)))
    (stage-beat 0.4 (stage-in "at2" (stage-text "2" -0.6 2 0.2)))
    (stage-beat 0.5 (stage-in "at3" (stage-text "3" 0.6 2 0.2))
             (stage-in "starts" (stage-text "data starts here" 3 2 0.2))
             (stage-draw "edge" (Figure stroke (Figure line 0 1.3 0 -0.3) stage-pink 0.06)))
    (stage-beat 1.4)

    ))
(Heap collect)

(def uo-part7
  (list
    ; 7: the header is made of the same cell.
    (stage-beat 0.6 (stage-say "the header is made of the same cell") (stage-out "starts")
             (stage-draw "probe" (stage-cell -3 3.1 0.6 stage-blue)))
    (stage-beat 0.6 (stage-to "probe" (Figure stroke (Figure shift (Figure square 1.2) -3 0.5) stage-blue 0.08))
             (stage-in "as0" (stage-text "p" -3 0.5 0.3)))
    (stage-beat 0.6)
    (stage-beat 0.6 (stage-to "probe" (Figure stroke (Figure shift (Figure square 1.2) -1.8 0.5) stage-blue 0.08))
             (stage-in "as1" (stage-text "p" -1.8 0.5 0.3)))
    (stage-beat 0.6)
    (stage-beat 0.6 (stage-to "probe" (Figure stroke (Figure shift (Figure square 1.2) -0.6 0.5) stage-blue 0.08))
             (stage-in "as2" (stage-text "i" -0.6 0.5 0.3)))
    (stage-beat 0.6)
    (stage-beat 0.5 (stage-out "probe"))
    (stage-beat 0.8)

    ))
(Heap collect)

(def uo-part8
  (list
    ; 8: the header is fixed; the data is any length.
    (stage-beat 0.6 (stage-say "the header is fixed, the data any length")
             (stage-out "pointer") (stage-out "pointer-name")
             (stage-out "at0") (stage-out "at1") (stage-out "at2") (stage-out "at3"))
    (stage-beat 0.5 (stage-from "d1" (stage-cell 1.8 0.5 1.2 stage-blue) 3))
    (stage-beat 0.5 (stage-from "d2" (stage-cell 3 0.5 1.2 stage-blue) 3))
    (stage-beat 0.5 (stage-to "d3" (stage-cell 4.2 0.5 1.2 stage-blue)) (stage-in "more" (stage-text "..." 5.3 0.5 0.3))
             (stage-in "dn" (stage-cell 6.4 0.5 1.2 stage-blue)) (stage-in "n" (stage-text "N" 6.4 0.5 0.3)))
    (stage-beat 1.6)

    ))
(Heap collect)

(def uo-part9
  (list
    ; 9: the two smallest lengths.
    (stage-beat 0.6 (stage-out "d1") (stage-out "d2") (stage-out "d3") (stage-out "more") (stage-out "dn") (stage-out "n")
             (stage-say "one unit of data, or two"))
    (stage-beat 0.8
             (stage-to "v0" (stage-cell -3 -1.6 1.2 stage-gold)) (stage-to "v1" (stage-cell -1.8 -1.6 1.2 stage-gold))
             (stage-to "v2" (stage-cell -0.6 -1.6 1.2 stage-gold)) (stage-to "v3" (stage-cell 0.6 -1.6 1.2 stage-blue))
             (stage-to "v4" (stage-cell 1.8 -1.6 1.2 stage-blue)))
    (stage-beat 0.5 (stage-in "next" (stage-text "next" 4.4 -0.55 0.24)))
    (stage-beat 3)))
(Heap collect)

; A part is made, then the heap collected, so that making the figures of the
; whole script never holds more than one part of garbage.
(def uo-steps
  (List append uo-part1 uo-part2 uo-part3 uo-part4 uo-part5 uo-part6 uo-part7 uo-part8 uo-part9))

; With no window, the last frame drawn 160 by 90: how many figures it holds,
; and a pixel inside the first header unit.
(stage-main "unit and object" uo-steps
  (fn (_ figures)
    (do (display "figures ")
        (write (List length figures))
        (newline)
        (display "header ")
        (write (Canvas pixel (Scene frame figures () 1 160 90) 42 35))
        (newline))))
