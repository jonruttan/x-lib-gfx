; stage.x -- What the explainer scenes share: their colours and cells, named
; figures on a stage, beats of actions, and the three ways to run them
; (gfx/figure, gfx/scene)
;
; A scene includes this file and hands stage-main its title, its steps and
; what to print of its last frame:
;
;   (include-once "./stage.x")
;   (stage-main "title" steps (fn (_ figures) ...))
;
; Each episode draws a part of x with the same definitions, so a refresher
; shows the earlier episode's picture.

(import gfx/canvas)
(import gfx/figure)
(import gfx/scene)
(import x/num/float)
(import x/num/float/literal)
(import x/sys/posix)

; --- Figures ---------------------------------------------------------------

(def stage-blue (list 88 196 221))
(def stage-gold (list 240 190 80))
(def stage-pink (list 209 71 189))
(def stage-grey (list 150 150 150))
(def stage-dark (list 20 40 60))

; A cell SIDE across about X Y, outlined in COLOUR.
(def stage-cell
  (fn (_ x y side colour)
    (Figure shift (Figure fill (Figure stroke (Figure square side) colour 0.05) stage-dark) x y)))

; A box from X0 Y0 to X1 Y1, outlined in COLOUR: a cell drawn narrow.
(def stage-box
  (fn (_ x0 y0 x1 y1 colour)
    (Figure fill (Figure stroke (Figure polygon (list (list x1 y1) (list x0 y1) (list x0 y0) (list x1 y0))) colour 0.05)
                 stage-dark)))

; TEXT, a capital HEIGHT high, about X Y.
(def stage-text (fn (_ text x y height) (Figure shift (Figure label text height) x y)))

(def stage-arrow (fn (_ x0 y0 x1 y1 colour) (Figure stroke (Figure arrow x0 y0 x1 y1) colour 0.05)))

; The dot a pointer leaves from, at X Y.
(def stage-dot
  (fn (_ x y colour) (Figure shift (Figure fill (Figure stroke (Figure circle 0.08) colour 0.02) colour) x y)))

; A figure with nothing of it showing: what a figure fades in from.
(def stage-clear (fn (_ fig) ((Figure fade-out fig) 1)))

; --- The stage -------------------------------------------------------------
;
; A state is the named figures on the stage, in the order they are drawn:
; ((NAME . FIGURE) ...).  An action is a function of a state that answers
; (NAMES ANIMATIONS STATE): the names it animates, their animations, and the
; state once they are done.  A beat runs its actions together.

(def stage-get
  (fn (self state name)
    (match ((null? state) ())
           ((str=? (first (first state)) name) (rest (first state)))
           (#t (self (rest state) name)))))

(def stage-del
  (fn (self state name)
    (match ((null? state) ())
           ((str=? (first (first state)) name) (rest state))
           (#t (pair (first state) (self (rest state) name))))))

; NAME's figure becomes FIG where it stands in the order, or is added last.
(def stage-set
  (fn (self state name fig)
    (match ((null? state) (list (pair name fig)))
           ((str=? (first (first state)) name) (pair (pair name fig) (rest state)))
           (#t (pair (first state) (self (rest state) name fig))))))

(def stage-has?
  (fn (self names name)
    (match ((null? names) #f)
           ((str=? (first names) name) #t)
           (#t (self (rest names) name)))))

; FIG fades in as NAME.
(def stage-in
  (fn (_ name fig)
    (fn (_ state) (list (list name) (list (Figure morph (stage-clear fig) fig)) (stage-set state name fig)))))

; FIG slides in as NAME from DX to its right, fading in on the way.
(def stage-from
  (fn (_ name fig dx)
    (fn (_ state)
      (list (list name) (list (Figure morph (Figure shift (stage-clear fig) dx 0) fig)) (stage-set state name fig)))))

; FIG is drawn in as NAME, from its first point on.
(def stage-draw
  (fn (_ name fig)
    (fn (_ state) (list (list name) (list (Figure create fig)) (stage-set state name fig)))))

; NAME fades out and is gone; no NAME, nothing happens.
(def stage-out
  (fn (_ name)
    (fn (_ state)
      ((fn (_ old)
         (if (null? old)
           (list () () state)
           (list (list name) (list (Figure fade-out old)) (stage-del state name))))
       (stage-get state name)))))

; NAME becomes FIG by a morph; no NAME, FIG fades in.
(def stage-to
  (fn (_ name fig)
    (fn (_ state)
      ((fn (_ old)
         (if (null? old)
           ((stage-in name fig) state)
           (list (list name) (list (Figure morph old fig)) (stage-set state name fig))))
       (stage-get state name)))))

; NAME's figure fades out as FIG fades in under the same name: how text
; changes.
(def stage-swap
  (fn (_ name fig)
    (fn (_ state)
      ((fn (_ old)
         (if (null? old)
           ((stage-in name fig) state)
           (list (list name)
                 (list (Figure fade-out old) (Figure morph (stage-clear fig) fig))
                 (stage-set state name fig))))
       (stage-get state name)))))

; The line of words under the stage becomes TEXT.
(def stage-say (fn (_ text) (stage-swap "caption" (stage-text text 0 -3.5 0.26))))

; The list of ACTIONS as one action: each acts on the state the one before
; it left.
(def stage-all
  (fn (_ actions)
    (fn (_ state)
      (List fold
        (fn (_ acc action)
          ((fn (_ did)
             (list (List append (first acc) (first did))
                   (List append (first (rest acc)) (first (rest did)))
                   (first (rest (rest did)))))
           (action (first (rest (rest acc))))))
        (list () () state)
        actions))))

; The actions run together over SECONDS; with none, the stage is held.
(def stage-beat
  (fn (_ seconds . actions)
    (fn (_ state play wait)
      ((fn (_ done)
         ((fn (_ names animations next)
            (do (if (null? animations)
                  (wait (List map rest state) seconds)
                  (play (List map rest
                          (List fold
                            (fn (_ kept entry) (if (stage-has? names (first entry)) kept (List append kept (list entry))))
                            () state))
                        animations seconds))
                next))
          (first done) (first (rest done)) (first (rest (rest done)))))
       ((stage-all actions) state)))))

; --- Running ---------------------------------------------------------------

; Every step in turn, from an empty stage: the figures at the end.
(def stage-run
  (fn (_ steps play wait)
    (List map rest (List fold (fn (_ state step) (step state play wait)) () steps))))

(def stage-live
  (fn (_ front title steps)
    (def stage (Scene open front title 1280 720 15))
    ; An empty stage first, long enough to open the page or the window.
    (Scene wait stage () 4)
    (stage-run steps
               (fn (_ figures animations seconds) (Scene play stage figures animations seconds))
               (fn (_ figures seconds) (Scene wait stage figures seconds)))
    (Scene close stage)))

; SCENES picks how to run: unset, the steps go straight to their ends and
; STILL is handed the last frame's figures; web plays them in a browser,
; the page's address on stderr; sdl in a window, on a host with SDL3.
(def stage-main
  (fn (_ title steps still)
    ((fn (_ how)
       (match
         ((null? how) (still (stage-run steps (fn (_ figures animations seconds) figures) (fn (_ figures seconds) figures))))
         ((str=? how "web") (do (import x/sys/web) (stage-live Web title steps)))
         ((str=? how "sdl") (do (import x/sys/sdl) (stage-live Sdl title steps)))
         (#t (still (stage-run steps (fn (_ figures animations seconds) figures) (fn (_ figures seconds) figures))))))
     (Sys getenv "SCENES"))))
