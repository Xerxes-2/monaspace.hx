;;; monaspace.scm — Monaspace font mixing for Helix (Steel fork)
;;;
;;; Adds bold/italic modifiers to highlight groups so that a terminal
;;; configured with different Monaspace variants per style renders each
;;; syntax element in its designated font. The modifiers are patched
;;; onto the currently active theme, preserving all its colors.
;;;
;;; Terminal setup (example for kitty/ghostty/alacritty):
;;;   Regular      → Monaspace Neon     (or your preferred default)
;;;   Bold         → Monaspace Xenon    (slab serif)
;;;   Italic       → Monaspace Radon    (handwriting)
;;;   Bold+Italic  → Monaspace Krypton  (mechanical sans)
;;;
;;; Usage: (require "monaspace/monaspace.scm") from your Helix init.scm

(require "helix/editor.scm")
(require "helix/misc.scm")
(require "helix/commands.scm")
(require "helix/themes.scm")

(require-builtin helix/core/themes)
(require-builtin helix/components)

(provide install-monaspace-plugin!)

;; ---------------------------------------------------------------------------
;; Configuration & state
;; ---------------------------------------------------------------------------

(define *monaspace-installed* #f)
;; Guard against re-entry when we invoke :theme to reload the patched theme
(define *monaspace-applying* #f)
(define *monaspace-plugin-name* "monaspace.hx")
(define *monaspace-plugin-version* "0.2.0")

;; Patched themes are registered under "<base-theme>+monaspace".
(define *monaspace-theme-suffix* "+monaspace")

;; ---------------------------------------------------------------------------
;; Style helpers
;;
;; These operate in "replace" mode: build a fresh style with ONLY the
;; desired modifier(s), then copy fg/bg from the existing style.
;;
;; Why not just patch (style-with-bold existing)? Because many themes
;; already set italic on comments. Adding bold would yield bold+italic,
;; which maps to Krypton instead of the intended Xenon. Replacing
;; guarantees a deterministic single-font slot per scope.
;;
;; Tradeoff: underline color/style are dropped. Steel exposes the builders
;; `style-underline-color` / `style-underline-style` but no *getters*, so an
;; existing underline cannot be read off the theme and carried over. This is
;; visible on diagnostics, where most themes use an undercurl.
;; ---------------------------------------------------------------------------

(define (copy-colors! src dst)
  (let ([fg (style->fg src)])
    (when fg
      (set-style-fg! dst fg)))
  (let ([bg (style->bg src)])
    (when bg
      (set-style-bg! dst bg)))
  dst)

(define (make-bold existing)
  (copy-colors! existing (style-with-bold (style))))

(define (make-italic existing)
  (copy-colors! existing (style-with-italics (style))))

(define (make-bold-italic existing)
  (copy-colors! existing (style-with-bold (style-with-italics (style)))))

;; ---------------------------------------------------------------------------
;; Font mapping
;;
;; Each list maps highlight scopes to a modifier. Customize to taste — the
;; only constraint is the 4 terminal slots: regular, bold, italic, bold+italic.
;; ---------------------------------------------------------------------------

;; Bold → Xenon (slab serif): structural / heading elements
(define *monaspace-bold-scopes*
  '("comment"
    "comment.line"
    "comment.line.documentation"
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
  '("markup.link" "markup.link.url"
                  "markup.link.label"
                  "markup.link.text"
                  "string.special.url"
                  "string.special.path"
                  "tag"
                  "label"))

;; Bold+Italic → Krypton (mechanical sans): diagnostics & UI chrome
(define *monaspace-bold-italic-scopes*
  '("diagnostic" "diagnostic.error"
                 "diagnostic.warning"
                 "diagnostic.info"
                 "diagnostic.hint"
                 "error"
                 "warning"
                 "info"
                 "hint"
                 "ui.virtual.jump-label"))

;; ---------------------------------------------------------------------------
;; Logging
;; ---------------------------------------------------------------------------

(define (log-info message)
  (log::info! (string-append "[monaspace] " message)))

;; ---------------------------------------------------------------------------
;; Core: apply modifiers to a SteelTheme
;; ---------------------------------------------------------------------------

;; A single `theme-set-style!` is enough on current builds: scopes the theme
;; did not define are appended to the theme's scope/highlight vectors, and
;; `Editor::set_theme` re-resolves them through `Loader::set_scopes` before
;; the next render. (Older builds needed this call duplicated.)
;;
;; Caveat: `Theme::set` does not update the theme's `scope_index` lookup
;; table, which `find_highlight_exact` consults. Tree-sitter highlighting is
;; unaffected, but UI-side lookups (inline diagnostics, jump labels) fall back
;; to the parent scope for scopes the theme itself never declared.
(define (apply-modifier-to-scope! theme scope modifier-fn)
  (theme-set-style! theme scope (modifier-fn (theme-style theme scope))))

(define (apply-font-map! theme scopes modifier-fn)
  (for-each (lambda (scope) (apply-modifier-to-scope! theme scope modifier-fn)) scopes))

(define (monaspace-load! theme)
  (apply-font-map! theme *monaspace-bold-scopes* make-bold)
  (apply-font-map! theme *monaspace-italic-scopes* make-italic)
  (apply-font-map! theme *monaspace-bold-italic-scopes* make-bold-italic)
  theme)

;; ---------------------------------------------------------------------------
;; Patch & reload
;;
;; Clone the active theme, apply modifiers, rename the clone to
;; "<base>+monaspace", register it, then switch to it.
;;
;; The rename is what makes this work: `Loader::load` searches the theme
;; directories first and only falls back to dynamically registered themes, so
;; re-registering under the original name is shadowed by the on-disk theme and
;; the patch is silently dropped. `theme-set-name!` gives the clone a name that
;; cannot collide with a file on disk.
;;
;; Skipping already-patched themes keeps `:theme` cheap — post-command fires
;; once per keystroke while the prompt is open — and avoids clobbering the
;; theme preview more often than necessary.
;; ---------------------------------------------------------------------------

(define (monaspace-theme-name? name)
  (ends-with? name *monaspace-theme-suffix*))

(define (apply-monaspace-to-current-theme!)
  (let ([name (current-theme-name)])
    (when (and (not *monaspace-applying*) (not (monaspace-theme-name? name)))
      (set! *monaspace-applying* #t)
      (let ([patched (monaspace-load! (current-theme))]
            [derived (string-append name *monaspace-theme-suffix*)])
        (theme-set-name! patched derived)
        (register-theme patched)
        (theme derived)
        (log-info (string-append "patched " name " -> " derived)))
      (set! *monaspace-applying* #f))))

;; ---------------------------------------------------------------------------
;; Plugin entry point
;; ---------------------------------------------------------------------------

(define (install-monaspace-plugin!)
  (if *monaspace-installed*
      #f
      (begin
        (set! *monaspace-installed* #t)
        (apply-monaspace-to-current-theme!)
        ;; `:theme` switches themes; `:config-reload` reloads the theme named
        ;; in config.toml. Both land us back on an unpatched theme.
        (register-hook 'post-command
                       (lambda (cmd)
                         (when (or (equal? cmd "theme") (equal? cmd "config-reload"))
                           (apply-monaspace-to-current-theme!))))
        (log-info "monaspace plugin loaded")
        (set-status! "monaspace plugin loaded"))))

(install-monaspace-plugin!)
