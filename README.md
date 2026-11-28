# x-lib-gfx

Graphics for [x-lang](https://github.com/jonruttan/x-lang), written in x: an
RGBA canvas, filled and stroked outlines, a stroke font, text set from
TrueType fonts, figures that move and change, and scenes played as frames.

x-lib-gfx holds the bundle `gfx`. It is a library: it has modules and no
entry, so there is nothing to start with `x -l`. A program imports what it
uses.

```x
(import gfx/canvas)
(Canvas pixel (Canvas make 4 4) 0 0)
```

## Modules

| Module | Class | |
|---|---|---|
| `gfx/canvas` | `Canvas` | an RGBA picture in memory, and the operations a frame is drawn with |
| `gfx/shape` | `Shape` | outlines filled and stroked on a canvas, anti-aliased |
| `gfx/font` | `Font` | the printable ASCII characters as strokes |
| `gfx/face` | `Face` | text set from a TrueType font's outlines, anti-aliased; Roboto, Roboto Bold and Roboto Mono ship with it |
| `gfx/figure` | `Figure` | outlines with a fill and a stroke, placed and changed over time |
| `gfx/scene` | `Scene` | figures and animations drawn as frames, and played |

## Using it

Installed under x's `bundles/` directory, an import of a `gfx/` module finds
it with nothing declared:

```sh
make install
```

A bundle that depends on it says so in its `bundle.xon`:

```x
(requires-bundle "gfx")
```

`examples/` holds three programs that play scenes: `scenes.x`, `story.x` and
`unit-and-object.x`.

## Working on it

```sh
make check
```

```sh
make doctest
```

## Licence

MIT No Attribution.  The fonts in `lib/gfx/fonts/` are Roboto, Roboto Bold
and Roboto Mono by Christian Robertson for Google, under the Apache License
2.0 beside them.
