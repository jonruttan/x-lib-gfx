# Face: text set from a TrueType font's outlines
# @weight 2

A face is opened from a .ttf file; Roboto, Roboto Bold and Roboto Mono
ship with the library.  Text is set at a size in pixels to the em and
filled by gfx/shape with anti-aliased edges.

## reading the font

### the shipped face's metrics, at 16 pixels an em, in 1/256 of a pixel

Roboto's em is 2048 units, its ascent 1900, its descent 500 and its
capitals 1456 high: at 16 pixels an em, 1900 * 16 * 256 / 2048 is 3800.

```x
(do (import gfx/face)
  (Face metrics (Face shipped "Roboto-Regular") 16))
```
---
    (3800 1000 0 2912)

### the capitals' height is the top of H

At 8 pixels an em of 2048 units, a 256th of a pixel is a unit.

```x
(do (import gfx/face)
  (def f (Face shipped "Roboto-Regular"))
  (def top (List fold (fn (_ m p) (if (< m (List ref 1 p)) (List ref 1 p) m)) 0 (first (List ref 1 (Face glyph f 72)))))
  (list top (List ref 3 (Face metrics f 8))))
```
---
    (1456 1456)

### a glyph is its advance and its contours, points on and off the curve

H is one contour of twelve points, all on the curve; o is two, the outer
and the counter, with quadratic control points between.

```x
(do (import gfx/face)
  (def f (Face shipped "Roboto-Regular"))
  (def h (Face glyph f 72))
  (def o (Face glyph f 111))
  (list (first h) (List length (List ref 1 h)) (List length (first (List ref 1 h)))
        (List length (List ref 1 o))
        (if (List find (fn (_ p) (not (List ref 2 p))) (first (List ref 1 o))) #t #f)))
```
---
    (1460 1 12 2 #t)

### a composite glyph is its parts: e with an acute is e's two contours and the accent's one

```x
(do (import gfx/face)
  (def f (Face shipped "Roboto-Regular"))
  (def e (Face glyph f 101))
  (def ea (Face glyph f 233))
  (list (= (first e) (first ea)) (List length (List ref 1 e)) (List length (List ref 1 ea))))
```
---
    (#t 2 3)

### a character the face has not is the missing glyph

```x
(do (import gfx/face)
  (def f (Face shipped "Roboto-Regular"))
  (equal? (Face glyph f 9812) (Face glyph f 57344)))
```
---
    #t

## setting text

### the width is the advances added, at the size asked

```x
(do (import gfx/face)
  (def f (Face shipped "Roboto-Regular"))
  (list (Face width f "Hag" 16) (Face width f "Hag" 32) (Face width f "" 16)))
```
---
    (7446 14892 0)

### every character of the mono face moves the pen as far

```x
(do (import gfx/face)
  (def f (Face shipped "RobotoMono-Regular"))
  (= (Face width f "iiii" 20) (Face width f "MMMM" 20)))
```
---
    #t

### the bold face is wider than the regular

```x
(do (import gfx/face)
  (< (Face width (Face shipped "Roboto-Regular") "Bishop" 16) (Face width (Face shipped "Roboto-Bold") "Bishop" 16)))
```
---
    #t

### a mask: H's stem part-covers two columns, its counter is clear, and the baseline is on a whole pixel

The pen starts 3 pixels in at 16 pixels an em, and the baseline is the
pad and the ascent, 15 pixels, rounded up: 18.  The outlines are not
hinted, so H's left stem, a pixel and a half wide, part-covers the fifth
and sixth columns; its counter is clear.

```x
(do (import gfx/canvas) (import gfx/face)
  (def m (Face mask (Face shipped "Roboto-Regular") "Hag" 16))
  (def c (first m))
  (def a (fn (_ x y) (List ref 3 (Canvas pixel c x y))))
  (list (List ref 1 m) (List ref 2 m) (List ref 3 m) (first c) (List ref 1 c)
        (a 4 10) (a 5 10) (a 7 10) (a 4 20)))
```
---
    (3 18 7446 37 25 173 209 0 0)

### the empty string is an empty mask

```x
(do (import gfx/canvas) (import gfx/face)
  (def m (Face mask (Face shipped "Roboto-Regular") "" 16))
  (list (List ref 3 m) (Canvas pixel (first m) 0 0)))
```
---
    (0 (0 0 0 0))

### a file that is not there raises

```x
(guard (e (Err label e)) (do (import gfx/face) (Face open "/no/such/font.ttf")))
```
---
    'value
