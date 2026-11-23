;;; site.el --- idlip.in: config, content wiring, site-specific rendering -*- lexical-binding: t; -*-

;;; Commentary:

;; This site's config, content and site-specific rendering: the org-publish
;; project definition, the Emacs-frame chrome data, wander, the themes
;; gallery, topic-list with chips and icons, references and the link
;; budget, the OG card template, base16 scheme handling, command palette
;; data.
;;
;; Builds to public-denden/, separate from Hugo's own public/ output.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'dom)
(require 'rx)
(require 'calendar)
(require 'cal-iso)
(require 'denden)
(require 'theme)
(require 'site-schemes-base16)

;;;; Config data: menu, color schemes, social links, palette icons, badges

(defconst site-menu-header
  '((:name "Log" :url "/log/")
    (:name "Pose" :url "/pose/")
    (:name "Wander" :url "/wander/")
    (:name "Media" :url "/media/")
    (:name "About" :url "/about/")
    (:name "More…" :url "#all-pages"))
  "The header links: short labels, no icons, separate from `site-menu-main'.")

(defconst site-menu-main
  '(
    (:name " Home" :url "/")
    (:name "󰎕 Blog Posts" :url "/log/")
    (:name "󰟶 Pose" :url "/pose/")
    (:name " Projects & Tools" :url "/repo/")
    (:name "󰆋 Wander/Blogroll" :url "/wander/")
    (:name " About" :url "/about/")
    (:name "󰚀 Now Now Now" :url "/now/")
    (:name "󰟴 Media" :url "/media/")
    (:name "󱀢 Quotes" :url "/quotes/")
    (:name " Feeds" :url "/index.xml")
    (:name "󰦃 Sitemap" :url "/sitemap/")
    (:name " Links" :url "/links/")
    (:name " Tags" :url "/tags/"))
  "Every page link with its icon, in order, for the footer and the palette.")

(defconst site-color-schemes
  '((:name "haki" :label "Haki" :bg "#000000" :fg "#ffffff" :accent "#5fd7af")
    (:name "" :label "Modus" :bg "#000000" :fg "#ffffff" :accent "#2fafff")
    (:name "dracula" :label "Dracula" :dark "dracula")
    (:name "gruvbox" :label "Gruvbox" :dark "gruvbox-dark-medium" :light "gruvbox-light-medium")
    (:name "tokyo-night" :label "Tokyo Night" :dark "tokyo-night-dark" :light "tokyo-night-light")
    (:name "catppuccin-mocha" :label "Catppuccin Mocha" :dark "catppuccin-mocha" :light "catppuccin-latte")
    (:name "one-dark" :label "One Dark" :dark "onedark" :light "one-light")
    (:name "rose-pine" :label "Rosé Pine" :dark "rose-pine" :light "rose-pine-dawn")
    (:name "kanagawa" :label "Kanagawa" :dark "kanagawa")
    (:name "ayu" :label "Ayu" :dark "ayu-dark" :light "ayu-light")
    (:name "everforest" :label "Everforest" :dark "everforest-dark-hard")
    (:name "oxocarbon" :label "Oxocarbon" :dark "oxocarbon-dark" :light "oxocarbon-light")
    (:name "monokai" :label "Monokai" :dark "monokai")
    (:name "github-dark" :label "GitHub Dark" :dark "github-dark" :light "github")))

(defconst site-social-links
  '((:label "hi@idlip.in" :url "mailto:hi@idlip.in" :icon "")
    (:label "idlip" :url "https://github.com/idlip" :icon "")
    (:label "idlip" :url "https://codeberg.org/idlip" :icon " ")
    (:label "Dilip G" :url "https://linkedin.com/in/dilip-g-29707727a" :icon " ")
    (:label "GolD_Lip" :url "https://reddit.com/u/GolD_Lip" :icon " ")
    (:label "zororg" :url "https://t.me/zororg" :icon " ")
    (:label "@idlip" :url "https://fosstodon.org/@idlip" :icon "󰫑 " :rel "me")
    (:label "zororg" :url "https://matrix.to/#/zororg:matrix.org" :icon "󰘨"))
  "The fosstodon.org entry's own `rel: me' is for IndieAuth verification.")

(defconst site-palette-icons
  '(:nav "󰘍 " :command " " :post " " :tag " " :scheme " "))

(defconst site-backlink-icon " "
  "The icon before a See Also row that links to the current page (a backlink).")

(defconst site-title "Dilip's Log")

(defconst site-title-quotes
  '("My heart beats when you see me..."
    "Gaming, tinkering and breathing inside Emacs"
    "Thank you for your time given to my site"
    "Coffee is bad, Buy Me Protein"
    "Magic… is all about lie, and skill at play"
    "Writing it down is 80% work done"
    "Still reading? You're officially a regular now"
    "Hovering on titles? You must be a developer"
    "Judging my CSS? It judged you first"
    "Shouldn't you be working right now?"
    "You're here instead of doom-scrolling. Proud of you"
    "You've been reading for a while. Water break?"
    "Found a typo? Free chat if you email it to me"
    "A simple thanks makes both of our day delightful"
    "Enough touching me, touch the grass now"
    )
  "Tiny delights: the site title shows one of these at random on hover.")

(defconst site-description "Dilip's Log")

(defconst site-copyright "Copyright © 2023-2026, Dilip | Zororg; All rights reserved.")

(defconst site-author-name "Dilip | Zororg")

(defconst site-author-email "hi@idlip.in")

(defconst site-fediverse-creator "@idlip@fosstodon.org"
  "This site's fediverse:creator meta value, ported from Hugo's
extended_head.html.")

(defconst site-base-url-production "https://idlip.in/")

(defun site-base-url ()
  "Return the base URL for links, canonical, feeds, and sitemap:
`site-base-url-production', or the preview env var when set."
  (or (getenv "DENDEN_PREVIEW_BASE_URL") site-base-url-production))

(defconst site-umami-script-url "https://analytics.fossunited.org/script.js")

(defconst site-umami-website-id "64825a51-be1b-416e-b1ec-895aa541dcab")

(defconst site-publishing-directory
  (expand-file-name "public-denden" denden-repository-directory))

(defconst site-preload-fonts '("/fonts/impress.woff2" "/fonts/code-haki.woff2")
  "Fonts the default view paints first, preloaded in <head>.")

(defconst site-favicon-relative-path "images/op-zoro.webp"
  "Relative to static/.")

(defconst site-tag-icons
  `(("snippets" . " ") ("nixos" . " ") ("nix" . " ") ("emacs" . " ") ("gnus" . " ")
    ("orgmode" . " ") ("novel" . " ") ("onepiece" . "󰨈 ") ("anime" . "󰨈 ") ("manga" . "󰨈 ")
    ("linux" . " ") ("foss" . " ") ("rss" . " ") ("games" . " ") ("terminal" . " ")
    ("cli" . " ") ("vim" . " ") ("android" . "") ("fossdroid" . "") ("quotes" . "󱀡 ")
    ("bioinformatics" . "󰚄 ") ("python" . " ") ("r" . "󰟔") ("finance" . " ")
    ("principle" . " ") ("webdev" . " ") ("lisp" . "󱃺 ") ("git" . " ") 

    ;; Link hosts for /links: a key matches a whole host or one dot-separated part of it.
    (,(rx (or (seq "emacs" (+ nonl)) "gnu" "karthinks" "protesilaos" "karl-voit")) . " ")
    ("github" . "󰊤") ("gitlab" . "󰮠") ("codeberg" . " ")
    (,(rx (or "wikipedia" "wikimedia")) . "󰖬") (,(rx (or "reddit" "redlib")) . " ")
    (,(rx (or "youtube" "youtu")) . "󰑈") (,(rx (or "f-droid" "izzysoft")) . " ")
    ("medium" . "󱀁")
    (,(rx (or "fosstodon.org" "lobste.rs" "fossunited.org" "nownownow.com" "miniflux.app")) . "󰚀")
    (,(rx (or "themoviedb.org" "novelupdates.com" "fandom" "obtf.ru")) . "󰟴")
    ("_default" . " "))
  "(KEY . GLYPH) icons for tags and /links hosts; the first non-empty match wins.
KEY is a regexp (plain word, or `rx' for a family) that must match a whole
tag, a whole host, or one dot-separated part of a host.")

(defconst site-badges
  (list (list :name "Emacs" :logo "/images/logos/emacs.png" :color "#5b2a85"
              :link "https://www.gnu.org/software/emacs/" :subtitle "Living in")
        (list :name "Org mode" :logo "/images/logos/orgmode.png" :color "#3f6b5e"
              :link "https://orgmode.org/" :subtitle "Swimming in")
        (list :name "Santōryū" :logo "/images/logos/zoro-chibi.webp" :color "#32ae55"
              :link "/wander/" :subtitle "Wander web" :tooltip "Find your way over the network")
        (list :name "OnePiece" :logo "/images/logos/onepiece.webp" :color "#D49A00"
              :subtitle "Finding" :link "https://one-piece.com/")
        (list :name "FOSS" :logo "/images/logos/foss.webp" :color "#8AA9BC"
              :link "https://en.wikipedia.org/wiki/Free_and_open-source_software" :subtitle "Liberated by")))

(defconst site-footer-content
  (list
   'div nil
   (list 'p '(:class "webring")
         '(a (:href "https://blr.indiewebclub.org/webring/idlip-in/previous.html" :aria-label "Previous site") "=")
         " "
         '(a (:href "https://blr.indiewebclub.org/") "IndieWebClub BLR")
         " "
         '(a (:href "https://blr.indiewebclub.org/webring/idlip-in/next.html" :aria-label "Next site") "="))
   (list 'p '(:class "webring")
         '(a (:href "https://craftering.systemcrafters.net/@idlip/previous" :aria-label "Previous site") "")
         " "
         '(a (:href "https://craftering.systemcrafters.net/") " Craftering ")
         " "
         '(a (:href "https://craftering.systemcrafters.net/@idlip/next" :aria-label "Next site") ""))
   (list 'span '(:class "dashed-rule" :aria-hidden "true")
         "- - - - - - -  - - - - - - -  - - - - - - -  - - - - - - -")
   (list 'p nil
         " 2023-2026 " '(b nil "Dilip | Zororg") "  Made with 󰣐  using "
         '(a (:href "https://github.com/idlip/denden") "Denden") " via "
         '(a (:href "https://www.gnu.org/software/emacs/") "Emacs") " "
         '(a (:href "https://orgmode.org/") "Org-mode")
         '(br nil)
         "The content is licensed under "
         '(a (:href "https://creativecommons.org/licenses/by-sa/4.0/") "CC-BY-SA 4.0"))
   (append (list 'p '(:class "badge-grid"))
           (mapcar (lambda (b) (apply #'theme-badge b)) site-badges)))
  "Webring links, credits, license, then every `site-badges' entry.")

;;;; Base16 scheme handling: CSS, swatches, gallery data
;;
;; Everything here takes already-loaded data (`site-schemes-base16', a
;; custom.css string) as arguments rather than reading any file itself, so
;; it stays testable.

(defconst site--base16-keys
  '("base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07"
    "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F")
  "The 16 base16 slot names, in emission order.")

(defun site-scheme-palette-value (palette key)
  "Return PALETTE's value for KEY, e.g. \"base0A\", tried as written and lowercased."
  (or (cdr (assoc key palette)) (cdr (assoc (downcase key) palette))))

(defun site--base16-entry (key)
  "The (:name :author :variant :palette) plist for base16 scheme KEY, or nil."
  (cdr (assoc key site-schemes-base16)))

(defconst site-contrast-floor
  '(("base05" . 7) ("base0D" . 4.5)
    ("base0C" . 3) ("base08" . 3) ("base09" . 3) ("base0B" . 3) ("base0E" . 3))
  "Least contrast on base00: text 7, links 4.5, accent and headings 3.")

(defun site--relative-luminance (hex)
  "The WCAG relative luminance of HEX, a \"#rrggbb\" colour."
  (let ((digits (string-remove-prefix "#" hex)))
    (apply #'+ (cl-mapcar (lambda (start weight)
                            (let ((channel (/ (string-to-number (substring digits start (+ start 2)) 16) 255.0)))
                              (* weight (if (<= channel 0.04045) (/ channel 12.92)
                                          (expt (/ (+ channel 0.055) 1.055) 2.4)))))
                          '(0 2 4) '(0.2126 0.7152 0.0722)))))

(defun site-contrast-ratio (first second)
  "The WCAG contrast ratio between hex colours FIRST and SECOND."
  (let ((a (site--relative-luminance first)) (b (site--relative-luminance second)))
    (/ (+ (max a b) 0.05) (+ (min a b) 0.05))))

(defun site-scheme-readable-p (colors)
  "Non-nil if COLORS, 16 base16 hex strings, meet `site-contrast-floor'."
  (and (= (length colors) 16)
       (cl-every (lambda (color) (string-match-p (rx bos (opt "#") (= 6 hex) eos) (or color ""))) colors)
       (cl-every (lambda (rule)
                   (>= (site-contrast-ratio (nth (cl-position (car rule) site--base16-keys :test #'equal) colors)
                                            (car colors))
                       (cdr rule)))
                 site-contrast-floor)))

(defun site--base16-colors (yaml-key)
  "The 16 colours of base16 scheme YAML-KEY, or nil if unknown."
  (let ((entry (and yaml-key (site--base16-entry yaml-key))))
    (and entry (mapcar (lambda (key) (site-scheme-palette-value (plist-get entry :palette) key))
                       site--base16-keys))))

(defun site-light-scheme-names (color-schemes custom-schemes)
  "COLOR-SCHEMES names with a readable light variant, using CUSTOM-SCHEMES."
  (delq nil (mapcar (lambda (scheme)
                      (let* ((name (plist-get scheme :name))
                             (custom (cl-find (concat name "-light") custom-schemes
                                              :key (lambda (s) (plist-get s :key)) :test #'equal))
                             (colors (if custom (plist-get custom :colors)
                                       (site--base16-colors (plist-get scheme :light)))))
                        (and (or (string-empty-p name) (site-scheme-readable-p colors)) name)))
                    color-schemes)))

(defun site-scheme-css (color-schemes)
  "CSS blocks for each readable :dark and :light variant in COLOR-SCHEMES."
  (mapconcat
   (lambda (scheme)
     (let ((name (plist-get scheme :name)))
       (mapconcat
        (lambda (variant-key-and-selector)
          (let ((yaml-key (car variant-key-and-selector))
                (selector (cdr variant-key-and-selector)))
            (if (null yaml-key) ""
              (let ((entry (site--base16-entry yaml-key)))
                (if (or (null entry) (not (site-scheme-readable-p (site--base16-colors yaml-key)))) ""
                  (let* ((palette (plist-get entry :palette))
                         (vars (mapconcat
                                (lambda (k)
                                  (let ((v (site-scheme-palette-value palette k)))
                                    (if v (format "--%s:%s;" k v) "")))
                                site--base16-keys "")))
                    (format "%s{%s}\n" selector vars)))))))
        (list (cons (plist-get scheme :dark) (format "[data-scheme=\"%s\"]" name))
              (cons (plist-get scheme :light) (format "[data-scheme=\"%s\"][data-theme=\"light\"]" name)))
        "")))
   color-schemes ""))

(defun site-parse-author (author)
  "Parse \"Name (URL)\" or plain \"Name\" AUTHOR into (:name :url); :url is
\"\" if there is none."
  (if (string-match (rx bos (group (+ (not (any "(")))) "(" (group (* (not (any ")")))) ")") author)
      (list :name (string-trim (match-string 1 author)) :url (match-string 2 author))
    (list :name (string-trim author) :url "")))

(defun site-parse-custom-css-schemes (css-text)
  "Parse CSS-TEXT's \"/* @scheme: Name | Author | Variant */\" comments into
base16-shaped entries."
  (when (and css-text (not (string-empty-p css-text)))
    (let ((unit-re (rx "/* @scheme:" (group (* (not (any "*")))) "*/" (* (any " \t\n"))
                       "[data-scheme=\"" (group (+ (any "a-zA-Z0-9_-"))) "\"]"
                       (opt (group "[data-theme=\"light\"]")) (* (any " \t\n"))
                       "{" (group (* (not (any "}")))) "}"))
          (start 0) (out nil))
      (while (string-match unit-re css-text start)
        ;; next-start/meta/key/light/body must be read off the match data
        ;; before anything else runs -- split-string and string-trim below
        ;; call string-match internally and would otherwise silently clobber
        ;; this same global match data, leaving `start' stuck and the loop
        ;; never advancing.
        (let* ((next-start (match-end 0))
               (meta (match-string 1 css-text))
               (key (match-string 2 css-text))
               (light (match-string 3 css-text))
               (body (match-string 4 css-text))
               (fields (split-string meta "|"))
               (name (string-trim (or (nth 0 fields) "")))
               (author (string-trim (or (nth 1 fields) "")))
               (variant (string-trim (or (nth 2 fields) "")))
               (colors nil)
               (hex-start 0))
          (setq start next-start)
          (while (string-match
                  (rx "--base0" (any "0-9A-F") ":" (* (any " \t")) (group "#" (= 6 (any "0-9a-fA-F"))))
                  body hex-start)
            (push (match-string 1 body) colors)
            (setq hex-start (match-end 0)))
          (setq colors (nreverse colors))
          (when (= (length colors) 16)
            (let ((a (site-parse-author author)))
              (push (list :key (if light (format "%s-light" key) key)
                          :name name :author-name (plist-get a :name) :author-url (plist-get a :url)
                          :variant variant :colors colors :source "custom")
                    out)))))
      (nreverse out))))

(defun site--base16-all-schemes ()
  "Return every `site-schemes-base16' entry projected to the gallery's (:key
:name ...) shape."
  (mapcar
   (lambda (pair)
     (let* ((key (car pair)) (entry (cdr pair))
            (author (site-parse-author (or (plist-get entry :author) ""))))
       (list :key key :name (or (plist-get entry :name) key)
             :author-name (plist-get author :name) :author-url (plist-get author :url)
             :variant (or (plist-get entry :variant) "")
             :colors (mapcar (lambda (k) (or (site-scheme-palette-value (plist-get entry :palette) k) ""))
                             site--base16-keys)
             :source "base16")))
   site-schemes-base16))

(defun site-all-schemes (&optional custom-css-text)
  "Return every base16 scheme plus this site's custom schemes, parsed from
CUSTOM-CSS-TEXT."
  (append (site--base16-all-schemes) (site-parse-custom-css-schemes custom-css-text)))

(defun site--scheme-families (custom-schemes)
  "Readable `site-color-schemes' as palette families, colours from CUSTOM-SCHEMES."
  (seq-filter
   (lambda (family) (or (null (plist-get family :colors)) (site-scheme-readable-p (plist-get family :colors))))
   (mapcar (lambda (scheme)
             (let* ((name (plist-get scheme :name))
                    (custom (cl-find name custom-schemes :key (lambda (s) (plist-get s :key)) :test #'equal)))
               (list :key name :name (plist-get scheme :label) :family name :variant "dark"
                     :colors (or (and custom (plist-get custom :colors))
                                 (site--base16-colors (plist-get scheme :dark))))))
           site-color-schemes)))

(defun site-schemes-json (&optional custom-css-text)
  "The palette scheme list as JSON: families first, then readable schemes."
  (let* ((custom (site-parse-custom-css-schemes custom-css-text))
         (families (site--scheme-families custom))
         (family-keys (mapcan (lambda (f) (list (plist-get f :key) (concat (plist-get f :key) "-light"))) families))
         (others (seq-filter (lambda (s) (and (not (member (plist-get s :key) family-keys))
                                              (site-scheme-readable-p (plist-get s :colors))))
                             (site-all-schemes custom-css-text))))
    (json-serialize
     (vconcat (mapcar (lambda (s) (append (list :key (plist-get s :key) :name (plist-get s :name)
                                                :variant (or (plist-get s :variant) "")
                                                :colors (vconcat (plist-get s :colors)))
                                          (when (plist-get s :family) (list :family (plist-get s :family)))))
                      (append families others))))))

;;;; Generate site-schemes-base16.el from the base16 yaml submodule
;;
;; Converts data/schemes/base16/*.yaml (submodule, 304 files) to a committed
;; elisp data file once, so the real build never loads yaml.el or touches
;; the submodule directly ("YAML stays off the build path"). Regenerate
;; with `site-generate-schemes-base16-file' by hand when the submodule
;; updates -- nothing on the build path calls it.

(defun site--yaml-raw-string-field (text key)
  "Return TEXT's top-level KEY value by regex, so a numeric-looking quoted
scalar stays a string."
  (or (and (string-match
            (rx bol (literal key) ":" (* (any " \t")) "\"" (group (* (not (any "\"")))) "\"")
            text)
           (match-string 1 text))
      (and (string-match
            (rx bol (literal key) ":" (* (any " \t")) (group (+? nonl)) (* (any " \t")) eol)
            text)
           (match-string 1 text))))

(defun site--yaml-scheme-file-to-entry (file)
  "Parse one base16 yaml FILE into (KEY . (:name :author :variant :palette))."
  (require 'yaml)
  (let* ((text (with-temp-buffer (insert-file-contents file) (buffer-string)))
         (data (yaml-parse-string text))
         (palette-hash (gethash 'palette data))
         (palette nil))
    (when (hash-table-p palette-hash)
      (maphash (lambda (k v) (push (cons (symbol-name k) v) palette)) palette-hash))
    (cons (file-name-base file)
          (list :name (site--yaml-raw-string-field text "name")
                :author (site--yaml-raw-string-field text "author")
                :variant (site--yaml-raw-string-field text "variant")
                :palette (nreverse palette)))))

(defun site-generate-schemes-base16-file (&optional source-directory output-file)
  "Parse every base16 yaml under SOURCE-DIRECTORY and write OUTPUT-FILE, a
committed elisp data file. Run by hand."
  (interactive)
  (let* ((source-directory (or source-directory
                               (expand-file-name "data/schemes/base16/" denden-repository-directory)))
         (output-file (or output-file
                          (expand-file-name "site-schemes-base16.el"
                                            (file-name-directory (or load-file-name buffer-file-name)))))
         (entries (mapcar #'site--yaml-scheme-file-to-entry
                          (sort (directory-files source-directory t (rx ".yaml" eos)) #'string<))))
    (with-temp-file output-file
      (insert ";;; site-schemes-base16.el --- generated base16 scheme data -*- lexical-binding: t; -*-\n\n")
      (insert ";; Do not hand-edit. Generated by `site-generate-schemes-base16-file'\n")
      (insert (format ";; (site.el) from %d files under data/schemes/base16/.\n\n" (length entries)))
      (insert ";;; Code:\n\n")
      (insert "(defconst site-schemes-base16\n  '(\n")
      (dolist (entry entries)
        (insert "    ")
        (prin1 entry (current-buffer))
        (insert "\n"))
      (insert "    )\n")
      (insert "  \"Base16 scheme data: KEY (a yaml file's base name) -> (:name :author\n:variant :palette) plist.\")\n\n")
      (insert "(provide 'site-schemes-base16)\n;;; site-schemes-base16.el ends here\n"))
    (message "site-generate-schemes-base16-file: wrote %d schemes to %s" (length entries) output-file)
    (length entries)))

;;;; Base16 mapping for highlighted code
;;
;; Maps the htmlize/org-html CSS class names onto this site's --base00..
;; --base0F custom properties, following the standard base16
;; styling-guidelines convention. This is what lets highlighted code follow
;; the scheme switcher: the class names never change, only what --base0X
;; resolves to.

(defconst site-highlight-class-colors
  '(("org-default"            . "var(--base05)")
    ("org-comment"            . "var(--base03)")
    ("org-comment-delimiter"  . "var(--base03)")
    ("org-string"             . "var(--base0B)")
    ("org-doc"                . "var(--base0B)")
    ("org-keyword"            . "var(--base0E)")
    ("org-negation-char"      . "var(--base0E)")
    ("org-preprocessor"       . "var(--base0F)")
    ("org-builtin"            . "var(--base0C)")
    ("org-function-name"      . "var(--base0D)")
    ("org-variable-name"      . "var(--base08)")
    ("org-type"               . "var(--base0A)")
    ("org-constant"           . "var(--base09)")
    ("org-warning"            . "var(--base08)"))
  "Base16 styling-guidelines mapping for htmlize's font-lock-derived classes.")

(defun site-highlight-stylesheet ()
  "Return the CSS stylesheet mapping highlighted code onto base16 tokens."
  (denden-highlight-stylesheet site-highlight-class-colors))

;;;; This site's OG card template
;;
;; The reusable wrapping math is `denden-og-wrap-words'/`denden-og-truncate-
;; lines'; colors and geometry here are this site's own: a 1200x630 card in
;; the site's Haki look.

(defconst site--og-media-types
  '(("webp" . "image/webp") ("png" . "image/png") ("jpg" . "image/jpeg")
    ("jpeg" . "image/jpeg") ("svg" . "image/svg+xml"))
  "File extension -> MIME type, for embedding the favicon as a data URI.")

(defun site--og-favicon-data-uri (favicon-path)
  "FAVICON-PATH's content as a data: URI, or nil if it does not exist."
  (when (and favicon-path (file-exists-p favicon-path))
    (let* ((extension (downcase (or (file-name-extension favicon-path) "")))
           (media-type (or (cdr (assoc extension site--og-media-types)) "application/octet-stream"))
           (content (with-temp-buffer
                      (set-buffer-multibyte nil)
                      (insert-file-contents-literally favicon-path)
                      (buffer-string))))
      (format "data:%s;base64,%s" media-type (base64-encode-string content t)))))

(defun site--og-title-lines (title)
  "TITLE wrapped to at most 3 lines, with a font size picked by its length."
  (let* ((font-size (cond ((> (length title) 60) 46) ((> (length title) 32) 54) (t 64)))
         (wrap-width (cond ((> (length title) 60) 38) ((> (length title) 32) 32) (t 27))))
    (list :font-size font-size
          :lines (denden-og-truncate-lines (denden-og-wrap-words title wrap-width) 3))))

(defun site--og-excerpt-lines (excerpt max-lines)
  "EXCERPT wrapped at 64 characters, at most MAX-LINES lines, gaps kept."
  (when (and excerpt (> max-lines 0))
    (denden-og-truncate-lines
     (seq-mapcat (lambda (source-line)
                   (if (string-empty-p source-line)
                       (list "")
                     (denden-og-wrap-words (replace-regexp-in-string (rx (+ (any " \t"))) " " (string-trim source-line)) 64)))
                 (split-string (string-trim excerpt) "\n"))
     max-lines)))

(defconst site--og-colors
  '(:background "#000000" :surface "#0a0f0a" :border "#404040" :text "#ffffff" :faint "#b3b3b3"
                :accent "#5fd7af" :title "#ab82ff" :link "#2fafff")
  "The Haki palette the OG card is drawn in, matching the site's default scheme.")

(defun site--og-chips (tags y)
  "Bordered #tag chips for the first 3 TAGS, text on baseline Y."
  (let ((x 64) (chips nil))
    (dolist (tag (seq-take tags 3))
      (let* ((label (concat "#" tag))
             (width (+ 32 (* 13 (length label)))))
        (push (list 'g nil
                    (list 'rect (list :x (number-to-string x) :y (number-to-string (- y 30))
                                      :width (number-to-string width) :height "44" :rx "8" :fill "none"
                                      :stroke (plist-get site--og-colors :link) :stroke-width "2"))
                    (list 'text (list :x (number-to-string (+ x 16)) :y (number-to-string y)
                                      :fill (plist-get site--og-colors :link) :font-size "22")
                          label))
              chips)
        (setq x (+ x width 14))))
    (append (list 'g nil) (nreverse chips))))

(cl-defun site-og-card-svg (&key title excerpt tags slug date meta-right card-site-title favicon-path
                                 (font "Code D OnePiece"))
  "This site's 1200x630 OG card for TITLE as an <svg> string, in Haki colours."
  (let* ((colors site--og-colors)
         (title-info (site--og-title-lines title))
         (title-lines (plist-get title-info :lines))
         (title-size (plist-get title-info :font-size))
         (title-top 236)
         (title-step (round (* title-size 1.18)))
         (title-last (+ title-top (* (1- (length title-lines)) title-step)))
         (excerpt-top (+ title-last 64))
         ;; Without a chip or meta row, the excerpt may run down to the edge bar.
         (excerpt-bottom (if (or tags date meta-right) 486 560))
         (excerpt-lines (site--og-excerpt-lines excerpt (min 6 (1+ (/ (- excerpt-bottom excerpt-top) 38)))))
         (favicon-data-uri (site--og-favicon-data-uri favicon-path))
         (domain (string-remove-prefix "https://" (string-remove-suffix "/" (site-base-url))))
         (address (if slug (format "%s/%s" domain (string-remove-suffix "/" slug)) domain))
         (meta (string-join (delq nil (list date (and meta-right (not (string-empty-p meta-right)) meta-right)))
                            "  ·  "))
         (title-x (if favicon-data-uri "132" "64"))
         (tree
          (list 'svg (list :xmlns "http://www.w3.org/2000/svg" :viewBox "0 0 1200 630"
                           :width "1200" :height "630" :font-family (format "%s, monospace" font))
                (list 'defs nil
                      '(clipPath (:id "favicon-clip") (rect (:x "64" :y "56" :width "52" :height "52" :rx "12")))
                      (list 'linearGradient '(:id "edge" :x1 "0" :x2 "1")
                            (list 'stop (list :offset "0" :stop-color (plist-get colors :accent)))
                            (list 'stop (list :offset "1" :stop-color (plist-get colors :title)))))
                (list 'rect (list :width "1200" :height "630" :fill (plist-get colors :background)))
                (list 'rect (list :x "1" :y "1" :width "1198" :height "628" :fill "none"
                                  :stroke (plist-get colors :border) :stroke-width "2"))
                (if favicon-data-uri
                    (list 'image (list :href favicon-data-uri :x "64" :y "56" :width "52" :height "52"
                                       :preserveAspectRatio "xMidYMid slice" :clip-path "url(#favicon-clip)"))
                  '(g nil))
                (list 'text (list :x title-x :y "93" :fill (plist-get colors :accent) :font-size "30" :font-weight "bold")
                      card-site-title)
                (list 'text (list :x "1136" :y "93" :fill (plist-get colors :faint) :font-size "22" :text-anchor "end")
                      address)
                (append
                 (list 'g nil)
                 (seq-map-indexed
                  (lambda (line index)
                    (list 'text (list :x "64" :y (number-to-string (+ title-top (* index title-step)))
                                      :fill (plist-get colors :title) :font-weight "bold"
                                      :font-size (number-to-string title-size))
                          line))
                  title-lines))
                (append
                 (list 'g nil)
                 (seq-map-indexed
                  (lambda (line index)
                    (list 'text (list :x "64" :y (number-to-string (+ excerpt-top (* index 38)))
                                      :fill (plist-get colors :faint) :font-size "25")
                          line))
                  excerpt-lines))
                (site--og-chips tags 562)
                (if (string-empty-p meta)
                    '(g nil)
                  (list 'text (list :x "1136" :y "562" :fill (plist-get colors :faint) :font-size "22" :text-anchor "end")
                        meta))
                '(rect (:y "620" :width "1200" :height "10" :fill "url(#edge)")))))
    (denden-serialize-node (denden-normalise-node tree))))

;;;; Wire theme templates into the real build
;;
;; Page-kind routing: a source file named _index.org (or index.org) is a
;; listing page (only content/_index.org exists today -> home); a file
;; whose #+layout: is "topic-list" or "themes" routes to that template;
;; everything else is a single page. /tags/ and every /tags/<tag>/ have no
;; source file at all -- synthesized purely from taxonomy data by
;; `site-build-taxonomy-pages', called after the normal publish+sweep so
;; the sweep does not delete them as "unexpected".

(defun site--word-count (body-html)
  "Approximate word count of BODY-HTML: strip tags, split on whitespace."
  (denden-html-word-count body-html))

(defun site--reading-time (word-count)
  "Reading time in whole minutes for WORD-COUNT words, minimum 1."
  (max 1 (round (/ word-count 200.0))))

(defun site--first-mailto (links)
  "First mailto: address in LINKS (site-social-links shape), or \"\"."
  (or (cl-some (lambda (l) (and (string-prefix-p "mailto:" (plist-get l :url))
                                (substring (plist-get l :url) 7)))
               links)
      ""))

(defun site--page-title (title)
  "Return the <title> tag text for TITLE, or `site-title' alone if TITLE is
nil."
  (if title (format "%s | %s" title site-title) site-title))

(defun site--palette-data-script (all-pages)
  "Return the command palette's post/tag/nav/icon data from ALL-PAGES, as one
<script> tag."
  (let ((posts (append
                (mapcar (lambda (p) (list :title (plist-get p :title)
                                          :url (concat "/" (plist-get p :url))
                                          :date (plist-get p :date)
                                          :tags (vconcat (plist-get p :tags))))
                        all-pages)
                ;; Pose entries too, so palette search and Random can land on a daily note.
                (mapcar (lambda (entry)
                          (let ((address (url-generic-parse-url (plist-get entry :permalink))))
                            (list :title (plist-get entry :title)
                                  :url (format "%s#%s" (url-filename address) (url-target address))
                                  :date (plist-get entry :date) :tags (vconcat (plist-get entry :tags)))))
                        (site--pose-feed-pages-for-build all-pages))))
        (tags (mapcar (lambda (tc) (list :name (plist-get tc :tag) :count (plist-get tc :count)
                                         :url (format "/tags/%s/" (downcase (plist-get tc :tag)))))
                      (denden-tag-counts all-pages))))
    (list 'raw-html nil
          (format "<script>window.__posts=%s;window.__tags=%s;window.__nav=%s;window.__paletteIcons=%s;</script>"
                  (json-serialize (vconcat posts)) (json-serialize (vconcat tags))
                  (json-serialize (vconcat site-menu-main)) (json-serialize site-palette-icons)))))

(defun site--favicon-mime-type ()
  "`site-favicon-relative-path''s MIME type, via `site--og-media-types'."
  (or (cdr (assoc (downcase (or (file-name-extension site-favicon-relative-path) ""))
                  site--og-media-types))
      "application/octet-stream"))

(cl-defun site--wrap-page (&key body rss-url title url (og-card t) description og-type
                                published-time modified-time tags noindex)
  "Wrap BODY in `theme-baseof' with this site's chrome data; pass OG-CARD nil
for a page with no OG image."
  (theme-baseof :language "en" :body body :stylesheet-href "/css/bundle.css"
                :script-href "/js/index.js" :schemes-url "/js/schemes-data.json"
                :palette-data-script site--palette-data-script-cache
                :page-title (site--page-title title) :og-title (or title site-title)
                :menu-items site-menu-header :footer-links site-menu-main
                :site-title site-title :title-quotes site-title-quotes :rss-url rss-url
                :light-schemes site--light-schemes-cache
                :footer-content site-footer-content
                :description (or description site-description)
                :canonical-url (and url (concat (string-remove-suffix "/" (site-base-url)) "/" url))
                :favicon-href (concat "/" site-favicon-relative-path)
                :favicon-type (site--favicon-mime-type)
                :touch-icon-href "/images/apple-touch-icon.png"
                :preload-fonts site-preload-fonts
                :og-type (or og-type "website") :og-image (and url og-card (site--og-image-url url))
                :published-time published-time :modified-time modified-time :tags tags
                :author-name site-author-name :noindex noindex
                :fediverse-creator site-fediverse-creator
                :analytics-script-url site-umami-script-url
                :analytics-website-id site-umami-website-id))

(defun site--write-page (page output)
  "Serialize PAGE (a theme-baseof node) to OUTPUT, doctype included."
  (make-directory (file-name-directory output) t)
  (with-temp-file output
    (insert "<!doctype html>")
    (insert (denden-serialize-node (denden-normalise-node page)))))

(defun site--related-pages (this-page all-pages body-links &optional backlinks)
  "Return pages from ALL-PAGES sharing THIS-PAGE's first two tags or refs, up
to the link budget left after BODY-LINKS and BACKLINKS, skipping BACKLINKS."
  (let* ((budget 7)
         ;; References and backlinks both use the budget; backlinks still always show.
         (n (+ (length body-links) (length backlinks)))
         (already (mapcar (lambda (l) (string-remove-suffix "/" (plist-get l :href)))
                          (seq-filter (lambda (l) (plist-get l :internal)) body-links)))
         (remaining (max 0 (- budget n)))
         (tags (seq-take (plist-get this-page :tags) 2))
         (refs (seq-take (plist-get this-page :refs) 2)))
    (if (or (>= n budget) (and (null tags) (null refs)))
        nil
      (seq-take
       (seq-filter (lambda (p) (and (not (eq p this-page)) (not (memq p backlinks))
                                    (not (member (string-remove-suffix "/" (concat "/" (plist-get p :url))) already))
                                    (or (seq-intersection (plist-get p :tags) tags)
                                        (seq-intersection (plist-get p :refs) refs))))
                   (denden-sort-pages-by-date-desc all-pages))
       remaining))))

(defun site--prev-next-in-section (this-page all-pages)
  "Return THIS-PAGE's (:prev :next) date-ordered neighbors within its own
:section, from ALL-PAGES."
  (let* ((siblings (denden-sort-pages-by-date-desc
                    (denden-pages-in-section all-pages (plist-get this-page :section))))
         (index (seq-position siblings this-page)))
    (when index
      (list :prev (nth (1+ index) siblings)
            :next (and (> index 0) (nth (1- index) siblings))))))

(defun site--toc-node (filename all-pages)
  "Return FILENAME's table-of-contents node, or nil unless it opts in via
#+toc: t."
  (when (denden-file-keyword-true-p filename "TOC")
    (let* ((options (plist-put (copy-sequence (denden-export-options-with-pages all-pages filename)) :with-toc t))
           (with-toc-html (with-temp-buffer
                            (insert-file-contents filename)
                            (org-mode)
                            (org-export-as 'denden-html nil nil t options)))
           (dom (with-temp-buffer (insert with-toc-html) (libxml-parse-html-region (point-min) (point-max))))
           (toc-div (car (dom-by-id dom (rx bos "table-of-contents" eos))))
           (toc-list (car (dom-by-id dom (rx bos "text-table-of-contents" eos)))))
      (when (and toc-div toc-list)
        (append (list 'details '(:class "toc") '(summary nil "Contents")) (dom-children toc-list))))))

(cl-defun site--assemble-and-write-single-page (&key output pub-dir body-html all-pages lastmod-source toc)
  "Assemble and write a themed single-post page at OUTPUT from BODY-HTML."
  (let* ((this-page (seq-find (lambda (p) (equal (plist-get p :url)
                                                 (denden-pretty-url (file-relative-name output pub-dir))))
                              all-pages))
         (title (or (and this-page (plist-get this-page :title)) (file-name-base output)))
         (tags (and this-page (plist-get this-page :tags)))
         (date (and this-page (plist-get this-page :date)))
         (lastmod (denden-git-lastmod lastmod-source))
         (word-count (site--word-count body-html))
         (reading-time (site--reading-time word-count))
         (body-links (denden-collect-body-links body-html))
         ;; The home page links to nearly everything, so it is no backlink.
         (backlinks (and this-page (site--regular-pages (denden-backlinks this-page all-pages))))
         (related (and this-page (site--related-pages this-page all-pages body-links backlinks)))
         (prev-next (and this-page (site--prev-next-in-section this-page all-pages))))
    (site--write-page
     (site--wrap-page
      :title title
      :url (and this-page (plist-get this-page :url))
      :description (site--meta-description-for-page
                    (list :content-html body-html :source (and this-page (plist-get this-page :source))))
      :og-type "article" :published-time date
      :modified-time (and lastmod (not (equal lastmod date)) lastmod)
      :tags tags
      :body (theme-single-page
             :post-header (theme-post-header :title title :date date :lastmod lastmod
                                             :wordcount word-count :readingtime reading-time :tags tags)
             :toc toc
             :body-html body-html
             :references (theme-references
                          :refs (mapcar (lambda (l) (list :href (plist-get l :href)
                                                          :label (plist-get l :text)
                                                          :internal (plist-get l :internal)))
                                        body-links)
                          :backlinks backlinks :related related :tag-icons site-tag-icons
                          :backlink-icon site-backlink-icon)
             :comment (theme-comment (site--first-mailto site-social-links) title)
             :post-navigation (theme-post-navigation :prev (plist-get prev-next :prev)
                                                     :next (plist-get prev-next :next))))
     output)
    output))

(defun site-publish-single-page (plist filename _pub-dir)
  "Publish FILENAME as a full themed single page, via
`site--assemble-and-write-single-page'. Stashes the rendered body onto
FILENAME's own entry in ALL-PAGES, so `site--enrich-page' can reuse it
instead of exporting FILENAME a second time."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (pub-dir (file-name-as-directory (org-publish-property :publishing-directory (cons nil plist))))
         (all-pages (plist-get plist :denden-all-pages))
         (this-page (seq-find (lambda (p) (equal (plist-get p :source) filename)) all-pages))
         (body-html (with-temp-buffer
                      (insert-file-contents filename)
                      (org-mode)
                      (org-export-as 'denden-html nil nil t (denden-export-options-with-pages all-pages filename)))))
    (when this-page (plist-put this-page :content-html body-html))
    (site--assemble-and-write-single-page
     :output output :pub-dir pub-dir :body-html body-html :all-pages all-pages
     :lastmod-source filename
     :toc (site--toc-node filename all-pages))))

(defvar site-pose-weekdays
  '((:hindi "Somvar" :meaning "Moon's day")
    (:hindi "Mangalvar" :meaning "Tyr's day, the Norse Mars")
    (:hindi "Budhvar" :meaning "Woden's day, the Norse Mercury")
    (:hindi "Guruvar" :meaning "Thor's day, the Norse Jupiter")
    (:hindi "Shukravar" :meaning "Frigg's day, the Norse Venus")
    (:hindi "Shanivar" :meaning "Saturn's day")
    (:hindi "Ravivar" :meaning "Sun's day"))
  "Pose weekdays, Monday first: Hindi name and what the English name means.
Every weekday is named after a planet; both show in the day chip's tooltip.
For my love and curiosity towards astronomy and mythology.")

(defun site--pose-entries (filename all-pages)
  "Return FILENAME's \"* [DATE] Title\" entries as plists, newest first."
  (with-temp-buffer
    (insert-file-contents filename)
    (org-mode)
    (let ((options (denden-export-options-with-pages all-pages filename))
          (seen-dates (make-hash-table :test 'equal))
          entries)
      (org-map-entries
       (lambda ()
         (when (= (org-current-level) 1)
           (let* ((headline (org-element-at-point))
                  (title-objects (org-element-parse-secondary-string
                                  (org-element-property :raw-value headline)
                                  (org-element-restriction 'headline)))
                  (timestamp (seq-find (lambda (object) (eq (org-element-type object) 'timestamp))
                                       title-objects))
                  ;; calendar.el's (MONTH DAY YEAR), straight from the parsed timestamp.
                  (calendar-date (and timestamp
                                      (list (org-element-property :month-start timestamp)
                                            (org-element-property :day-start timestamp)
                                            (org-element-property :year-start timestamp))))
                  (date (and calendar-date
                             (format "%04d-%02d-%02d" (nth 2 calendar-date) (nth 0 calendar-date)
                                     (nth 1 calendar-date))))
                  (title (string-trim
                          (org-link-display-format
                           (org-element-interpret-data (remq timestamp title-objects)))))
                  (seen (gethash date seen-dates 0))
                  ;; The date is the anchor, so links shared before the format change still work.
                  (id (or (org-element-property :CUSTOM_ID headline)
                          (if (or (null date) (> seen 0))
                              (format "%s-%d" (or date "entry") (1+ seen))
                            date)))
                  (contents-begin (org-element-property :contents-begin headline))
                  (html (if contents-begin
                            (save-restriction
                              (narrow-to-region contents-begin (org-element-property :contents-end headline))
                              (org-export-as 'denden-html nil nil t options))
                          "")))
             (puthash date (1+ seen) seen-dates)
             (push (append
                    (list :id id :title title :date date
                          :tags (org-get-tags nil t)
                          :html html
                          :search-text (downcase (concat title " " (denden-html-plain-text html))))
                    (when calendar-date
                      ;; `calendar-day-of-week' counts from Sunday = 0; ISO counts Monday = 1 to Sunday = 7.
                      (let* ((weekday (let ((day (calendar-day-of-week calendar-date))) (if (zerop day) 7 day)))
                             (planet (nth (1- weekday) site-pose-weekdays)))
                        (list :calendar-date calendar-date :weekday (number-to-string weekday)
                              :day (calendar-day-name calendar-date t)
                              :day-title (format "%s · %s · %s" (calendar-day-name calendar-date)
                                                 (plist-get planet :hindi) (plist-get planet :meaning))))))
                   entries))))
       nil nil)
      ;; ENTRIES is already in reverse file order, and `sort' is stable.
      (sort entries (lambda (a b) (string> (or (plist-get a :date) "") (or (plist-get b :date) "")))))))

(defun site--pose-week-label (calendar-date)
  "The label for CALENDAR-DATE's ISO week, like \"Week 48 · 23 to 29 Nov 2026\"."
  (let* ((iso (calendar-iso-from-absolute (calendar-absolute-from-gregorian calendar-date)))
         (monday-absolute (calendar-iso-to-absolute (list (nth 0 iso) 1 (nth 2 iso))))
         (monday (calendar-gregorian-from-absolute monday-absolute))
         (sunday (calendar-gregorian-from-absolute (+ monday-absolute 6)))
         (day-month-year (lambda (date &optional with-month with-year)
                           (concat (number-to-string (nth 1 date))
                                   (and with-month (concat " " (calendar-month-name (nth 0 date) t)))
                                   (and with-year (format " %d" (nth 2 date))))))
         (same-year (= (nth 2 monday) (nth 2 sunday)))
         (same-month (and same-year (= (nth 0 monday) (nth 0 sunday)))))
    (format "Week %d · %s to %s" (nth 0 iso)
            (funcall day-month-year monday (not same-month) (not same-year))
            (funcall day-month-year sunday t t))))

(defun site--pose-weeks (entries)
  "ENTRIES, newest first, grouped into ISO weeks as (:id :label :entries) plists."
  (let (weeks)
    (dolist (entry entries)
      (let* ((calendar-date (plist-get entry :calendar-date))
             (iso (and calendar-date (calendar-iso-from-absolute (calendar-absolute-from-gregorian calendar-date))))
             ;; ISO (WEEK DAY YEAR); the ISO year can differ from the calendar year near New Year.
             (id (if iso (format "%d-W%02d" (nth 2 iso) (nth 0 iso)) "undated")))
        (if (equal id (plist-get (car weeks) :id))
            (plist-put (car weeks) :entries (cons entry (plist-get (car weeks) :entries)))
          (push (list :id id :label (if iso (site--pose-week-label calendar-date) "Undated")
                      :entries (list entry))
                weeks))))
    (nreverse (mapcar (lambda (week) (plist-put week :entries (nreverse (plist-get week :entries)))) weeks))))

(defun site--pose-intro-html (filename all-pages)
  "Return FILENAME's content before its first heading, exported to HTML, or
\"\" if there is none."
  (with-temp-buffer
    (insert-file-contents filename)
    (org-mode)
    (goto-char (point-min))
    (when (re-search-forward (rx bol "*") nil t)
      (narrow-to-region (point-min) (match-beginning 0)))
    (org-export-as 'denden-html nil nil t (denden-export-options-with-pages all-pages filename))))

(defun site--pose-feed-pages (entries page-url base-url)
  "ENTRIES as `site--feed-pages' input, each linking its own anchor on PAGE-URL."
  (mapcar (lambda (entry)
            (list :title (plist-get entry :title)
                  :permalink (format "%s%s#%s" base-url page-url (plist-get entry :id))
                  :date (plist-get entry :date) :lastmod (plist-get entry :date)
                  :tags (plist-get entry :tags) :content-html (plist-get entry :html)))
          (seq-filter (lambda (entry) (plist-get entry :date)) entries)))

(defun site--pose-feed-pages-for-build (all-pages)
  "Every Pose entry as feed items, from the pose-layout page in ALL-PAGES."
  (let ((pose-page (seq-find (lambda (page)
                               (let ((source (plist-get page :source)) (case-fold-search t))
                                 ;; Plain text, no Org mode: the keyword sits in the file's head.
                                 (and source (file-exists-p source)
                                      (with-temp-buffer
                                        (insert-file-contents source nil 0 2000)
                                        (re-search-forward (rx bol "#+layout:" (* blank) "pose" eow) nil t)))))
                             all-pages)))
    (when pose-page
      (site--pose-feed-pages (site--pose-entries (plist-get pose-page :source) all-pages)
                             (plist-get pose-page :url) (site-base-url)))))

(defun site-publish-pose-page (plist filename pub-dir)
  "Publish FILENAME, a #+layout: pose file, via `theme-pose-page'; one page,
each entry with its own shareable anchor and expand-to-dialog view."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (all-pages (plist-get plist :denden-all-pages))
         (keywords (with-temp-buffer
                     (insert-file-contents filename)
                     (org-mode)
                     (org-collect-keywords '("TITLE" "DESC"))))
         (title (or (cadr (assoc "TITLE" keywords)) "Pose"))
         (page-url (denden-pretty-url (file-relative-name output pub-dir)))
         (this-page (seq-find (lambda (p) (equal (plist-get p :url) page-url)) all-pages))
         (entries (site--pose-entries filename all-pages)))
    (site-write-feed-trio (site--pose-feed-pages entries page-url (site-base-url))
                          (file-name-directory output) (site-base-url)
                          (format "%s: Pose" site-title) (or (cadr (assoc "DESC" keywords)) site-description)
                          site-author-name site-author-email nil site-copyright '("rss.xml"))
    (site--write-page
     (site--wrap-page
      :title title
      :url (and this-page (plist-get this-page :url))
      :rss-url (concat "/" page-url "rss.xml")
      :body (theme-pose-page
             :title title
             :intro-html (site--pose-intro-html filename all-pages)
             :weeks (site--pose-weeks entries)))
     output)))

(defun site--blank-html-p (html)
  "Non-nil if HTML has no real content once tags and whitespace are stripped."
  (string-empty-p
   (string-trim (replace-regexp-in-string
                 denden-whitespace-run-regexp " "
                 (replace-regexp-in-string (rx "<" (+ (not (any ">"))) ">") " " html)))))

(defun site-publish-home-page (plist filename pub-dir)
  "Publish FILENAME as the home page: a title+body page if it has content,
else the post listing fallback."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (all-pages (plist-get plist :denden-all-pages))
         (body-html (with-temp-buffer
                      (insert-file-contents filename)
                      (org-mode)
                      (org-export-as 'denden-html nil nil t (denden-export-options-with-pages all-pages filename))))
         (title (or (cadr (assoc "TITLE" (with-temp-buffer
                                           (insert-file-contents filename)
                                           (org-mode)
                                           (org-collect-keywords '("TITLE")))))
                    "Home")))
    (site--write-page
     (site--wrap-page
      :rss-url "/index.xml"
      :url ""
      :body (if (site--blank-html-p body-html)
                (let ((home-pages (denden-pages-in-section all-pages "log")))
                  (theme-post-listing
                   :title "Log"
                   :article-list (theme-article-list :grouped-pages (denden-group-pages-by-year home-pages)
                                                     :tag-icons site-tag-icons)))
              (theme-home-page :title title :body-html body-html)))
     output)
    output))

(defun site--file-layout (filename)
  "FILENAME's #+layout: keyword value, or nil."
  (cadr (assoc "LAYOUT" (with-temp-buffer
                          (insert-file-contents filename)
                          (org-mode)
                          (org-collect-keywords '("LAYOUT"))))))

(defun site--sort-topic-groups (groups)
  "Sort each of GROUPS's :items alphabetically by :name, for #+sort: name."
  (mapcar (lambda (group)
            (list :label (plist-get group :label)
                  :items (sort (copy-sequence (plist-get group :items))
                               (lambda (a b) (string< (plist-get a :name) (plist-get b :name))))))
          groups))

(defun site-publish-topic-list-page (plist filename pub-dir)
  "Publish FILENAME, a #+layout: topic-list file (wander, projects, media,
quotes, uses), via `theme-topic-list-page'."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (keywords (with-temp-buffer
                     (insert-file-contents filename)
                     (org-mode)
                     (org-collect-keywords '("TITLE" "DATE" "SORT" "SHOW_CONSOLE" "CHIP_COLOR"))))
         (title (or (cadr (assoc "TITLE" keywords)) (file-name-base filename)))
         (date (denden--org-date-to-iso (cadr (assoc "DATE" keywords))))
         (groups (denden-parse-topic-list filename))
         (groups (if (equal (cadr (assoc "SORT" keywords)) "name") (site--sort-topic-groups groups) groups))
         (all-pages (plist-get plist :denden-all-pages)))
    (site--write-page
     (site--wrap-page
      :title title
      :url (denden-pretty-url (file-relative-name output pub-dir))
      :body (theme-topic-list-page
             :title title :date date
             :intro-html (denden-topic-list-intro-html filename)
             :show-console (equal (cadr (assoc "SHOW_CONSOLE" keywords)) "true")
             :items-node (theme-topic-list-items :groups groups :tag-icons site-tag-icons
                                                 :chip-color (cadr (assoc "CHIP_COLOR" keywords))
                                                 :all-pages all-pages)))
     output)
    output))

(defun site-publish-themes-page (plist filename _pub-dir)
  "Publish FILENAME (the retired /themes/ gallery) as a redirect to the home page."
  (let ((output (denden-output-file-for filename (cons nil plist))))
    (site--write-string (denden-alias-redirect-html (concat (string-remove-suffix "/" (site-base-url)) "/"))
                        output)
    output))

(defun site--home-page-p (page)
  "Return non-nil if PAGE is the home page, content/index.org."
  (member (file-name-base (plist-get page :source)) '("_index" "index")))

(defun site--regular-pages (pages)
  "PAGES minus the home page."
  (seq-remove #'site--home-page-p pages))

(defun site--sitemap-groups (all-pages exclude-page)
  "Return ALL-PAGES grouped for the sitemap as (:label :count :pages) plists,
sectionless bucket first."
  (let ((sectionless (denden-sort-pages-by-title
                      (remove exclude-page
                              (site--regular-pages (denden-pages-in-section all-pages ""))))))
    (append
     (when sectionless (list (list :label "Pages" :count nil :pages sectionless)))
     (mapcar (lambda (section)
               (let ((pages (denden-sort-pages-by-title (denden-pages-in-section all-pages section))))
                 (list :label (capitalize section) :count (length pages) :pages pages)))
             (sort (copy-sequence (site--distinct-sections all-pages)) #'string<)))))

(defun site--page-as-topic-item (page)
  "Return PAGE (`denden-collect-page-metadata' shape) as a topic-list item
plist, so `site--sitemap-groups' output can go straight through
`theme-topic-list-items' instead of its own separate template."
  (list :url (concat "/" (plist-get page :url))
        :name (plist-get page :title)
        :desc ""
        :parts (append (mapcar (lambda (tag) (format "tag: %s" tag)) (plist-get page :tags))
                       (mapcar (lambda (ref) (format "refs: %s" ref)) (plist-get page :refs)))))

(defun site-publish-sitemap-page (plist filename pub-dir)
  "Publish FILENAME (content/sitemap.org) via `theme-topic-list-page': one
topic-list group per section, every page's own tags/refs as chips, and
the same search box every other topic-list page has."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (all-pages (plist-get plist :denden-all-pages))
         (this-page (seq-find (lambda (p) (equal (plist-get p :url)
                                                 (denden-pretty-url (file-relative-name output pub-dir))))
                              all-pages))
         (title (or (and this-page (plist-get this-page :title)) "Sitemap"))
         (intro-html (with-temp-buffer
                       (insert-file-contents filename)
                       (org-mode)
                       (org-export-as 'denden-html nil nil t (denden-export-options-with-pages all-pages filename))))
         (groups (mapcar (lambda (g) (list :label (plist-get g :label)
                                           :items (mapcar #'site--page-as-topic-item (plist-get g :pages))))
                         (site--sitemap-groups all-pages this-page))))
    (site--write-page
     (site--wrap-page
      :title title
      :url (and this-page (plist-get this-page :url))
      :body (theme-topic-list-page
             :title title
             :intro-html intro-html
             :items-node (theme-topic-list-items :groups groups :tag-icons site-tag-icons
                                                 :all-pages all-pages :external nil)))
     output)
    output))

(defun site--link-domain-icon (url)
  "URL's glyph from `site-tag-icons', matching its host or one part of it."
  (let ((host (string-remove-prefix "www." (or (url-host (url-generic-parse-url url)) ""))))
    (or (cl-some (lambda (text) (theme-icon-for text site-tag-icons))
                 (cons host (split-string host (rx "."))))
        (cdr (assoc "_default" site-tag-icons)))))

(defun site--links-groups (all-pages)
  "Every external link in ALL-PAGES as topic-list groups by domain, busiest first.
Sites cited only once share a last \"Other sites\" group."
  (let ((by-url (make-hash-table :test 'equal))
        (own-host (url-host (url-generic-parse-url (site-base-url))))
        urls)
    (dolist (page (site--regular-pages all-pages))
      ;; Full URLs to this site itself are internal links; the sitemap lists those.
      (dolist (link (seq-remove (lambda (link) (equal (url-host (url-generic-parse-url (plist-get link :url))) own-host))
                                (plist-get page :external-links)))
        (let* ((url (plist-get link :url))
               (entry (gethash url by-url)))
          (unless entry
            (setq entry (list :url url :text nil :pages nil))
            (push url urls))
          (unless (plist-get entry :text) (setq entry (plist-put entry :text (plist-get link :text))))
          (setq entry (plist-put entry :pages (cons page (plist-get entry :pages))))
          (puthash url entry by-url))))
    (let* ((domains (seq-group-by (lambda (url) (string-remove-prefix "www." (or (url-host (url-generic-parse-url url)) "")))
                                  urls))
           (item (lambda (url)
                   (let* ((entry (gethash url by-url))
                          (label (denden-link-label url))
                          (cited (mapconcat (lambda (page)
                                              (format "<a href=\"/%s\">%s</a>" (plist-get page :url)
                                                      (org-html-encode-plain-text (plist-get page :title))))
                                            (denden-sort-pages-by-date-desc (delete-dups (plist-get entry :pages)))
                                            ", ")))
                     (list :url url :name (or (plist-get entry :text) label) :parts nil
                           :icon (site--link-domain-icon url)
                           :desc (concat (if (plist-get entry :text) (concat (org-html-encode-plain-text label) " · ") "")
                                         "in " cited)))))
           (items (lambda (urls)
                    (sort (mapcar item urls)
                          (lambda (a b) (string< (downcase (plist-get a :name)) (downcase (plist-get b :name)))))))
           ;; A site cited once gets no heading of its own; those all share one last section.
           (shared (seq-filter (lambda (domain) (null (cddr domain))) domains))
           (own (seq-remove (lambda (domain) (null (cddr domain))) domains)))
      (append
       (mapcar (lambda (domain) (list :label (car domain) :items (funcall items (cdr domain))))
               (sort own (lambda (a b) (or (> (length (cdr a)) (length (cdr b)))
                                           (and (= (length (cdr a)) (length (cdr b))) (string< (car a) (car b)))))))
       (when shared
         (list (list :label "Other sites" :items (funcall items (mapcar #'cadr shared)))))))))

(defun site-publish-links-page (plist filename pub-dir)
  "Publish FILENAME, a #+layout: links page: every external link, by domain."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (all-pages (plist-get plist :denden-all-pages))
         (this-page (seq-find (lambda (p) (equal (plist-get p :url)
                                                 (denden-pretty-url (file-relative-name output pub-dir))))
                              all-pages))
         (title (or (and this-page (plist-get this-page :title)) "Links"))
         (intro-html (with-temp-buffer
                       (insert-file-contents filename)
                       (org-mode)
                       (org-export-as 'denden-html nil nil t (denden-export-options-with-pages all-pages filename)))))
    (site--write-page
     (site--wrap-page
      :title title
      :url (and this-page (plist-get this-page :url))
      :body (theme-topic-list-page
             :title title
             :intro-html intro-html
             :items-node (theme-topic-list-items :groups (site--links-groups all-pages) :all-pages all-pages
                                                 :collapsed t)))
     output)
    output))

(defun site-publish-page (plist filename pub-dir)
  "Dispatch FILENAME to the right site-publish-* function, by filename then
#+layout:."
  (cond
   ((member (file-name-base filename) '("_index" "index"))
    (site-publish-home-page plist filename pub-dir))
   ((equal (site--file-layout filename) "topic-list")
    (site-publish-topic-list-page plist filename pub-dir))
   ((equal (site--file-layout filename) "themes")
    (site-publish-themes-page plist filename pub-dir))
   ((equal (site--file-layout filename) "sitemap")
    (site-publish-sitemap-page plist filename pub-dir))
   ((equal (site--file-layout filename) "links")
    (site-publish-links-page plist filename pub-dir))
   ((equal (site--file-layout filename) "pose")
    (site-publish-pose-page plist filename pub-dir))
   (t (site-publish-single-page plist filename pub-dir))))

(defun site--distinct-sections (all-pages)
  "Return every non-empty :section value in ALL-PAGES, deduplicated."
  (delete-dups (delq nil (mapcar (lambda (p) (let ((section (plist-get p :section)))
                                               (and (not (string-empty-p section)) section)))
                                 all-pages))))

(defun site--write-term-page (term count pages back-url rss-url url output)
  "Write one term page (/tags/<tag>/ or /refs/<ref>/) for TERM at OUTPUT."
  (site--write-page
   (site--wrap-page
    :rss-url rss-url
    :title term
    :url url
    :body (theme-post-listing
           :title (concat "#" term)
           :term-header (theme-term-header :count count :rss-url rss-url :back-url back-url)
           :article-list (theme-article-list :grouped-pages (denden-group-pages-by-year pages)
                                             :tag-icons site-tag-icons)))
   output))

(defun site-build-taxonomy-pages (all-pages pub-dir)
  "Write one listing page per section, plus /tags/, /refs/ and their terms,
into PUB-DIR. Call after the main publish."
  (let ((tag-counts (denden-tag-counts all-pages))
        (ref-counts (denden-ref-counts all-pages)))
    (dolist (section (site--distinct-sections all-pages))
      (site--write-page
       (site--wrap-page
        :rss-url (format "/%s/index.xml" section)
        :title (capitalize section)
        :url (format "%s/" section)
        :body (theme-post-listing
               :title (capitalize section)
               :article-list (theme-article-list
                              :grouped-pages (denden-group-pages-by-year (denden-pages-in-section all-pages section))
                              :tag-icons site-tag-icons)))
       (expand-file-name (format "%s/index.html" section) pub-dir)))
    ;; /tags/ and /refs/ themselves stay rss-url-less (they list every
    ;; term, not one feed's worth), but each term page under them now
    ;; links its own narrower feed; see `site-build-term-feeds' for the
    ;; actual feed XML.
    (site--write-page
     (site--wrap-page :title "Tags" :url "tags/"
                      :body (theme-terms-list :title "Tags" :tag-counts tag-counts))
     (expand-file-name "tags/index.html" pub-dir))
    (dolist (tc tag-counts)
      (let* ((tag (plist-get tc :tag)) (tagged (denden-pages-with-tag all-pages tag)))
        (site--write-term-page tag (length tagged) tagged "/tags/"
                               (format "/tags/%s/rss.xml" (downcase tag))
                               (format "tags/%s/" (downcase tag))
                               (expand-file-name (format "tags/%s/index.html" (downcase tag)) pub-dir))))
    (when ref-counts
      (site--write-page
       (site--wrap-page :title "Refs" :url "refs/"
                        :body (theme-terms-list :title "Refs" :tag-counts ref-counts :base-url "/refs/"))
       (expand-file-name "refs/index.html" pub-dir))
      (dolist (rc ref-counts)
        (let* ((ref (plist-get rc :tag)) (referring (denden-pages-with-ref all-pages ref)))
          (site--write-term-page ref (length referring) referring "/refs/"
                                 (format "/refs/%s/rss.xml" (downcase ref))
                                 (format "refs/%s/" (downcase ref))
                                 (expand-file-name (format "refs/%s/index.html" (downcase ref)) pub-dir)))))))

(defun site--latest-post (all-pages)
  "The single newest page in ALL-PAGES's \"log\" section, or nil."
  (car (denden-sort-pages-by-date-desc (denden-pages-in-section all-pages "log"))))

(defun site--404-latest-post-item (all-pages)
  "Return the \"Latest: <link> (date)\" <li> from ALL-PAGES, or nil if there
is none."
  (let ((latest (site--latest-post all-pages)))
    (when latest
      (list 'li nil "Latest: "
            (list 'a (list :href (concat "/" (plist-get latest :url))) (plist-get latest :title))
            (format " (%s)" (plist-get latest :date))))))

(defconst site--404-wanted-poster
  '(div (:class "wanted-poster")
        (p nil "WANTED")
        (p nil "Page D. Notfound")
        (p nil (strong nil "DEAD OR ALIVE"))
        (p nil "Bounty: 404,069,420")
        (p nil "Last seen: " (code (:id "wanted-lastseen") "parts unknown"))
        (p nil (em nil "Even " (b nil "Roronoa Zoro") " would've found his way here faster.")))
  "404 page's WANTED-poster gag box.")

(defconst site--404-wanted-lastseen-script
  ;; A plain 'script' text child, not raw-html: no `&&'/`<'/`>' in this one
  ;; line for `denden--escape-text' to mangle (contrast `theme--topic-list-
  ;; search-script', which does need raw-html for exactly that reason).
  '(script nil "document.getElementById('wanted-lastseen').textContent = window.location.pathname;")
  "Fills the WANTED poster's \"Last seen\" line with the actual mistyped path,
since static HTML can't know it.")


(defun site--404-body (all-pages)
  "Return 404.html's body: the void-variable joke, WANTED poster, quick links,
latest post, and palette hint."
  (list 'div nil
        (list 'p nil (list 'code nil "Symbol's value as variable is void: /404.html"))
        site--404-wanted-poster
        (append
         (list 'ul nil
               '(li nil (a (:href "/") "Home"))
               '(li nil (a (:href "/log/") "Log")))
         (let ((latest-item (site--404-latest-post-item all-pages))) (when latest-item (list latest-item))))
        '(p nil "Or search for everything else: "
            (button (:type "button" :data-action "open-palette" :hidden t :data-requires-js t) "Search " (kbd nil "x")))
        site--404-wanted-lastseen-script))

(defun site-404-page (all-pages)
  "Return the 404 page's article, using ALL-PAGES for the latest-post link."
  (list 'article nil
        '(header nil (h1 nil "Page not found"))
        (site--404-body all-pages)))

(defun site-build-404-page (all-pages pub-dir)
  "Write PUB-DIR/404.html, from ALL-PAGES for the latest-post link."
  (site--write-page (site--wrap-page :body (site-404-page all-pages) :noindex t)
                    (expand-file-name "404.html" pub-dir)))

;;;; Auxiliary build outputs: feeds, sitemap, robots, aliases, search
;;;; index, wander.js, OG cards, 404
;;
;; :content-html/:permalink/:lastmod are not part of `denden-collect-page-
;; metadata's own plist -- they are each expensive enough (a full
;; org-export, or a git shell-out) that no caller should pay for them until
;; it actually needs them. `site--enrich-page' computes all three once,
;; shared by every function below that needs them.
;;
;; Permalinks are base-url plus the page's own pretty :url (log/foo/).
;; Per-page OG cards follow the same shape -- a sibling og.svg inside the
;; page's own pretty-URL directory.

(defun site--page-permalink (page base-url)
  "PAGE's absolute permalink: BASE-URL plus its pretty :url."
  (concat base-url (plist-get page :url)))

(defun site--enrich-page (page base-url all-pages)
  "Return PAGE plus :content-html, :permalink and :lastmod, computed via
BASE-URL and ALL-PAGES. Reuses PAGE's own :content-html if the main
publish pass already stashed it (single-post layout); other layouts
(pose, topic-list, themes, home) still export it fresh here, since their
real page body is assembled differently from this flat file export."
  (append page
          (list :content-html (or (plist-get page :content-html)
                                  (with-temp-buffer
                                    (insert-file-contents (plist-get page :source))
                                    (org-mode)
                                    (org-export-as 'denden-html nil nil t
                                                   (denden-export-options-with-pages
                                                    all-pages (plist-get page :source)))))
                :permalink (site--page-permalink page base-url)
                :lastmod (denden-page-lastmod page))))

(defun site--write-string (string output)
  "Write STRING to OUTPUT, creating its directory. Handles multibyte and
UTF-8-encoded unibyte STRING, so a batch build never hangs."
  (make-directory (file-name-directory output) t)
  (if (multibyte-string-p string)
      (let ((coding-system-for-write 'utf-8-unix))
        (with-temp-file output (insert string)))
    (let ((coding-system-for-write 'no-conversion))
      (write-region string nil output))))

(defun site--feed-pages (pages)
  "PAGES projected to `denden-atom-feed's own page shape."
  (mapcar (lambda (page) (list :title (plist-get page :title) :permalink (plist-get page :permalink)
                               :date (plist-get page :date) :lastmod (plist-get page :lastmod)
                               :tags (plist-get page :tags) :content-html (plist-get page :content-html)))
          (denden-sort-pages-by-date-desc pages)))

(defun site-write-feed-trio (pages directory base-url feed-site-title description
                                   author-name author-email favicon-url copyright &optional names)
  "Write Atom feed XML to DIRECTORY, one file per name in NAMES."
  ;; Default is the full trio: index.xml, rss.xml and feed.xml, same
  ;; content, each with its own `self' link. Real feed XML, not an HTML
  ;; meta-refresh redirect at rss.xml/feed.xml :: that breaks any client
  ;; that fetches a .xml URL and parses the body as XML by extension or
  ;; MIME type, since it never runs the HTML meta-refresh.
  (dolist (name (or names '("index.xml" "rss.xml" "feed.xml")))
    (let* ((self-url (concat (file-name-as-directory base-url) name))
           (xml (denden-atom-feed :pages (site--feed-pages pages) :site-title feed-site-title
                                  :description description :base-url base-url :self-url self-url
                                  :author-name author-name :author-email author-email
                                  :favicon-url favicon-url :copyright copyright)))
      (site--write-string xml (expand-file-name name directory)))))

(defun site-build-term-feeds (pages pub-dir)
  "Write one rss.xml per tag and per ref in PAGES under PUB-DIR."
  ;; Just rss.xml, not the main/log feeds' full trio. A tag feed is only
  ;; ever found by its own rel=alternate link, never typed in by hand, so
  ;; the rss.xml/feed.xml/index.xml redundancy buys nothing here.
  (dolist (tag-count (denden-tag-counts pages))
    (let ((tag (plist-get tag-count :tag)))
      (site-write-feed-trio (denden-pages-with-tag pages tag)
                            (expand-file-name (format "tags/%s" (downcase tag)) pub-dir)
                            (site-base-url) (format "%s: %s" site-title tag)
                            (format "Posts tagged %s on %s" tag site-title)
                            site-author-name site-author-email nil site-copyright '("rss.xml"))))
  (dolist (ref-count (denden-ref-counts pages))
    (let ((ref (plist-get ref-count :tag)))
      (site-write-feed-trio (denden-pages-with-ref pages ref)
                            (expand-file-name (format "refs/%s" (downcase ref)) pub-dir)
                            (site-base-url) (format "%s: %s" site-title ref)
                            (format "Posts referencing %s on %s" ref site-title)
                            site-author-name site-author-email nil site-copyright '("rss.xml")))))

(defun site-build-sitemap (all-pages pub-dir)
  "Write PUB-DIR/sitemap.xml over ALL-PAGES."
  (site--write-string
   (denden-sitemap-xml (mapcar (lambda (p) (list :permalink (plist-get p :permalink) :lastmod (plist-get p :lastmod)))
                               all-pages))
   (expand-file-name "sitemap.xml" pub-dir)))

(defun site-build-robots (base-url pub-dir)
  "Write PUB-DIR/robots.txt, pointing at the sitemap under BASE-URL."
  (site--write-string (denden-robots-txt base-url) (expand-file-name "robots.txt" pub-dir)))

(defun site-build-aliases (all-pages pub-dir)
  "For every page in ALL-PAGES with :aliases, write a redirect at
ALIAS/index.html under PUB-DIR."
  (dolist (page all-pages)
    (dolist (alias (plist-get page :aliases))
      (site--write-string (denden-alias-redirect-html (plist-get page :permalink))
                          (expand-file-name (format "%s/index.html" alias) pub-dir)))))

(defconst site-legacy-section-redirects
  '(("posts" . "log"))
  "Old section slug -> new, for a renamed section's own listing page.")

(defun site-build-legacy-redirects (base-url pub-dir)
  "Write a redirect for every old section listing page in PUB-DIR, per
`site-legacy-section-redirects'."
  (dolist (rename site-legacy-section-redirects)
    (site--write-string
     (denden-alias-redirect-html (format "%s/%s/" (string-remove-suffix "/" base-url) (cdr rename)))
     (expand-file-name (format "%s/index.html" (car rename)) pub-dir))))

(defun site-build-search-index (all-pages pub-dir)
  "Write PUB-DIR/search-index.json over every page in ALL-PAGES."
  (site--write-string
   (denden-search-index-json
    (mapcar (lambda (p) (list :title (plist-get p :title) :url (concat "/" (plist-get p :url))
                              :plain-text (denden-html-plain-text (plist-get p :content-html))))
            all-pages))
   (expand-file-name "search-index.json" pub-dir)))

(defconst site--wander-colors-script
  ";(function(){try{var c=JSON.parse(localStorage.getItem('emacs-wander-colors'));if(c)Object.keys(c).forEach(function(k){document.documentElement.style.setProperty(k,c[k]);});}catch(e){}})();\n"
  "Appended to wander.js: paints the console in the colours the site saved.")

(defun site-build-wander-js (wander-source-file pub-dir)
  "Write PUB-DIR/wander/console/wander.js from WANDER-SOURCE-FILE, split into
consoles and pages by H2 label."
  (let (consoles pages)
    (dolist (group (denden-parse-topic-list wander-source-file))
      (let ((is-console (string-search "console" (downcase (plist-get group :label)))))
        (dolist (item (plist-get group :items))
          (if is-console (push (plist-get item :url) consoles) (push (plist-get item :url) pages)))))
    (site--write-string
     (concat (format "const wander = { consoles:\n[%s],\npages:\n[%s],\nstyles: [\"wander-theme.css\"], ignore: [], }\n"
                     (site--wander-js-array (nreverse consoles)) (site--wander-js-array (nreverse pages)))
             site--wander-colors-script)
     (expand-file-name "wander.js" (expand-file-name "wander/console" pub-dir)))))

(defun site--wander-js-array (urls)
  "Return URLS as wander.js's one-per-line jsonified array body."
  (mapconcat (lambda (url) (format "  %s,\n" (json-serialize url))) urls ""))

(defconst site-wander-theme-css-source
  (expand-file-name "assets/css/wander-theme.css" denden-repository-directory)
  "This site's wander-console theme override, copied by hand since
static/wander/console/ is a submodule checkout.")


(defun site-build-wander-theme-css (pub-dir)
  "Copy `site-wander-theme-css-source' to PUB-DIR/wander/console/ verbatim."
  (let ((output (expand-file-name "wander-theme.css" (expand-file-name "wander/console" pub-dir))))
    (make-directory (file-name-directory output) t)
    (copy-file site-wander-theme-css-source output t)))

(defun site--og-svg-output-path (page pub-dir)
  "PAGE's OG SVG output path under PUB-DIR: og.svg in its own pretty-URL dir."
  (expand-file-name (concat (plist-get page :url) "og.svg") pub-dir))

(defconst site-og-png-directory
  (expand-file-name "static/og" denden-repository-directory)
  "Where rasterized OG-card PNGs live. Run `just og' by hand; the Elisp build
never writes these.")


(defun site--og-slug (pretty-url)
  "PRETTY-URL's OG slug: its last path segment, or \"home\" for none."
  (if (string-empty-p pretty-url)
      "home"
    (file-name-nondirectory (directory-file-name pretty-url))))

(defun site--og-image-url (pretty-url)
  "Return PRETTY-URL's absolute OG-image URL, or nil if none exists."
  ;; Its own rasterized PNG if one exists (Log posts only), else the
  ;; site's one common card at /og/home.png.
  (let* ((slug (site--og-slug pretty-url))
         (own (expand-file-name (concat slug ".png") site-og-png-directory))
         (common (expand-file-name "home.png" site-og-png-directory))
         (base (string-remove-suffix "/" (site-base-url))))
    (cond ((file-exists-p own) (concat base "/og/" slug ".png"))
          ((file-exists-p common) (concat base "/og/home.png"))
          (t nil))))

(defun site--og-prose-paragraphs (node)
  "Return every <p> element under NODE, in document order, skipping the
contents of any <div class=\"figure\"> or <figure> element. Those hold an
image and its caption, both rendered as plain <p> tags with no class of
their own once `denden-paragraph' strips the \"Figure N:\" prefix, so
they would otherwise look like body prose."
  (cond
   ((not (consp node)) nil)
   ((eq (dom-tag node) 'figure) nil)
   ((and (eq (dom-tag node) 'div) (equal (dom-attr node 'class) "figure")) nil)
   ((eq (dom-tag node) 'p) (list node))
   (t (seq-mapcat #'site--og-prose-paragraphs (dom-children node)))))

(defun site--og-excerpt-for-page (page)
  "Return PAGE's OG-card excerpt: its #+description/#+desc/#+og_description:
keyword if its source sets one, otherwise the first two body-prose <p>s of
its rendered content, as blank-line separated plain text. Skips any <p>
that is really an image or its caption; see `site--og-prose-paragraphs'."
  (let* ((source (plist-get page :source))
         (keywords (and source (file-exists-p source)
                        (with-temp-buffer
                          (insert-file-contents source)
                          (org-mode)
                          (org-collect-keywords '("DESCRIPTION" "DESC" "OG_DESCRIPTION")))))
         (description (and keywords
                           (or (cadr (assoc "DESCRIPTION" keywords))
                               (cadr (assoc "DESC" keywords))
                               (cadr (assoc "OG_DESCRIPTION" keywords))))))
    (or description
        (let* ((dom (with-temp-buffer (insert (plist-get page :content-html))
                                      (libxml-parse-html-region (point-min) (point-max))))
               (paragraphs (seq-take (site--og-prose-paragraphs dom) 2)))
          (mapconcat (lambda (p) (string-trim (dom-texts p))) paragraphs "\n\n")))))

(defun site--meta-description-for-page (page)
  "Return PAGE's meta-description text: its OG excerpt, collapsed to one line
and capped at 160 characters."
  (let ((text (replace-regexp-in-string denden-whitespace-run-regexp " " (site--og-excerpt-for-page page))))
    (if (> (length text) 160) (concat (substring text 0 159) "…") text)))

(cl-defun site-build-og-cards (&key pages card-site-title favicon-path pub-dir word-count-fn)
  "Write one OG-card SVG per page in PAGES under PUB-DIR, titled
CARD-SITE-TITLE, with FAVICON-PATH embedded."
  (dolist (page pages)
    (site--write-string
     (site-og-card-svg :title (plist-get page :title)
                       :excerpt (site--og-excerpt-for-page page)
                       :tags (plist-get page :tags)
                       :slug (plist-get page :url)
                       :date (plist-get page :date) :meta-right (funcall word-count-fn page)
                       :card-site-title card-site-title :favicon-path favicon-path)
     (site--og-svg-output-path page pub-dir))))

(defun site--word-count-meta (page)
  "PAGE's \"N words · M min\" OG-card meta-right, from its own :content-html."
  (let* ((word-count (site--word-count (plist-get page :content-html)))
         (reading-time (site--reading-time word-count)))
    (format "%d words · %d min" word-count reading-time)))

(defun site-build-auxiliary-outputs (all-pages pub-dir repository-directory)
  "Write every auxiliary output (feeds, sitemap, robots.txt, redirects, search
index, OG cards, 404) into PUB-DIR."
  (let* ((enriched (mapcar (lambda (p) (site--enrich-page p (site-base-url) all-pages)) all-pages))
         (regular (site--regular-pages enriched))
         (favicon-path (expand-file-name site-favicon-relative-path
                                         (expand-file-name "static" repository-directory))))
    ;; Only Log and Pose are syndicated: the rest (Wander, Media, Quotes,
    ;; every standalone page) are for browsing. The main feed carries both;
    ;; /log/ and /pose/ each keep a feed of their own.
    (site-write-feed-trio (append (denden-pages-in-section regular "log") (site--pose-feed-pages-for-build all-pages))
                          pub-dir (site-base-url) site-title
                          site-description site-author-name site-author-email nil site-copyright)
    (site-write-feed-trio (denden-pages-in-section regular "log") (expand-file-name "log" pub-dir)
                          (site-base-url) site-title site-description
                          site-author-name site-author-email nil site-copyright)
    (site-build-term-feeds regular pub-dir)
    (site-build-sitemap enriched pub-dir)
    (site-build-robots (site-base-url) pub-dir)
    (site-build-aliases enriched pub-dir)
    (site-build-legacy-redirects (site-base-url) pub-dir)
    (site-build-search-index regular pub-dir)
    (site-build-wander-js (expand-file-name "content/wander.org" repository-directory) pub-dir)
    (site-build-wander-theme-css pub-dir)
    ;; Only Log posts earn their own OG card: a real excerpt and word
    ;; count is worth the per-post render. Every other page, standalone
    ;; pages and every section listing like /wander/ or /projects/ alike,
    ;; shares this one static home card instead, via `site--og-image-url's
    ;; fallback to og/home.png. No title, no words, never changes.
    (site-build-og-cards :pages (denden-pages-in-section regular "log") :card-site-title site-title
                         :favicon-path favicon-path :pub-dir pub-dir :word-count-fn #'site--word-count-meta)
    ;; The one shared card, built from the home page's own excerpt (its
    ;; #+description: keyword if index.org sets one, else its own first
    ;; paragraphs). No slug or meta-right: this card is reused as-is on
    ;; every non-Log page, so nothing page-specific belongs on it.
    (let ((home-page (seq-find #'site--home-page-p enriched)))
      (site--write-string
       (site-og-card-svg :title site-title
                         :excerpt (or (and home-page (site--og-excerpt-for-page home-page)) "")
                         :tags nil :slug nil :date nil :meta-right nil
                         :card-site-title site-title :favicon-path favicon-path)
       (expand-file-name "og.svg" pub-dir)))
    (site-build-404-page all-pages pub-dir)))

;;;; org-publish project definition, real build entry points

(defconst site-async-init-file
  (expand-file-name "site-async-init.el" (expand-file-name "site" denden-repository-directory))
  "Path to site-async-init.el, computed once at load time so any later caller
works, not just site.el's own load.")


(setq org-publish-project-alist
      (list
       (list "site-org"
             :base-directory (expand-file-name "content" denden-repository-directory)
             :base-extension "org"
             :recursive t
             :publishing-directory site-publishing-directory
             :publishing-function 'site-publish-page
             :denden-output-extension ".html"
             ;; Real content has links our placeholder link transcoder can't
             ;; resolve yet. Mark them instead of aborting the whole file's
             ;; export.
             :with-broken-links 'mark
             ;; Real disabled <input type="checkbox">, not <code>[X]</code>.
             :html-checkbox-type 'html
             ;; A #+draft: t file is excluded from a non-draft build: this
             ;; site's prod command is `hugo --minify', no -D.
             :exclude (denden-draft-exclude-regexp (expand-file-name "content" denden-repository-directory)))
       (list "site-static"
             :base-directory (expand-file-name "static" denden-repository-directory)
             :base-extension 'any
             :recursive t
             :publishing-directory site-publishing-directory
             :publishing-function 'org-publish-attachment)
       (list "site" :components '("site-org" "site-static"))))

(defconst site-css-source-file
  (expand-file-name "assets/css/theme.css" denden-repository-directory)
  "This site's one real, hand-edited CSS file.")


(defun site--custom-css-text ()
  "Return `site-css-source-file''s content, for `site-all-schemes' to parse
its @scheme comments."
  (with-temp-buffer
    (insert-file-contents site-css-source-file)
    (buffer-string)))

(defun site-build-stylesheet (pub-dir)
  "Concatenate the real CSS file plus generated scheme and highlight CSS into
PUB-DIR/css/bundle.css."
  (let ((output (expand-file-name "css/bundle.css" pub-dir)))
    (make-directory (file-name-directory output) t)
    (with-temp-file output
      (insert-file-contents site-css-source-file)
      (goto-char (point-max))
      (insert "\n/* ---- generated: base16 scheme variables (site-scheme-css) ---- */\n")
      (insert (site-scheme-css site-color-schemes))
      (insert "\n/* ---- generated: code-highlight colors (site-highlight-stylesheet) ---- */\n")
      (insert (site-highlight-stylesheet)))))

(defconst site-js-source-file
  (expand-file-name "assets/js/index.js" denden-repository-directory)
  "The site's real JS: one hand-edited file, kept in sync with Hugo's copy by
hand.")


(defun site-build-scripts (pub-dir)
  "Copy `site-js-source-file' to PUB-DIR/js/index.js verbatim."
  (let ((output (expand-file-name "js/index.js" pub-dir)))
    (make-directory (file-name-directory output) t)
    (copy-file site-js-source-file output t)))

(defun site-build-schemes-json (pub-dir)
  "Write PUB-DIR/js/schemes-data.json, the command-palette's data source."
  (let ((output (expand-file-name "js/schemes-data.json" pub-dir))
        (coding-system-for-write 'no-conversion))
    (make-directory (file-name-directory output) t)
    (write-region (site-schemes-json (site--custom-css-text)) nil output)))

(defvar site--light-schemes-cache nil
  "Scheme names with a readable light variant, set by `site--inject-all-pages'.")

(defvar site--palette-data-script-cache nil
  "This build's command-palette data script, a `raw-html' node, computed once
by `site--inject-all-pages'.")


(defun site--inject-all-pages ()
  "Compute this build's page metadata, custom.css text, and palette script
once, stashed for reuse across pages."
  (let* ((leaves (org-publish-expand-projects (list (assoc "site-org" org-publish-project-alist))))
         (all-pages (denden-collect-page-metadata leaves))
         (entry (assoc "site-org" org-publish-project-alist)))
    (setcdr entry (plist-put (plist-put (copy-sequence (cdr entry)) :denden-all-pages all-pages)
                             :site-custom-css-text (site--custom-css-text)))
    (setq site--palette-data-script-cache (site--palette-data-script all-pages))
    (setq site--light-schemes-cache
          (site-light-scheme-names site-color-schemes (site-parse-custom-css-schemes (site--custom-css-text))))
    all-pages))

(defun site-build (&optional force)
  "Build the site synchronously, plus taxonomy pages and every auxiliary
output, using the cache unless FORCE."
  (let* ((coding-system-for-read 'utf-8-unix)
         (coding-system-for-write 'utf-8-unix)
         (org-confirm-babel-evaluate nil)
         (denden--git-lastmod-table (denden-git-lastmod-table denden-repository-directory))
         (all-pages (site--inject-all-pages)))
    (denden-build-project (assoc "site" org-publish-project-alist) force)
    (site-build-taxonomy-pages all-pages site-publishing-directory)
    (site-build-stylesheet site-publishing-directory)
    (site-build-scripts site-publishing-directory)
    (site-build-schemes-json site-publishing-directory)
    (site-build-auxiliary-outputs all-pages site-publishing-directory denden-repository-directory)))

(defcustom site-dev-include-drafts t
  "Non-nil: dev-only rebuilds include drafts; the real production build never does.
`site-build-async'/`site-build-file-async' (never `site-build') clear
the \"site-org\" project's draft :exclude for that one child process, so
a page you're actively drafting rebuilds live too. Matches Hugo's own
`-D' dev-serve flag: drafts still never appear in a real build, only in
the live-preview loop."
  :type 'boolean :group 'denden)

(defun site--maybe-clear-draft-exclude ()
  "Clear the draft :exclude when `site-dev-include-drafts' is non-nil, once
early in a dev-build async child."
  (when site-dev-include-drafts
    (let ((entry (assoc "site-org" org-publish-project-alist)))
      (setcdr entry (plist-put (copy-sequence (cdr entry)) :exclude nil)))))

(defun site-build-async (&optional force on-done)
  "Build the site in a separate process, non-blocking; page-metadata
collection runs inside the child, not the parent."
  (let ((pub-dir site-publishing-directory)
        (repository-directory denden-repository-directory)
        (org-export-async-init-file site-async-init-file)
        (include-drafts site-dev-include-drafts))
    (org-export-async-start
        (or on-done (lambda (_) nil))
      `(progn
         (setq site-dev-include-drafts ,include-drafts)
         (site--maybe-clear-draft-exclude)
         (let ((denden--git-lastmod-table (denden-git-lastmod-table ,repository-directory))
               (all-pages (site--inject-all-pages)))
           (denden-build-project (assoc "site" org-publish-project-alist) ,force)
           (site-build-taxonomy-pages all-pages ,pub-dir)
           (site-build-stylesheet ,pub-dir)
           (site-build-scripts ,pub-dir)
           (site-build-schemes-json ,pub-dir)
           (site-build-auxiliary-outputs all-pages ,pub-dir ,repository-directory))))))

(defun site-build-file-async (file on-done)
  "Rebuild just FILE in a separate process, skipping CSS/JS/feeds/OG cards;
refreshes cross-page metadata first."
  (let ((org-export-async-init-file site-async-init-file)
        (include-drafts site-dev-include-drafts))
    (org-export-async-start
        (or on-done (lambda (_) nil))
      `(progn
         (setq site-dev-include-drafts ,include-drafts)
         (site--maybe-clear-draft-exclude)
         (site--inject-all-pages)
         (let ((org-publish-use-timestamps-flag nil))
           (org-publish-file ,file (assoc "site-org" org-publish-project-alist)))
         nil))))

;;;; Wire this site into denden's generic customize/command surface

(setq denden-content-directory (expand-file-name "content" denden-repository-directory))
(setq denden-post-directory (expand-file-name "log" denden-content-directory))
(setq denden-publishing-directory site-publishing-directory)
(setq denden-project-root-directory denden-repository-directory)
(setq denden-link-label-rules
      (list (cons (rx bos "github.com/" (group (+ anything))) "github:\\1")
            (cons (rx bos "codeberg.org/" (group (+ anything))) "codeberg:\\1")
            ;; Only a bare subreddit or user; a post link keeps its full path.
            (cons (rx bos (opt "old.") "reddit.com/" (group (any "ru") "/" (+ (not (any "/")))) eos) "\\1")))
(setq denden-full-build-function #'site-build)
(setq denden-build-function #'site-build-async)
(setq denden-build-file-function #'site-build-file-async)

;;;; This site's own M-x commands, via `denden-define-command'

(denden-define-command idlip og-regenerate-all ()
                       "Regenerate every Log post's OG card SVG, without a full rebuild."
                       (let* ((leaves (org-publish-expand-projects (list (assoc "site" org-publish-project-alist))))
                              (all-pages (denden-collect-page-metadata leaves))
                              (enriched (mapcar (lambda (p) (site--enrich-page p (site-base-url) all-pages)) all-pages))
                              (regular (site--regular-pages enriched))
                              (favicon-path (expand-file-name site-favicon-relative-path
                                                              (expand-file-name "static" denden-repository-directory))))
                         (site-build-og-cards :pages (denden-pages-in-section regular "log") :card-site-title site-title
                                              :favicon-path favicon-path
                                              :pub-dir site-publishing-directory :word-count-fn #'site--word-count-meta)))

(provide 'site)
;;; site.el ends here
