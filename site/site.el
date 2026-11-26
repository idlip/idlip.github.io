;;; site.el --- idlip.in: site data, layouts and outputs -*- lexical-binding: t; -*-

;;; Commentary:

;; idlip.in on Denden: the site's data (menus, colour schemes, social
;; links, icons, badges), its layouts (single pages, home, Pose, topic
;; lists, sitemap, links, generated lists of sections and tags, 404),
;; and its outputs (feeds, redirects, search index, the Wander console
;; files, the style sheet bundle, OG cards).  Templates live in theme.el.
;;
;; Build it with M-x denden-build, or `just build' from a shell.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'dom)
(require 'rx)
(require 'calendar)
(require 'cal-iso)
(require 'url-parse)
(require 'denden)
(require 'theme)
(require 'site-schemes-base16)

(defconst site-root-directory
  (file-name-directory (directory-file-name (file-name-directory (or load-file-name buffer-file-name))))
  "Root folder of the site: the folder above the one that holds site.el.")

(defconst site-js-source-file "assets/js/index.js"
  "The site's one hand-edited script, relative to the site's root.")

(defconst site-css-source-file "assets/css/theme.css"
  "The site's one hand-edited style sheet, relative to the site's root.")

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
    (:name " Projects & Tools" :url "/projects/")
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

(defconst site-umami-script-url "https://analytics.fossunited.org/script.js")

(defconst site-umami-website-id "64825a51-be1b-416e-b1ec-895aa541dcab")

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

(declare-function yaml-parse-string "yaml" (string &rest args))

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

(defun site-generate-schemes-base16-file (&optional schemes-directory output-file)
  "Parse every base16 yaml under SCHEMES-DIRECTORY and write OUTPUT-FILE, a
committed elisp data file. Run by hand."
  (interactive)
  (let* ((schemes-directory (or schemes-directory
                                (expand-file-name "data/schemes/base16/" site-root-directory)))
         (output-file (or output-file
                          (expand-file-name "site-schemes-base16.el"
                                            (file-name-directory (or load-file-name buffer-file-name)))))
         (entries (mapcar #'site--yaml-scheme-file-to-entry
                          (sort (directory-files schemes-directory t (rx ".yaml" eos)) #'string<))))
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
  "Return the CSS that colours highlighted code with the base16 variables."
  (mapconcat (lambda (entry) (format ".%s { color: %s; }" (car entry) (cdr entry)))
             site-highlight-class-colors "\n"))

;;;; This site's OG card template
;;
;; A 1200x630 card in the site's Haki look, written as SVG.  `just og'
;; turns each card into a PNG by hand.

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
          :lines (site--truncate-lines (site--wrap-words title wrap-width) 3))))

(defun site--og-excerpt-lines (excerpt max-lines)
  "EXCERPT wrapped at 64 characters, at most MAX-LINES lines, gaps kept."
  (when (and excerpt (> max-lines 0))
    (site--truncate-lines
     (seq-mapcat (lambda (source-line)
                   (if (string-empty-p source-line)
                       (list "")
                     (site--wrap-words (replace-regexp-in-string (rx (+ (any " \t"))) " " (string-trim source-line)) 64)))
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
                                 base-url (font "Code D OnePiece"))
  "Return the 1200x630 OG card of TITLE as SVG text, in Haki colours.
EXCERPT, TAGS, SLUG, DATE and META-RIGHT fill the card; CARD-SITE-TITLE
and the image at FAVICON-PATH head it; BASE-URL gives the address
shown; FONT is the font family."
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
         (domain (string-remove-prefix "https://" (string-remove-suffix "/" (or base-url ""))))
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
    (denden-serialize-node tree)))

;;;; Text helpers

(defun site--wrap-words (text max-width)
  "Return TEXT wrapped greedily into lines of at most MAX-WIDTH characters."
  (let ((lines nil)
        (current ""))
    (dolist (word (split-string text " " t))
      (let ((candidate (if (string-empty-p current) word (concat current " " word))))
        (if (> (length candidate) max-width)
            (progn (unless (string-empty-p current) (push current lines))
                   (setq current word))
          (setq current candidate))))
    (unless (string-empty-p current) (push current lines))
    (nreverse lines)))

(defun site--truncate-lines (lines max-lines)
  "Return at most MAX-LINES of LINES, with an ellipsis when some were cut."
  (if (<= (length lines) max-lines)
      lines
    (let ((kept (seq-take lines max-lines)))
      (append (seq-take kept (1- max-lines))
              (list (concat (car (last kept)) "…"))))))

(defun site--word-count (page)
  "Return the number of words in the body of PAGE."
  (length (split-string (denden-html-plain-text (or (denden-page-body page) "")) nil t)))

(defun site--reading-time (word-count)
  "Return the reading time in whole minutes for WORD-COUNT words, at least 1."
  (max 1 (round (/ word-count 200.0))))

(defun site--true-p (value)
  "Return non-nil when the keyword VALUE means true, such as t or true."
  (and value (member (downcase (string-trim value)) '("t" "true" "yes"))))

(defun site--meta (page key)
  "Return the value of KEY in the meta plist of PAGE."
  (plist-get (denden-page-meta page) key))

(defun site--remember (page key compute)
  "Return the value stored under KEY in PAGE, calling COMPUTE once to make it.
The value lives in the page's meta plist, so it lasts for one build."
  (or (site--meta page key)
      (let ((value (funcall compute)))
        (setf (denden-page-meta page) (plist-put (denden-page-meta page) key value))
        value)))

(defun site--tags (page)
  "Return the tags of PAGE."
  (denden-page-taxonomy-terms page "tags"))

(defun site--refs (page)
  "Return the refs of PAGE."
  (denden-page-taxonomy-terms page "refs"))

(defun site--intro-html (page)
  "Return the body of PAGE before its first section, as HTML."
  (let* ((body (or (denden-page-body page) ""))
         (split-point (string-search "<div id=\"outline-container-" body)))
    (if split-point (substring body 0 split-point) body)))

(defun site--strip-paragraph (html)
  "Return HTML without the one paragraph element around it, if it has one."
  (let ((html (string-trim html)))
    (if (and (string-prefix-p "<p>" html) (string-suffix-p "</p>" html))
        (string-trim (substring html 3 -4))
      html)))

(defun site--home-page-p (page)
  "Return non-nil if PAGE is the home page."
  (string-empty-p (denden-page-url page)))

(defun site--regular-pages (pages)
  "Return PAGES without the home page."
  (seq-remove #'site--home-page-p pages))

(defun site-pose-page (pages)
  "Return the page of PAGES whose layout is pose, or nil."
  (seq-find (lambda (page) (equal (denden-page-layout page) "pose")) pages))

;;;; Topic lists (wander, projects, media, quotes, uses)
;;
;; A topic-list page is Org with one heading per group and a descriptive
;; list of items under it: "- [[URL][Name]] :: description | key: value".
;; The parts after " | " become chips.

(defun site--topic-item (item)
  "Return the parts of the descriptive list ITEM, before any export.
The result is a plist with :url, :name, :description-text and
:parts, each part a plist with :key and :value.  The name is the
link's text, or the term itself when it has no link; :url is then
empty."
  (let* ((link (car (org-element-map (org-element-property :tag item) 'link #'identity)))
         (begin (org-element-contents-begin item))
         (end (org-element-contents-end item))
         (raw (if (and begin end) (string-trim (buffer-substring-no-properties begin end)) ""))
         (segments (mapcar #'string-trim (split-string raw " | "))))
    (list :url (if link (org-element-property :raw-link link) "")
          ;; A term without a link is shown as its own text.
          :name (if link
                    (let ((link-begin (org-element-contents-begin link))
                          (link-end (org-element-contents-end link)))
                      (if (and link-begin link-end)
                          (string-trim (buffer-substring-no-properties link-begin link-end))
                        (org-element-property :raw-link link)))
                  (string-trim (org-no-properties
                                (org-element-interpret-data (org-element-property :tag item)))))
          :description-text (or (car segments) "")
          :parts (mapcar (lambda (segment)
                           (let ((colon (string-search ":" segment)))
                             (list :key (if colon (string-trim (substring segment 0 colon)) segment)
                                   :value (if colon (string-trim (substring segment (1+ colon))) ""))))
                         (cdr segments)))))

(defun site--parse-topic-groups (page)
  "Return the groups of the topic-list PAGE, before any export.
Each group is a plist with :label and :items."
  (with-temp-buffer
    (insert (denden-page-text page))
    (delay-mode-hooks (org-mode))
    (org-element-map (org-element-parse-buffer) 'headline
      (lambda (headline)
        (list :label (org-element-property :raw-value headline)
              :items (mapcan (lambda (plain-list)
                               (and (eq (org-element-property :type plain-list) 'descriptive)
                                    (mapcar #'site--topic-item
                                            (org-element-map plain-list 'item #'identity))))
                             (org-element-map (org-element-contents headline) 'plain-list
                               #'identity nil nil 'headline))))
      nil nil 'headline)))

(defun site-topic-groups (site page pages)
  "Return the groups of the topic-list PAGE of SITE, given all PAGES.
Each group is a plist with :label and :items.  Each item is a plist
with :url, :name, :description (HTML) and :parts, each part a plist
with :key, :value and :html.  Every description and part is exported
in one batch, and the result is kept in PAGE for the rest of the
build.  With #+sort: name, items are sorted by name."
  (site--remember
   page :site-topic-groups
   (lambda ()
     (let* ((groups (site--parse-topic-groups page))
            (items (mapcan (lambda (group) (copy-sequence (plist-get group :items))) groups))
            (texts (mapcan (lambda (item)
                             (cons (plist-get item :description-text)
                                   (mapcar (lambda (part) (plist-get part :value))
                                           (plist-get item :parts))))
                           items))
            ;; One HTML piece per text, in the order of TEXTS.
            (html (mapcar #'site--strip-paragraph
                          (and texts (denden-export-org-strings site texts pages page))))
            (by-name (equal (site--meta page :sort) "name")))
       (mapcar (lambda (group)
                 (let ((items (mapcar (lambda (item)
                                        (list :url (plist-get item :url)
                                              :name (plist-get item :name)
                                              :description (pop html)
                                              :parts (mapcar (lambda (part)
                                                               (list :key (plist-get part :key)
                                                                     :value (plist-get part :value)
                                                                     :html (pop html)))
                                                             (plist-get item :parts))))
                                      (plist-get group :items))))
                   (list :label (plist-get group :label)
                         :items (if by-name
                                    (sort items :key (lambda (item) (plist-get item :name)))
                                  items))))
               groups)))))

;;;; Pose

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

(defun site--pose-entry (headline)
  "Return the Pose entry of HEADLINE, a top-level heading, before export.
The plist has :custom-id, :title, :date, :tags, :clock (hour and
minute, when the heading's timestamp has them), :line (the heading's
line in the file), :body-text, and for a dated entry :calendar-date,
:weekday, :day and :day-title."
  (let* ((title-objects (org-element-parse-secondary-string
                         (org-element-property :raw-value headline)
                         (org-element-restriction 'headline)))
         (timestamp (seq-find (lambda (object) (org-element-type-p object 'timestamp))
                              title-objects))
         ;; calendar.el's (MONTH DAY YEAR), straight from the parsed timestamp.
         (calendar-date (and timestamp
                             (list (org-element-property :month-start timestamp)
                                   (org-element-property :day-start timestamp)
                                   (org-element-property :year-start timestamp))))
         (begin (org-element-contents-begin headline))
         (end (org-element-contents-end headline)))
    (append
     (list :custom-id (org-element-property :CUSTOM_ID headline)
           :title (string-trim (org-no-properties
                                (org-link-display-format
                                 (org-element-interpret-data (remq timestamp title-objects)))))
           :date (and calendar-date
                      (format "%04d-%02d-%02d" (nth 2 calendar-date) (nth 0 calendar-date)
                              (nth 1 calendar-date)))
           :tags (org-element-property :tags headline)
           :clock (and timestamp (org-element-property :hour-start timestamp)
                       (list (org-element-property :hour-start timestamp)
                             (org-element-property :minute-start timestamp)))
           :line (line-number-at-pos (org-element-begin headline))
           :body-text (if (and begin end) (buffer-substring-no-properties begin end) ""))
     (and calendar-date
          ;; `calendar-day-of-week' counts from Sunday = 0; ISO counts Monday = 1 to Sunday = 7.
          (let* ((weekday (let ((day (calendar-day-of-week calendar-date))) (if (zerop day) 7 day)))
                 (planet (nth (1- weekday) site-pose-weekdays)))
            (list :calendar-date calendar-date
                  :weekday (number-to-string weekday)
                  :day (calendar-day-name calendar-date t)
                  :day-title (format "%s · %s · %s" (calendar-day-name calendar-date)
                                     (plist-get planet :hindi) (plist-get planet :meaning))))))))

(defun site--line-commit-times (file)
  "Return a hash table from each line number of FILE to its commit time.
The time is that of the commit that last changed the line, from one
git blame.  Lines not committed yet are left out.  Return nil when
FILE is not in git or `denden-lastmod-from-git' is nil."
  (and denden-lastmod-from-git
       (condition-case nil
           (let ((default-directory (file-name-directory file))
                 (times (make-hash-table))
                 (line nil))
             (dolist (text (process-lines "git" "blame" "--line-porcelain" "--"
                                          (file-name-nondirectory file)))
               (cond
                ((string-match (rx bos (group (= 40 hex)) " " (+ digit) " " (group (+ digit)))
                               text)
                 (setq line (and (not (string-match-p (rx bos (+ "0") eos) (match-string 1 text)))
                                 (string-to-number (match-string 2 text)))))
                ((and line (string-prefix-p "committer-time " text))
                 (puthash line (seconds-to-time
                                (string-to-number (substring text (length "committer-time "))))
                          times))))
             times)
         (error nil))))

(defun site--pose-entry-time (entry commit-times)
  "Return the full time of the dated Pose ENTRY.
The heading's own time wins; then the commit time of its line in
COMMIT-TIMES, when on the same day; then `denden-default-time'."
  (let ((clock (plist-get entry :clock)))
    (denden-resolve-time
     (date-to-time (if clock
                       (format "%s %02d:%02d" (plist-get entry :date) (car clock) (cadr clock))
                     (plist-get entry :date)))
     clock
     (and commit-times (gethash (plist-get entry :line) commit-times)))))

(defun site-pose-entries (site page pages)
  "Return the entries of the Pose PAGE of SITE, newest first.
PAGES are all pages.  Each entry is a top-level heading
\"* [DATE] Title\", as a plist with :id (the date, or date-2 for a
second entry that day), :title, :date, :time (see
`site--pose-entry-time'), :tags, :html, :search-text and the day
fields.  All bodies are exported in one batch, and the
result is kept in PAGE for the rest of the build."
  (site--remember
   page :site-pose-entries
   (lambda ()
     (let* ((entries (with-temp-buffer
                       (insert (denden-page-text page))
                       (delay-mode-hooks (org-mode))
                       (org-element-map (org-element-parse-buffer) 'headline
                         #'site--pose-entry nil nil 'headline)))
            (html (denden-export-org-strings
                   site (mapcar (lambda (entry) (plist-get entry :body-text)) entries) pages page))
            (commit-times (site--line-commit-times (denden-page-source page)))
            (seen (make-hash-table :test #'equal)))
       ;; Newest first; entries of one day keep their file order.
       (sort (cl-mapcar
              (lambda (entry body)
                (let* ((date (plist-get entry :date))
                       (count (cl-incf (gethash date seen 0))))
                  (append entry
                          ;; The date is the anchor, so links shared before still work.
                          (list :id (or (plist-get entry :custom-id)
                                        (if (or (null date) (> count 1))
                                            (format "%s-%d" (or date "entry") count)
                                          date))
                                :time (and date (site--pose-entry-time entry commit-times))
                                :html body
                                :search-text (downcase (concat (plist-get entry :title) " "
                                                               (denden-html-plain-text body)))))))
              entries html)
             :key (lambda (entry) (or (plist-get entry :date) "")) :reverse t)))))

(defun site--pose-week-label (calendar-date)
  "Return the label of the ISO week of CALENDAR-DATE.
For example, \"Week 48 · 23 to 29 Nov 2026\"."
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
  "Return ENTRIES, newest first, grouped into ISO weeks.
Each week is a plist with :id, :label and :entries."
  (let ((weeks nil))
    (dolist (entry entries)
      (let* ((calendar-date (plist-get entry :calendar-date))
             (iso (and calendar-date
                       (calendar-iso-from-absolute (calendar-absolute-from-gregorian calendar-date))))
             ;; ISO (WEEK DAY YEAR); the ISO year can differ from the calendar year near New Year.
             (id (if iso (format "%d-W%02d" (nth 2 iso) (nth 0 iso)) "undated")))
        (if (equal id (plist-get (car weeks) :id))
            (push entry (plist-get (car weeks) :entries))
          (push (list :id id :label (if iso (site--pose-week-label calendar-date) "Undated")
                      :entries (list entry))
                weeks))))
    (nreverse (mapcar (lambda (week) (plist-put week :entries (nreverse (plist-get week :entries))))
                      weeks))))

(defun site--pose-feed-pages (site pages)
  "Return the dated Pose entries of PAGES as page records for feeds.
Each record links to the entry's own anchor on the Pose page of SITE."
  (let ((pose-page (site-pose-page pages)))
    (and pose-page
         (mapcan (lambda (entry)
                   (let ((date (plist-get entry :date)))
                     (and date
                          (let ((time (plist-get entry :time)))
                            (list (denden-page-create
                                   :url (format "%s#%s" (denden-page-url pose-page) (plist-get entry :id))
                                   :title (plist-get entry :title)
                                   :date time :lastmod time
                                   :terms (list (cons "tags" (plist-get entry :tags)))
                                   :body (plist-get entry :html)))))))
                 (site-pose-entries site pose-page pages)))))

;;;; Data shared by every page of one build

(defvar site--build-data nil
  "Data every page of one build shares, as (PAGES . PLIST).
It is computed for the first page of a build and reused while the
page list is the same object, so a new build always recomputes it.")

(defun site--read-file (file)
  "Return the text of FILE, relative to the site's root folder."
  (with-temp-buffer
    (insert-file-contents (expand-file-name file site-root-directory))
    (buffer-string)))

(defun site--palette-data-script (site pages)
  "Return the command palette's data script for SITE and PAGES, a raw-html node."
  (let ((posts (append
                (mapcar (lambda (page)
                          (list :title (denden-page-title page)
                                :url (concat "/" (denden-page-url page))
                                :date (and (denden-page-date page)
                                           (format-time-string "%F" (denden-page-date page)))
                                :tags (vconcat (site--tags page))))
                        pages)
                ;; Pose entries too, so palette search and Random can land on a daily note.
                (mapcar (lambda (entry)
                          (list :title (denden-page-title entry)
                                :url (concat "/" (denden-page-url entry))
                                :date (format-time-string "%F" (denden-page-date entry))
                                :tags (vconcat (site--tags entry))))
                        (site--pose-feed-pages site pages))))
        (tags (mapcar (lambda (entry)
                        (list :name (car entry) :count (cdr entry)
                              :url (format "/tags/%s/" (downcase (car entry)))))
                      (denden-term-counts pages "tags"))))
    (list 'raw-html nil
          (format "<script>window.__posts=%s;window.__tags=%s;window.__nav=%s;window.__paletteIcons=%s;</script>"
                  (json-serialize (vconcat posts)) (json-serialize (vconcat tags))
                  (json-serialize (vconcat site-menu-main)) (json-serialize site-palette-icons)))))

(defun site--build-data (site pages)
  "Return the data every page of this build of SITE shares, given its PAGES.
The plist has :palette-script, :custom-css and :light-schemes."
  (unless (eq (car site--build-data) pages)
    (let ((custom-css (site--read-file site-css-source-file)))
      (setq site--build-data
            (cons pages
                  (list :palette-script (site--palette-data-script site pages)
                        :custom-css custom-css
                        :light-schemes (site-light-scheme-names
                                        site-color-schemes
                                        (site-parse-custom-css-schemes custom-css)))))))
  (cdr site--build-data))

;;;; Page shell

(defconst site-og-png-directory "static/og"
  "Folder of the rasterized OG cards, relative to the site's root.
Run `just og' by hand to make them; the build never writes them.")

(defun site--og-slug (url)
  "Return the OG card name of the page at URL: its last part, or \"home\"."
  (if (string-empty-p url) "home" (file-name-nondirectory (directory-file-name url))))

(defun site--post-p (page)
  "Return non-nil when PAGE is a Log post, a page with its own OG card."
  (equal (denden-page-section page) "log"))

(defun site--og-image-url (site page)
  "Return the full address of the OG image of PAGE in SITE, or nil.
Only a Log post has one, once `just og' has made its PNG.  Other
pages have no image, so link previews show their title, description
and the site's icon."
  (let ((slug (site--og-slug (denden-page-url page))))
    (and (site--post-p page)
         (file-exists-p (expand-file-name (concat slug ".png")
                                          (expand-file-name site-og-png-directory
                                                            site-root-directory)))
         (concat (denden-base-url site) "og/" slug ".png"))))

(defun site--feed-url (page)
  "Return the address of the feed that PAGE links in its head, or nil."
  (let ((url (denden-page-url page)))
    (cond ((string-empty-p url) "/index.xml")
          ((equal (denden-page-layout page) "pose") (concat "/" url "rss.xml"))
          ((equal (denden-page-layout page) "section-listing") (concat "/" url "index.xml"))
          ((equal (denden-page-layout page) "term") (concat "/" url "rss.xml")))))

(defun site--favicon-mime-type ()
  "Return the MIME type of the favicon, from its file extension."
  (or (cdr (assoc (downcase (or (file-name-extension site-favicon-relative-path) ""))
                  site--og-media-types))
      "application/octet-stream"))

(defun site-page-shell (site page main pages)
  "Return the whole page of PAGE of SITE around MAIN, given all PAGES."
  (let ((data (site--build-data site pages))
        (title (denden-page-title page)))
    (theme-baseof
     :language (denden-page-language site page) :body main
     :page-title (if (site--home-page-p page)
                     site-title
                   (format denden-page-title-format title site-title))
     :head-nodes (denden-seo-head-nodes site page (site--og-image-url site page))
     :palette-data-script (plist-get data :palette-script)
     :stylesheet-href "/css/bundle.css" :script-href "/js/index.js"
     :schemes-url "/js/schemes-data.json"
     :menu-items site-menu-header :footer-links site-menu-main
     :site-title site-title :title-quotes site-title-quotes
     :feed-url (site--feed-url page) :feed-title (format "%s RSS feed" title)
     :light-schemes (plist-get data :light-schemes)
     :footer-content site-footer-content
     :favicon-href (concat "/" site-favicon-relative-path)
     :favicon-type (site--favicon-mime-type)
     :touch-icon-href "/images/apple-touch-icon.png"
     :preload-fonts site-preload-fonts
     :noindex (site--meta page :noindex)
     :fediverse-creator site-fediverse-creator
     :analytics-script-url site-umami-script-url
     :analytics-website-id site-umami-website-id)))

;;;; Single pages

(defun site--first-mailto (links)
  "Return the first mailto address in LINKS, `site-social-links' in shape, or \"\"."
  (or (cl-some (lambda (link) (and (string-prefix-p "mailto:" (plist-get link :url))
                                   (substring (plist-get link :url) (length "mailto:"))))
               links)
      ""))

(defun site--body-links (html)
  "Return the links in HTML to other sites and to this site, each once.
Each is a plist with :href, :text and :internal."
  (let ((seen (make-hash-table :test #'equal))
        (links nil))
    (dolist (anchor (dom-by-tag (denden--parse-html html) 'a))
      (let ((href (dom-attr anchor 'href)))
        (when (and href
                   (or (string-prefix-p "http://" href) (string-prefix-p "https://" href)
                       (string-prefix-p "/" href))
                   (not (gethash href seen)))
          (puthash href t seen)
          (push (list :href href :text (denden--dom-text anchor) :internal (string-prefix-p "/" href))
                links))))
    (nreverse links)))

(defun site--related-pages (page pages body-links backlinks)
  "Return pages of PAGES that share one of the first two tags or refs of PAGE.
They fill the link budget of 7 left after BODY-LINKS and BACKLINKS,
newest first, skipping BACKLINKS and pages the body already links."
  (let* ((budget 7)
         ;; References and backlinks both use the budget; backlinks still always show.
         (used (+ (length body-links) (length backlinks)))
         (already (mapcar (lambda (link) (string-remove-suffix "/" (plist-get link :href)))
                          (seq-filter (lambda (link) (plist-get link :internal)) body-links)))
         (tags (seq-take (site--tags page) 2))
         (refs (seq-take (site--refs page) 2)))
    (unless (or (>= used budget) (and (null tags) (null refs)))
      (seq-take
       (seq-filter (lambda (other)
                     (and (not (eq other page)) (not (memq other backlinks))
                          (not (member (string-remove-suffix "/" (concat "/" (denden-page-url other)))
                                       already))
                          (or (seq-intersection (site--tags other) tags)
                              (seq-intersection (site--refs other) refs))))
                   (denden-sort-pages-by-date pages))
       (- budget used)))))

(defun site--toc-list (headings)
  "Return a nested ul for HEADINGS, a list of (LEVEL ID TEXT), and the rest.
The result is (NODE . REST): NODE lists the headings at the level of
the first one and those below it, and REST the headings after them."
  (let ((level (car (car headings)))
        (items nil))
    (while (and headings (>= (car (car headings)) level))
      (pcase-let ((`(,_level ,id ,text) (pop headings)))
        (let ((children nil))
          (when (and headings (> (car (car headings)) level))
            (pcase-let ((`(,node . ,rest) (site--toc-list headings)))
              (setq children (list node) headings rest)))
          (push `(li nil (a (:href ,(concat "#" id)) ,text) ,@children) items))))
    (cons `(ul nil ,@(nreverse items)) headings)))

(defun site--toc-node (page)
  "Return the table of contents of PAGE, or nil unless it sets #+toc: t.
It lists the headings of the exported body, so no second export is
needed."
  (when (site--true-p (site--meta page :toc))
    (let* ((dom (denden--parse-html (or (denden-page-body page) "")))
           (headings (mapcan (lambda (node)
                               (and (memq (dom-tag node) '(h2 h3 h4 h5 h6)) (dom-attr node 'id)
                                    (progn
                                      (dolist (anchor (dom-by-class node (rx bos "heading-anchor" eos)))
                                        (dom-remove-node node anchor))
                                      (list (list (string-to-number (substring (symbol-name (dom-tag node)) 1))
                                                  (dom-attr node 'id)
                                                  (denden--dom-text node))))))
                             (dom-search dom (lambda (node) (memq (dom-tag node) '(h2 h3 h4 h5 h6)))))))
      (and headings
           `(details (:class "toc") (summary nil "Contents") ,(car (site--toc-list headings)))))))

(defun site-render-single-page (_site page pages)
  "Return the main part of PAGE, an ordinary page, given all PAGES.
_SITE is not used."
  (let* ((title (denden-page-title page))
         (body (or (denden-page-body page) ""))
         (word-count (site--word-count page))
         (body-links (site--body-links body))
         ;; The home page links to nearly everything, so it is no backlink.
         (backlinks (site--regular-pages (denden-backlinks page pages)))
         (neighbours (denden-previous-and-next page pages)))
    (theme-single-page
     :post-header (theme-post-header :title title :date (denden-page-date page)
                                     :lastmod (denden-page-lastmod page)
                                     :word-count word-count
                                     :reading-time (site--reading-time word-count)
                                     :tags (site--tags page))
     :toc (site--toc-node page)
     :body-html body
     :references (theme-references
                  :references (mapcar (lambda (link) (list :href (plist-get link :href)
                                                           :label (plist-get link :text)
                                                           :internal (plist-get link :internal)))
                                      body-links)
                  :backlinks backlinks
                  :related (site--related-pages page pages body-links backlinks)
                  :tag-icons site-tag-icons :backlink-icon site-backlink-icon)
     :comment (unless (site--true-p (site--meta page :no-comment))
                (theme-comment (site--first-mailto site-social-links) title))
     :post-navigation (theme-post-navigation :previous (car neighbours) :next (cdr neighbours)))))

;;;; Home, Pose and topic-list pages

(defun site-render-page (site page pages)
  "Return the main part of PAGE of SITE, given all PAGES.
This is the site's default layout: the home page gets
`site-render-home-page', every other page `site-render-single-page'."
  (if (site--home-page-p page)
      (site-render-home-page site page pages)
    (site-render-single-page site page pages)))

(defun site-render-home-page (_site page pages)
  "Return the main part of the home PAGE: its title and body.
A home page with no body lists the Log from PAGES instead."
  (let ((body (or (denden-page-body page) "")))
    (if (string-empty-p (denden-html-plain-text body))
        (theme-post-listing
         :title "Log"
         :article-list (theme-article-list
                        :grouped-pages (denden-group-pages-by-year (denden-pages-in-section pages "log"))
                        :tag-icons site-tag-icons))
      (theme-home-page :title (denden-page-title page) :body-html body))))

(defun site-render-pose-page (site page pages)
  "Return the main part of the Pose PAGE of SITE, given all PAGES."
  (theme-pose-page :title (denden-page-title page)
                   :intro-html (site--intro-html page)
                   :weeks (site--pose-weeks (site-pose-entries site page pages))))

(defun site-render-topic-list-page (site page pages)
  "Return the main part of the topic-list PAGE of SITE, given all PAGES."
  (theme-topic-list-page
   :title (denden-page-title page)
   :date (denden-page-date page)
   :intro-html (site--intro-html page)
   :show-console (site--true-p (site--meta page :show-console))
   :items-node (theme-topic-list-items :groups (site-topic-groups site page pages)
                                       :tag-icons site-tag-icons
                                       :chip-color (site--meta page :chip-color)
                                       :pages pages)))

(defun site--page-as-topic-item (page)
  "Return PAGE as a topic-list item, with its tags and refs as chips."
  (list :url (concat "/" (denden-page-url page))
        :name (denden-page-title page)
        :description ""
        :parts (append (mapcar (lambda (tag) (list :key "tag" :value tag)) (site--tags page))
                       (mapcar (lambda (ref) (list :key "refs" :value ref)) (site--refs page)))))

(defun site--sitemap-groups (page pages)
  "Return PAGES grouped for the sitemap PAGE, pages without a section first.
Each group is a plist with :label and :items."
  (let ((sectionless (denden-sort-pages-by-title
                      (remove page (site--regular-pages (denden-pages-in-section pages ""))))))
    (append
     (and sectionless (list (list :label "Pages" :pages sectionless)))
     (mapcar (lambda (section)
               (list :label (capitalize section)
                     :pages (denden-sort-pages-by-title (denden-pages-in-section pages section))))
             (sort (denden-sections pages))))))

(defun site-render-sitemap-page (_site page pages)
  "Return the main part of the sitemap PAGE: every page of PAGES by section."
  (theme-topic-list-page
   :title (denden-page-title page)
   :intro-html (denden-page-body page)
   :items-node (theme-topic-list-items
                :groups (mapcar (lambda (group)
                                  (list :label (plist-get group :label)
                                        :items (mapcar #'site--page-as-topic-item
                                                       (plist-get group :pages))))
                                (site--sitemap-groups page pages))
                :tag-icons site-tag-icons :pages pages :external nil)))

(defun site--link-domain-icon (url)
  "Return the glyph of URL from `site-tag-icons', by its host or a part of it."
  (let ((host (string-remove-prefix "www." (or (url-host (url-generic-parse-url url)) ""))))
    (or (cl-some (lambda (text) (theme-icon-for text site-tag-icons))
                 (cons host (split-string host (rx "."))))
        (cdr (assoc "_default" site-tag-icons)))))

(defconst site-recent-link-count 15
  "How many of the most recently cited links the links page shows first.")

(defun site--link-dates-from-log (lines)
  "Return a hash table from each URL added in LINES to the date it was first added.
LINES is the output of git log -p with a \"commit:DATE\" line before
each commit, newest commit first, so the last date seen for a URL is
the oldest.  Trailing punctuation is not part of a URL, as in Org."
  (let ((dates (make-hash-table :test #'equal))
        (date nil))
    (dolist (line lines)
      (cond
       ((string-prefix-p "commit:" line)
        (setq date (substring line (length "commit:"))))
       ((and date (string-prefix-p "+" line) (not (string-prefix-p "+++" line)))
        (let ((start 0))
          (while (string-match (rx "http" (opt "s") "://" (+ (not (in " \t\"'<>[]{}|\\^`"))))
                               line start)
            (setq start (match-end 0))
            (puthash (string-trim-right (match-string 0 line) (rx (+ (in ".,;:!?)"))))
                     date dates))))))
    dates))

(defun site--link-dates (site)
  "Return when each link in the content of SITE was first added, from git.
The result is a hash table from URL to a \"YYYY-MM-DD\" date, or nil
when the site is not in git or `denden-lastmod-from-git' is nil."
  (and denden-lastmod-from-git
       (condition-case nil
           (let ((default-directory (denden-site-root-directory site)))
             (site--link-dates-from-log
              (process-lines "git" "log" "--format=commit:%cs" "-p" "-U0" "--no-color"
                             "--" (denden-site-content-directory site))))
         (error nil))))

(defun site--links-groups (site pages)
  "Return every link of PAGES to another site, grouped by domain, busiest first.
Sites cited only once share a last \"Other sites\" group.  Links to
SITE itself are left out; the sitemap lists those."
  (let ((by-url (make-hash-table :test #'equal))
        (own-host (url-host (url-generic-parse-url (denden-base-url site))))
        (urls nil))
    (dolist (page (site--regular-pages pages))
      (pcase-dolist (`(,url . ,text) (denden-page-external-links page))
        (unless (equal (url-host (url-generic-parse-url url)) own-host)
          (let ((entry (or (gethash url by-url)
                           (progn (push url urls) (list :text nil :pages nil)))))
            (unless (plist-get entry :text) (setq entry (plist-put entry :text text)))
            (puthash url (plist-put entry :pages (cons page (plist-get entry :pages))) by-url)))))
    (let* ((domains (seq-group-by (lambda (url)
                                    (string-remove-prefix "www." (or (url-host (url-generic-parse-url url)) "")))
                                  (nreverse urls)))
           (item (lambda (url)
                   (let* ((entry (gethash url by-url))
                          (label (denden-link-label site url))
                          (cited (mapconcat (lambda (page)
                                              (format "<a href=\"/%s\">%s</a>" (denden-page-url page)
                                                      (org-html-encode-plain-text (denden-page-title page))))
                                            (denden-sort-pages-by-date (delete-dups (plist-get entry :pages)))
                                            ", ")))
                     (list :url url :name (or (plist-get entry :text) label) :parts nil
                           :icon (site--link-domain-icon url)
                           :description (concat (if (plist-get entry :text)
                                                    (concat (org-html-encode-plain-text label) " · ")
                                                  "")
                                                "in " cited)))))
           (items (lambda (urls) (sort (mapcar item urls) :key (lambda (item) (downcase (plist-get item :name))))))
           ;; A site cited once gets no heading of its own; those all share one last section.
           (shared (seq-filter (lambda (domain) (null (cddr domain))) domains))
           (own (seq-remove (lambda (domain) (null (cddr domain))) domains)))
      (append
       (site--recent-links-group site (hash-table-keys by-url) item)
       (mapcar (lambda (domain) (list :label (car domain) :items (funcall items (cdr domain))))
               (sort own :key (lambda (domain) (list (- (length (cdr domain))) (car domain)))))
       (and shared (list (list :label "Other sites" :items (funcall items (mapcar #'cadr shared)))))))))

(defun site--recent-links-group (site urls item)
  "Return a list of one group of the newest of URLS, or nil.
The newest are those first added to the content of SITE most
recently, by git history; a link not in git yet counts as newest.
ITEM makes the topic-list item of a URL."
  (let ((dates (site--link-dates site)))
    (and dates urls
         (let ((today (format-time-string "%F")))
           (list (list :label "Recently cited"
                       :items (mapcar item
                                      (seq-take (sort urls
                                                      :key (lambda (url)
                                                             (list (gethash url dates today) url))
                                                      :reverse t)
                                                site-recent-link-count))))))))

(defun site-render-links-page (site page pages)
  "Return the main part of the links PAGE of SITE: every link to another site."
  (theme-topic-list-page
   :title (denden-page-title page)
   :intro-html (denden-page-body page)
   :items-node (theme-topic-list-items :groups (site--links-groups site pages) :pages pages
                                       :collapsed t)))

;;;; Pages with no Org file: section lists, tags, refs, 404

(defun site--listing-page (url title layout &rest meta)
  "Return a page record for a generated page at URL with TITLE and LAYOUT.
META is its meta plist, read by the layout."
  (denden-page-create :url url :title title :layout layout :meta meta))

(defun site-render-section-listing (_site page pages)
  "Return the main part of the section list PAGE: its section's pages by year."
  (theme-post-listing
   :title (denden-page-title page)
   :article-list (theme-article-list
                  :grouped-pages (denden-group-pages-by-year
                                  (denden-pages-in-section pages (site--meta page :section)))
                  :tag-icons site-tag-icons)))

(defun site-render-terms (_site page pages)
  "Return the main part of the PAGE that lists every term of a taxonomy of PAGES."
  (let ((taxonomy (site--meta page :taxonomy)))
    (theme-terms-list :title (denden-page-title page)
                      :term-counts (denden-term-counts pages taxonomy)
                      :base-url (format "/%s/" taxonomy))))

(defun site-render-term (_site page pages)
  "Return the main part of the PAGE that lists the pages of PAGES with one term."
  (let* ((taxonomy (site--meta page :taxonomy))
         (term-pages (denden-pages-with-term pages taxonomy (site--meta page :term))))
    (theme-post-listing
     :title (concat "#" (site--meta page :term))
     :term-header (theme-term-header :count (length term-pages)
                                     :feed-url (concat "/" (denden-page-url page) "rss.xml")
                                     :back-url (format "/%s/" taxonomy))
     :article-list (theme-article-list :grouped-pages (denden-group-pages-by-year term-pages)
                                       :tag-icons site-tag-icons))))

(defconst site--404-wanted-poster
  '(div (:class "wanted-poster")
        (p nil "WANTED")
        (p nil "Page D. Notfound")
        (p nil (strong nil "DEAD OR ALIVE"))
        (p nil "Bounty: 404,069,420")
        (p nil "Last seen: " (code (:id "wanted-lastseen") "parts unknown"))
        (p nil (em nil "Even " (b nil "Roronoa Zoro") " would've found his way here faster.")))
  "The WANTED poster of the 404 page.")

(defconst site--404-wanted-lastseen-script
  '(script nil "document.getElementById('wanted-lastseen').textContent = window.location.pathname;")
  "Script that fills the poster's \"Last seen\" line with the mistyped path,
since a static page cannot know it.")

(defun site-render-not-found (_site _page pages)
  "Return the main part of the 404 page, with the newest Log post of PAGES."
  (let ((latest (car (denden-sort-pages-by-date (denden-pages-in-section pages "log")))))
    `(article nil
              (header nil (h1 nil "Page not found"))
              (div nil
                   (p nil (code nil "Symbol's value as variable is void: /404.html"))
                   ,site--404-wanted-poster
                   (ul nil
                       (li nil (a (:href "/") "Home"))
                       (li nil (a (:href "/log/") "Log"))
                       ,(and latest
                             `(li nil "Latest: "
                                  (a (:href ,(concat "/" (denden-page-url latest))) ,(denden-page-title latest))
                                  ,(format " (%s)" (format-time-string "%F" (denden-page-date latest))))))
                   (p nil "Or search for everything else: "
                      (button (:type "button" :data-action "open-palette" :hidden t :data-requires-js t)
                              "Search " (kbd nil "x")))
                   ,site--404-wanted-lastseen-script))))

(defun site-listing-outputs (site pages)
  "Return the section lists, tag and ref pages and the 404 page of SITE.
They are rendered from PAGES through the site's page shell."
  (let ((render (lambda (page) (cons (denden-page-url page) (denden-render-page site page pages)))))
    (mapcar render
            (append
             (mapcar (lambda (section)
                       (site--listing-page (concat section "/") (capitalize section) "section-listing"
                                           :section section))
                     (denden-sections pages))
             (mapcan (lambda (taxonomy)
                       (let ((counts (denden-term-counts pages taxonomy)))
                         (and counts
                              (cons (site--listing-page (concat taxonomy "/") (capitalize taxonomy) "terms"
                                                        :taxonomy taxonomy)
                                    (mapcar (lambda (entry)
                                              (site--listing-page
                                               (format "%s/%s/" taxonomy (downcase (car entry)))
                                               (car entry) "term" :taxonomy taxonomy :term (car entry)))
                                            counts)))))
                     '("tags" "refs"))
             (list (site--listing-page "404.html" "Page not found" "not-found" :noindex t))))))

;;;; Feeds

(defun site--feed (site pages url &optional title)
  "Return the Atom feed of PAGES at URL of SITE, newest first, as (URL . TEXT).
TITLE is the feed title, the site title by default."
  (cons url (denden-atom-feed site (denden-sort-pages-by-date pages)
                              :title (or title site-title)
                              :self-url (concat (denden-base-url site) url)
                              :rights site-copyright)))

(defun site-feed-outputs (site pages)
  "Return every feed of SITE as (URL . TEXT), given its PAGES.
The main feed carries Log posts and Pose entries; /log/ and /pose/
keep their own, and each tag and ref has an rss.xml.  The main and
Log feeds are written three times, as index.xml, rss.xml and
feed.xml, so readers find them under any usual name."
  (let* ((log (denden-pages-in-section (site--regular-pages pages) "log"))
         (pose (site--pose-feed-pages site pages))
         (pose-page (site-pose-page pages))
         (names '("index.xml" "rss.xml" "feed.xml")))
    (append
     (mapcar (lambda (name) (site--feed site (append log pose) name)) names)
     (mapcar (lambda (name) (site--feed site log (concat "log/" name))) names)
     (and pose-page
          (list (site--feed site pose (concat (denden-page-url pose-page) "rss.xml")
                            (format "%s: Pose" site-title))))
     (mapcan (lambda (taxonomy)
               (mapcar (lambda (entry)
                         (site--feed site (denden-pages-with-term pages taxonomy (car entry))
                                     (format "%s/%s/rss.xml" taxonomy (downcase (car entry)))
                                     (format "%s: %s" site-title (car entry))))
                       (denden-term-counts (site--regular-pages pages) taxonomy)))
             '("tags" "refs")))))

;;;; Other outputs

(defconst site-legacy-redirects
  '(("posts/" . "log/") ("themes/" . ""))
  "Old URL to current URL, for pages that moved or were retired.")

(defun site-legacy-redirect-outputs (site pages)
  "Return a redirect page of SITE for each of `site-legacy-redirects'.
The target page comes from PAGES, or is the generated list of its section."
  (mapcar (lambda (redirect)
            (let ((target (or (seq-find (lambda (page) (equal (denden-page-url page) (cdr redirect))) pages)
                              (site--listing-page (cdr redirect)
                                                  (capitalize (string-remove-suffix "/" (cdr redirect)))
                                                  "section-listing"))))
              (cons (car redirect) (denden-redirect-html site target))))
          site-legacy-redirects))

(defun site-search-index-output (site pages)
  "Return the search index of SITE over every page of PAGES but the home page."
  (denden-search-index-output site (site--regular-pages pages)))

(defconst site--wander-colors-script
  ";(function(){try{var c=JSON.parse(localStorage.getItem('emacs-wander-colors'));if(c)Object.keys(c).forEach(function(k){document.documentElement.style.setProperty(k,c[k]);});}catch(e){}})();\n"
  "Added to wander.js: paints the console in the colours the site saved.")

(defun site-wander-outputs (site pages)
  "Return wander.js and wander-theme.css of the Wander console of SITE.
wander.js lists the links of the wander page in PAGES: groups whose
label names a console are consoles, the rest are pages."
  (let ((wander (seq-find (lambda (page) (equal (denden-page-url page) "wander/")) pages))
        (consoles nil)
        (links nil))
    (when wander
      (dolist (group (site-topic-groups site wander pages))
        (let ((console (string-search "console" (downcase (plist-get group :label)))))
          (dolist (item (plist-get group :items))
            (if console (push (plist-get item :url) consoles) (push (plist-get item :url) links))))))
    (let ((array (lambda (urls) (mapconcat (lambda (url) (format "  %s,\n" (json-serialize url)))
                                           (nreverse urls) ""))))
      (list (cons "wander/console/wander.js"
                  (concat (format "const wander = { consoles:\n[%s],\npages:\n[%s],\nstyles: [\"wander-theme.css\"], ignore: [], }\n"
                                  (funcall array consoles) (funcall array links))
                          site--wander-colors-script))
            (cons "wander/console/wander-theme.css" (site--read-file "assets/css/wander-theme.css"))))))

(defun site-asset-outputs (site pages)
  "Return the style sheet bundle, the script and the scheme data of SITE.
The bundle is the hand-edited style sheet, then the colour scheme
variables, then the code colours.  PAGES identify the build."
  (let ((custom-css (plist-get (site--build-data site pages) :custom-css)))
    (list (cons "css/bundle.css"
                (concat custom-css
                        "\n/* ---- generated: base16 scheme variables (site-scheme-css) ---- */\n"
                        (site-scheme-css site-color-schemes)
                        "\n/* ---- generated: code-highlight colors (site-highlight-stylesheet) ---- */\n"
                        (site-highlight-stylesheet)))
          (cons "js/index.js" (site--read-file site-js-source-file))
          (cons "js/schemes-data.json" (site-schemes-json custom-css)))))

(defun site-og-card-outputs (site pages)
  "Return the OG card SVG of each Log post of SITE, from PAGES.
`just og' turns them into PNG files."
  (let ((favicon (expand-file-name (concat "static/" site-favicon-relative-path)
                                   site-root-directory)))
    (mapcar (lambda (page)
              (let ((word-count (site--word-count page)))
                (cons (concat (denden-page-url page) "og.svg")
                      (site-og-card-svg
                       :title (denden-page-title page) :base-url (denden-base-url site)
                       :excerpt (denden-page-excerpt page)
                       :tags (site--tags page)
                       :slug (denden-page-url page)
                       :date (and (denden-page-date page)
                                  (format-time-string "%F" (denden-page-date page)))
                       :meta-right (format "%d words · %d min"
                                           word-count (site--reading-time word-count))
                       :card-site-title site-title :favicon-path favicon))))
            (seq-filter #'site--post-p pages))))

;;;; The site

(setq denden-figure-numbers nil
      ;; A date without a time is published at 22:00, unless git knows better.
      denden-default-time "22:00")

(denden-define-site idlip-site
  "idlip.in, Dilip's Log."
  :title site-title
  :description site-description
  :author site-author-name
  :base-url "https://idlip.in/"
  :root-directory site-root-directory
  :publishing-directory "public-denden"
  :taxonomies '("tags" "refs")
  :evaluate-code t
  :default-layout #'site-render-page
  :page-shell #'site-page-shell
  :layouts '(("pose" . site-render-pose-page)
             ("topic-list" . site-render-topic-list-page)
             ("sitemap" . site-render-sitemap-page)
             ("links" . site-render-links-page)
             ("section-listing" . site-render-section-listing)
             ("terms" . site-render-terms)
             ("term" . site-render-term)
             ("not-found" . site-render-not-found))
  :outputs (list #'site-listing-outputs #'site-feed-outputs
                 #'denden-sitemap-output #'denden-robots-output
                 #'denden-redirect-outputs #'site-legacy-redirect-outputs
                 #'site-search-index-output #'site-wander-outputs
                 #'site-asset-outputs #'site-og-card-outputs)
  :link-label-rules
  (list (cons (rx bos "github.com/" (group (+ anything))) "github:\\1")
        (cons (rx bos "codeberg.org/" (group (+ anything))) "codeberg:\\1")
        ;; Only a bare subreddit or user; a post link keeps its full path.
        (cons (rx bos (opt "old.") "reddit.com/" (group (in "ru") "/" (+ (not (in "/")))) eos) "\\1")))

(provide 'site)
;;; site.el ends here
