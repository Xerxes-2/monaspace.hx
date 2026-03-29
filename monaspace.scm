;;; monaspace.scm — Monaspace font mixing for Helix (Steel fork)
;;;
;;; Assigns bold/italic modifiers to highlight groups so that a terminal
;;; configured with different Monaspace variants per style renders each
;;; syntax element in its designated font.
;;;
;;; Terminal setup (example for kitty/ghostty/alacritty):
;;;   Regular      → Monaspace Neon     (or your preferred default)
;;;   Bold         → Monaspace Xenon    (slab serif)
;;;   Italic       → Monaspace Radon    (handwriting)
;;;   Bold+Italic  → Monaspace Krypton  (mechanical sans)
;;;
;;; Usage: (require "monaspace/monaspace.scm") from your Helix init.scm

(require "helix/editor.scm")

(require-builtin helix/core/themes)
(require-builtin helix/components)

(provide install-monaspace-plugin!)

;; ---------------------------------------------------------------------------
;; Configuration & state
;; ---------------------------------------------------------------------------

(define *monaspace-installed* #f)
(define *monaspace-plugin-name* "monaspace.hx")
(define *monaspace-plugin-version* "0.1.0")

;; ---------------------------------------------------------------------------
;; Style helpers
;; ---------------------------------------------------------------------------

(define (make-bold s)
  (style-with-bold s))

(define (make-italic s)
  (style-with-italics s))

(define (make-bold-italic s)
  (style-with-bold (style-with-italics s)))

;; ---------------------------------------------------------------------------
;; Font mapping
;;
;; Each list maps highlight scopes to a modifier function.
;; Customize these to taste — the only constraint is the 4 terminal slots:
;;   regular, bold, italic, bold+italic
;; ---------------------------------------------------------------------------

;; Bold → Xenon (slab serif): structural / heading elements
(define *monaspace-bold-scopes*
  '("comment"
    "comment.line"
    "comment.block"
    "comment.block.documentation"
    "markup.heading"
    "markup.heading.1"
    "markup.heading.2"
    "markup.heading.3"
    "markup.heading.4"
    "markup.heading.5"
    "markup.heading.6"
    "markup.heading.marker"
    "ui.text.directory"))

;; Italic → Radon (handwriting): links, special strings, labels
(define *monaspace-italic-scopes*
  '("markup.link"
    "markup.link.url"
    "markup.link.label"
    "markup.link.text"
    "string.special.url"
    "string.special.path"
    "tag"
    "label"))

;; Bold+Italic → Krypton (mechanical sans): diagnostics & UI chrome
(define *monaspace-bold-italic-scopes*
  '("diagnostic"
    "diagnostic.error"
    "diagnostic.warning"
    "diagnostic.info"
    "diagnostic.hint"
    "error"
    "warning"
    "info"
    "hint"
    "ui.virtual.jump-label"))

;; ---------------------------------------------------------------------------
;; Logging helpers
;; ---------------------------------------------------------------------------

(define (log-info message)
  (log::info! (string-append "[monaspace] " message)))

;; ---------------------------------------------------------------------------
;; Core: apply modifiers to a SteelTheme object
;; ---------------------------------------------------------------------------

(define (apply-modifier-to-scope! theme scope modifier-fn)
  (let ((existing (theme-style theme scope)))
    (theme-set-style! theme scope (modifier-fn existing))))

(define (apply-font-map! theme scopes modifier-fn)
  (for-each (lambda (scope)
              (apply-modifier-to-scope! theme scope modifier-fn))
            scopes))

(define (monaspace-load! theme)
  "Apply Monaspace font-mixing modifiers to a SteelTheme object.
Mutates and returns the theme."
  (apply-font-map! theme *monaspace-bold-scopes*        make-bold)
  (apply-font-map! theme *monaspace-italic-scopes*      make-italic)
  (apply-font-map! theme *monaspace-bold-italic-scopes* make-bold-italic)
  theme)

;; ---------------------------------------------------------------------------
;; Plugin entry point
;;
;; Creates a "monaspace" theme with font-mixing modifiers applied and
;; registers it with the editor. Switch to it with :theme monaspace
;; ---------------------------------------------------------------------------

(define (install-monaspace-plugin!)
  (if *monaspace-installed*
      #f
      (begin
        (set! *monaspace-installed* #t)
        (let ((theme (hashmap->theme "monaspace" (hash))))
          (monaspace-load! theme)
          (register-theme theme))
        (log-info "monaspace plugin loaded")
        (set-status! "monaspace plugin loaded"))))

(install-monaspace-plugin!)
