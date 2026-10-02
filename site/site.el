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
(require 'denden)
(require 'theme)
(require 'site-schemes-base16)

;;;; Config data: menu, color schemes, social links, palette icons, badges

(defconst site-menu-main
  '((:name "Home" :url "/")
    (:name "Blog Posts" :url "/log/")
    (:name "Projects & Tools" :url "/repo/")
    (:name "About" :url "/about/")
    (:name "Now Now Now" :url "/now/")
    (:name " Feeds" :url "/index.xml")
    (:name "Wander My Small Web" :url "/wander/")
    (:name "Media" :url "/media/")
    (:name "Quotes" :url "/quotes/")
    (:name "Color Themes" :url "/themes/"))
  "In :weight order, not declaration order.")

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
  '(:nav "󰘍 " :command " " :post " " :tag " " :scheme " " :help "󰘥 "))

(defconst site-title "Dilip's Log")

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

(defconst site-favicon-relative-path "images/op-zoro.webp"
  "Relative to static/.")

(defconst site-tag-icons
  '(("snippets" . " ") ("nixos" . " ") ("nix" . " ") ("emacs" . " ") ("gnus" . " ")
    ("orgmode" . " ") ("novel" . " ") ("onepiece" . "󰨈 ") ("anime" . "󰨈 ") ("manga" . "󰨈 ")
    ("linux" . " ") ("foss" . " ") ("rss" . " ") ("games" . " ") ("terminal" . " ")
    ("cli" . " ") ("vim" . " ") ("android" . "") ("fossdroid" . "") ("quotes" . "󱀡 ")
    ("bioinformatics" . "󰚄 ") ("python" . " ") ("r" . "󰟔") ("finance" . " ")
    ("principle" . " ") ("webdev" . " ") ("lisp" . "󱃺 ") ("git" . " ") ("_default" . " "))
  "Flat tag -> Nerd Font glyph map, for the article-list type icon.")

(defconst site-badges
  (list (list :name "Emacs" :logo "/images/logos/emacs.png" :color "#5b2a85"
              :link "https://www.gnu.org/software/emacs/" :subtitle "Living in")
        (list :name "Org mode" :logo "/images/logos/orgmode.png" :color "#3f6b5e"
              :link "https://orgmode.org/" :subtitle "Swimming in")
        (list :name "Santōryū" :logo "/images/logos/zoro-chibi.webp" :color "#32ae55"
              :link "/wander/" :subtitle "Wander my web" :tooltip "Find your way over the network")
        (list :name "OnePiece" :logo "/images/logos/onepiece.webp" :color "#D49A00"
              :subtitle "Finding" :link "https://one-piece.com/")
        (list :name "FOSS" :logo "/images/logos/foss.webp" :color "#8AA9BC"
              :link "https://en.wikipedia.org/wiki/Free_and_open-source_software" :subtitle "Liberated by")))

(defconst site-footer-content
  (list
   'div nil
   (list 'p '(:class "webring" :align "center" :style "font-size:0.9em;")
         '(a (:href "https://blr.indiewebclub.org/webring/idlip-in/previous.html") "=")
         " "
         '(a (:href "https://blr.indiewebclub.org/") "IndieWebClub BLR")
         " "
         '(a (:href "https://blr.indiewebclub.org/webring/idlip-in/next.html") "="))
   (list 'p '(:class "webring" :align "center" :style "font-size:0.9em;")
         '(a (:href "https://craftering.systemcrafters.net/@idlip/previous") "")
         " "
         '(a (:href "https://craftering.systemcrafters.net/") " Craftering ")
         " "
         '(a (:href "https://craftering.systemcrafters.net/@idlip/next") ""))
   (list 'p '(:align "center" :style "font-size:0.75em;")
         (list 'span '(:style "white-space: nowrap;")
               "- - - - - - -  - - - - - - -  - - - - - - -  - - - - - - -")
         '(br nil)
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

(defun site-scheme-css (color-schemes)
  "Return CSS for COLOR-SCHEMES: a [data-scheme=NAME] block per entry's :dark and :light base16 keys."
  (mapconcat
   (lambda (scheme)
     (let ((name (plist-get scheme :name)))
       (mapconcat
        (lambda (variant-key-and-selector)
          (let ((yaml-key (car variant-key-and-selector))
                (selector (cdr variant-key-and-selector)))
            (if (null yaml-key) ""
              (let ((entry (site--base16-entry yaml-key)))
                (if (null entry) ""
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

(defun site-scheme-swatch-style (scheme)
  "Return the inline --p-bg/--p-fg/--p-accent swatch style for SCHEME, from
its base16 palette or explicit colors."
  (let* ((dark-key (plist-get scheme :dark))
         (entry (and dark-key (site--base16-entry dark-key)))
         (palette (and entry (plist-get entry :palette)))
         (bg (if palette (site-scheme-palette-value palette "base00") (plist-get scheme :bg)))
         (fg (if palette (site-scheme-palette-value palette "base05") (plist-get scheme :fg)))
         (accent (if palette (site-scheme-palette-value palette "base0D") (plist-get scheme :accent))))
    (format "--p-bg:%s;--p-fg:%s;--p-accent:%s" bg fg accent)))

(defun site-parse-author (author)
  "Parse \"Name (URL)\" or plain \"Name\" AUTHOR into (:name :url); :url is
\"\" if there is none."
  (if (string-match "\\`\\([^(]+\\)(\\([^)]*\\))" author)
      (list :name (string-trim (match-string 1 author)) :url (match-string 2 author))
    (list :name (string-trim author) :url "")))

(defun site-parse-custom-css-schemes (css-text)
  "Parse CSS-TEXT's \"/* @scheme: Name | Author | Variant */\" comments into
base16-shaped entries."
  (when (and css-text (not (string-empty-p css-text)))
    (let ((unit-re (concat "/\\* @scheme:\\([^*]*\\)\\*/[ \t\n]*"
                            "\\[data-scheme=\"\\([a-zA-Z0-9_-]+\\)\"\\]"
                            "\\(\\[data-theme=\"light\"\\]\\)?[ \t\n]*"
                            "{\\([^}]*\\)}"))
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
          (while (string-match "--base0[0-9A-F]:[ \t]*\\(#[0-9a-fA-F]\\{6\\}\\)" body hex-start)
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

(defun site-schemes-json (&optional custom-css-text)
  "Return the key/name/colors JSON for the command-palette picker, from
`site-all-schemes'."
  (json-serialize
   (vconcat (mapcar (lambda (s) (list :key (plist-get s :key) :name (plist-get s :name)
                                       :colors (vconcat (plist-get s :colors))))
                     (site-all-schemes custom-css-text)))))

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
  (or (and (string-match (format "^%s:[ \t]*\"\\([^\"]*\\)\"" (regexp-quote key)) text)
           (match-string 1 text))
      (and (string-match (format "^%s:[ \t]*\\(.+?\\)[ \t]*$" (regexp-quote key)) text)
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
                           (sort (directory-files source-directory t "\\.yaml\\'") #'string<))))
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
;; lines'; colors and geometry here are this site's own, an
;; Emacs-window-styled 1200x630 card.

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
  "Return TITLE wrapped to at most 2 lines, plus a font size sized by TITLE's
length."
  (let* ((font-size (cond ((> (length title) 52) 38) ((> (length title) 28) 44) (t 50)))
         (wrap-width (cond ((> (length title) 52) 40) ((> (length title) 28) 34) (t 30))))
    (list :font-size font-size
          :lines (denden-og-truncate-lines (denden-og-wrap-words title wrap-width) 2))))

(defun site--og-excerpt-lines (excerpt)
  "Return EXCERPT's lines, word-wrapped to 62 characters per paragraph and
capped to 5 lines. A blank line in EXCERPT (a paragraph break) becomes a
blank output line, so the break still shows as a gap on the card."
  (when excerpt
    (denden-og-truncate-lines
     (seq-mapcat (lambda (source-line)
                   (if (string-empty-p source-line)
                       (list "")
                     (denden-og-wrap-words (replace-regexp-in-string "[ \t]+" " " (string-trim source-line)) 62)))
                 (split-string (string-trim excerpt) "\n"))
     5)))

(cl-defun site-og-card-svg (&key title excerpt tags slug date meta-right card-site-title favicon-path
                                  (font "Code D OnePiece"))
  "Return this site's OG card as a full <svg> string, built through
`denden-serialize-node'."
  (let* ((title-info (site--og-title-lines title))
         (title-lines (plist-get title-info :lines))
         (title-font-size (plist-get title-info :font-size))
         (tags-string (mapconcat (lambda (tag) (format "#%s" tag)) (seq-take tags 3) "  "))
         (excerpt-lines (site--og-excerpt-lines excerpt))
         (favicon-data-uri (site--og-favicon-data-uri favicon-path))
         (title-top 180)
         (title-last (+ title-top (* (1- (length title-lines)) (+ title-font-size 12))))
         (tags-y (+ title-last 50))
         (excerpt-top (if (> (length tags-string) 0) (+ tags-y 52) (+ title-last 56)))
         (date-x 36) (slug-x (if date (+ date-x 226) date-x))
         (tree
          (list 'svg (list :xmlns "http://www.w3.org/2000/svg" :viewBox "0 0 1200 630"
                            :width "1200" :height "630" :font-family (format "%s, monospace" font))
                (list 'defs nil
                      (list 'clipPath '(:id "favclip")
                            (list 'rect '(:x "1074" :y "436" :width "80" :height "80" :rx "14"))))
                (list 'rect '(:width "1200" :height "630" :fill "#000000"))
                (list 'rect '(:width "1200" :height "68" :fill "#0a0f0a"))
                (list 'rect '(:y "68" :width "1200" :height "2" :fill "#111c17"))
                (list 'text '(:x "36" :y "46" :fill "#b4aeae" :font-size "34")
                      (list 'raw-html nil "&#x2261;"))
                (list 'rect '(:x "80" :y "19" :width "2" :height "30" :fill "#248f6c" :opacity "0.6"))
                (list 'text '(:x "100" :y "46" :fill "#5fd7af" :font-size "30" :font-weight "bold")
                      card-site-title)
                (list 'text '(:x "1164" :y "46" :fill "#5fd7af" :font-size "22" :text-anchor "end"
                                   :opacity "0.85")
                      (list 'raw-html nil "&#xf0a08; Will of D. &#xf0833;"))
                (append
                 (list 'g nil)
                 (seq-map-indexed
                  (lambda (line index)
                    (list 'text (list :x "80" :y (number-to-string (+ title-top (* index (+ title-font-size 12))))
                                       :fill "#ab82ff" :font-weight "bold" :font-size (number-to-string title-font-size))
                          (if (= index 0) (list 'raw-html nil "<tspan fill=\"#5fd7af\">&#x25C9;</tspan> ") "")
                          line))
                  title-lines))
                (if (> (length tags-string) 0)
                    (list 'text (list :x "82" :y (number-to-string tags-y) :fill "#5fd7af"
                                       :font-size "19" :opacity "0.85")
                          tags-string)
                  '(g nil))
                (append
                 (list 'g nil)
                 (seq-map-indexed
                  (lambda (line index)
                    (list 'text (list :x "80" :y (number-to-string (+ excerpt-top (* index 40)))
                                       :fill "#9aa0a6" :font-size "24")
                          line))
                  excerpt-lines))
                (if favicon-data-uri
                    (list 'image (list :href favicon-data-uri :x "1074" :y "436" :width "80" :height "80"
                                        :preserveAspectRatio "xMidYMid slice" :clip-path "url(#favclip)"
                                        :opacity "0.95"))
                  '(g nil))
                (list 'rect '(:y "562" :width "1200" :height "68" :fill "#0a0f0a"))
                (list 'rect '(:y "562" :width "1200" :height "2" :fill "#248f6c"))
                (if date
                    (list 'g nil
                          (list 'text (list :x (number-to-string date-x) :y "606" :fill "#888888" :font-size "30")
                                date)
                          (list 'text (list :x (number-to-string (+ date-x 200)) :y "606" :fill "#3a3a3a"
                                             :font-size "30")
                                (list 'raw-html nil "&#xB7;")))
                  '(g nil))
                (if slug
                    (list 'text (list :x (number-to-string slug-x) :y "606" :fill "#5fd7af" :font-size "30"
                                       :font-weight "bold")
                          (format "*%s*" slug))
                  '(g nil))
                (if (and meta-right (> (length meta-right) 0))
                    (list 'text '(:x "1164" :y "606" :fill "#888888" :font-size "30" :text-anchor "end")
                          meta-right)
                  '(g nil)))))
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
  (let ((posts (mapcar (lambda (p) (list :title (plist-get p :title)
                                          :url (concat "/" (plist-get p :url))
                                          :date (plist-get p :date)
                                          :tags (vconcat (plist-get p :tags))))
                       all-pages))
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
                :menu-items site-menu-main :color-schemes site-color-schemes
                :social-links site-social-links :site-title site-title :rss-url rss-url
                :swatch-style-fn #'site-scheme-swatch-style
                :description (or description site-description)
                :canonical-url (and url (concat (string-remove-suffix "/" (site-base-url)) "/" url))
                :favicon-href (concat "/" site-favicon-relative-path)
                :favicon-type (site--favicon-mime-type)
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

(defun site--related-pages (this-page all-pages body-links)
  "Return pages from ALL-PAGES sharing THIS-PAGE's first two tags or refs, up
to the remaining link budget."
  (let* ((budget 7)
         (n (length body-links))
         (already (mapcar (lambda (l) (string-remove-suffix "/" (plist-get l :href)))
                          (seq-filter (lambda (l) (plist-get l :internal)) body-links)))
         (remaining (max 0 (- budget n)))
         (tags (seq-take (plist-get this-page :tags) 2))
         (refs (seq-take (plist-get this-page :refs) 2)))
    (if (or (>= n budget) (and (null tags) (null refs)))
        nil
      (seq-take
       (seq-filter (lambda (p) (and (not (eq p this-page))
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
           (toc-div (car (dom-by-id dom "\\`table-of-contents\\'")))
           (toc-list (car (dom-by-id dom "\\`text-table-of-contents\\'"))))
      (when toc-div
        (dom-set-attribute toc-div 'class "table-of-contents")
        (when toc-list (setcar toc-list 'nav))
        toc-div))))

(cl-defun site--assemble-and-write-single-page (&key output pub-dir body-html all-pages lastmod-source
                                                       unique-id-seed toc modeline-buffer-name)
  "Assemble and write a themed single-post page at OUTPUT from BODY-HTML."
  (let* ((this-page (seq-find (lambda (p) (equal (plist-get p :url)
                                                  (denden-pretty-url (file-relative-name output pub-dir))))
                               all-pages))
         (title (or (and this-page (plist-get this-page :title)) (file-name-base output)))
         (tags (and this-page (plist-get this-page :tags)))
         (date (and this-page (plist-get this-page :date)))
         (section (and this-page (plist-get this-page :section)))
         (lastmod (denden-git-lastmod lastmod-source))
         (word-count (site--word-count body-html))
         (reading-time (site--reading-time word-count))
         (ancestors (when (and section (not (string-empty-p section)))
                      (list (list :title (capitalize section) :url (format "/%s/" section)))))
         (body-links (denden-collect-body-links body-html))
         (related (and this-page (site--related-pages this-page all-pages body-links)))
         (prev-next (and this-page (site--prev-next-in-section this-page all-pages)))
         (unique-id (secure-hash 'md5 unique-id-seed)))
    (site--write-page
     (site--wrap-page
      :title title
      :url (and this-page (plist-get this-page :url))
      :description (site--meta-description-for-page (list :content-html body-html))
      :og-type "article" :published-time date
      :modified-time (and lastmod (not (equal lastmod date)) lastmod)
      :tags tags
      :body (theme-single-page
             :breadcrumbs (theme-breadcrumbs :ancestors ancestors :title title)
             :post-header (theme-post-header :title title :date date :lastmod lastmod
                                              :wordcount word-count :readingtime reading-time :tags tags)
             :toc toc
             :body-html body-html
             :references (theme-references
                          :refs (mapcar (lambda (l) (list :href (plist-get l :href)
                                                           :label (plist-get l :text)
                                                           :internal (plist-get l :internal)))
                                        body-links)
                          :related related)
             :comment (theme-comment (site--first-mailto site-social-links) title unique-id)
             :post-navigation (theme-post-navigation :prev (plist-get prev-next :prev)
                                                       :next (plist-get prev-next :next))
             :footer (theme-footer site-footer-content)
             :modeline (theme-modeline :buffer modeline-buffer-name :title title
                                       :wordcount word-count :readingtime reading-time :date date
                                       :progress (or (> reading-time 3) (> word-count 500)))))
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
     :lastmod-source filename :unique-id-seed filename
     :toc (site--toc-node filename all-pages)
     :modeline-buffer-name (file-name-nondirectory filename))))

(defun site--pose-entry-teaser (html)
  "Return HTML up to its first <hr>, or all of HTML if it has none. An
entry can put a horizontal rule (five or more dashes on their own line)
after its opening thought, so extra context/examples after that point
show only in the entry's own dialog, not on the compact card."
  (let ((cut (string-match "<hr" html)))
    (if cut (substring html 0 cut) html)))

(defun site--pose-entries (filename all-pages)
  "Return every level-2 heading in FILENAME, a #+layout: pose file, as a
(:id :title :html :teaser-html) plist, each its own subtree export."
  (with-temp-buffer
    (insert-file-contents filename)
    (org-mode)
    (let (entries)
      (org-map-entries
       (lambda ()
         (when (= (org-current-level) 2)
           (let* ((id (denden-heading-id (org-element-at-point)))
                  (html (org-export-as 'denden-html t nil t (denden-export-options-with-pages all-pages filename))))
             (push (list :id id
                         :title (org-get-heading t t t t)
                         :html html
                         :teaser-html (site--pose-entry-teaser html))
                   entries))))
       nil nil)
      (nreverse entries))))

(defun site--pose-intro-html (filename all-pages)
  "Return FILENAME's content before its first heading, exported to HTML, or
\"\" if there is none."
  (with-temp-buffer
    (insert-file-contents filename)
    (org-mode)
    (goto-char (point-min))
    (when (re-search-forward "^\\*" nil t)
      (narrow-to-region (point-min) (match-beginning 0)))
    (org-export-as 'denden-html nil nil t (denden-export-options-with-pages all-pages filename))))

(defun site--pose-entries-data-script (entries)
  "Return ENTRIES' full title/html, keyed by id, as one <script> tag. The
Pose page's click-to-expand dialog reads this to show an entry's full
content, past whatever its card's own teaser cuts off at."
  (let ((table (make-hash-table :test 'equal)))
    (dolist (entry entries)
      (puthash (plist-get entry :id)
                (list :title (plist-get entry :title) :html (plist-get entry :html))
                table))
    (list 'raw-html nil (format "<script>window.__poseEntries=%s;</script>" (json-serialize table)))))

(defun site-publish-pose-page (plist filename pub-dir)
  "Publish FILENAME, a #+layout: pose file, via `theme-pose-page'; one page,
each entry with its own shareable anchor and expand-to-dialog view."
  (let* ((output (denden-output-file-for filename (cons nil plist)))
         (all-pages (plist-get plist :denden-all-pages))
         (title (or (cadr (assoc "TITLE" (with-temp-buffer
                                            (insert-file-contents filename)
                                            (org-mode)
                                            (org-collect-keywords '("TITLE")))))
                    "Pose"))
         (this-page (seq-find (lambda (p) (equal (plist-get p :url)
                                                  (denden-pretty-url (file-relative-name output pub-dir))))
                               all-pages))
         (date (and this-page (plist-get this-page :date)))
         (entries (site--pose-entries filename all-pages)))
    (site--write-page
     (site--wrap-page
      :title title
      :url (and this-page (plist-get this-page :url))
      :body (theme-pose-page
             :title title
             :intro-html (site--pose-intro-html filename all-pages)
             :entries entries
             :entries-data-script (site--pose-entries-data-script entries)
             :footer (theme-footer site-footer-content)
             :modeline (theme-modeline :buffer (format "*%s*" (downcase title)) :date date)))
     output)))

(defun site--blank-html-p (html)
  "Non-nil if HTML has no real content once tags and whitespace are stripped."
  (string-empty-p
   (string-trim (replace-regexp-in-string "[ \t\n\r]+" " " (replace-regexp-in-string "<[^>]+>" " " html)))))

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
                   :tag-cloud (theme-tag-cloud :tag-counts (denden-tag-counts all-pages))
                   :article-list (theme-article-list :grouped-pages (denden-group-pages-by-year home-pages)
                                                      :tag-icons site-tag-icons)
                   :footer (theme-footer site-footer-content)
                   :modeline (theme-modeline :buffer "*log*")))
              (theme-home-page :title title :body-html body-html
                                :footer (theme-footer site-footer-content)
                                :modeline (theme-modeline :buffer "*home*"))))
     output)
    output))

(defun site--file-layout (filename)
  "FILENAME's #+layout: keyword value, or nil."
  (cadr (assoc "LAYOUT" (with-temp-buffer
                          (insert-file-contents filename)
                          (org-mode)
                          (org-collect-keywords '("LAYOUT"))))))

(defun site--topic-list-buffer-name (title explicit)
  "Return EXPLICIT #+buffer_name if given, else TITLE's first word lowercased
and wrapped in *...*."
  (or explicit (format "*%s*" (downcase (car (split-string title))))))

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
                     (org-collect-keywords '("TITLE" "DATE" "SORT" "SHOW_CONSOLE" "CHIP_COLOR" "BUFFER_NAME"))))
         (title (or (cadr (assoc "TITLE" keywords)) (file-name-base filename)))
         (date (denden--org-date-to-iso (cadr (assoc "DATE" keywords))))
         (groups (denden-parse-topic-list filename))
         (groups (if (equal (cadr (assoc "SORT" keywords)) "name") (site--sort-topic-groups groups) groups))
         (all-pages (plist-get plist :denden-all-pages))
         (chip-color (cadr (assoc "CHIP_COLOR" keywords)))
         (buffer-name (site--topic-list-buffer-name title (cadr (assoc "BUFFER_NAME" keywords)))))
    (site--write-page
     (site--wrap-page
      :title title
      :url (denden-pretty-url (file-relative-name output pub-dir))
      :body (theme-topic-list-page
             :title title :date date
             :intro-html (denden-topic-list-intro-html filename)
             :show-console (equal (cadr (assoc "SHOW_CONSOLE" keywords)) "true")
             :items-node (theme-topic-list-items :groups groups :tag-icons site-tag-icons
                                                  :chip-color chip-color :all-pages all-pages)
             :footer (theme-footer site-footer-content)
             :modeline (theme-modeline :buffer buffer-name
                                       :date (or date (format-time-string "%Y-%m-%d")))))
     output)
    output))

(defun site-publish-themes-page (plist filename pub-dir)
  "Publish FILENAME (content/themes.org) via `theme-themes-gallery-page', one
card per `site-all-schemes' entry."
  (let* ((all-pages (plist-get plist :denden-all-pages))
         (output (denden-output-file-for filename (cons nil plist)))
         (title (or (cadr (assoc "TITLE" (with-temp-buffer
                                            (insert-file-contents filename)
                                            (org-mode)
                                            (org-collect-keywords '("TITLE")))))
                    "Themes"))
         (body-html (with-temp-buffer
                      (insert-file-contents filename)
                      (org-mode)
                      (org-export-as 'denden-html nil nil t
                                     (denden-export-options-with-pages all-pages filename)))))
    (site--write-page
     (site--wrap-page
      :title title
      :url (denden-pretty-url (file-relative-name output pub-dir))
      :body (theme-themes-gallery-page
             :title title :body-html body-html
             :cards (site-all-schemes (plist-get plist :site-custom-css-text))
             :footer (theme-footer site-footer-content)
             :modeline (theme-modeline :buffer "*themes*" :date (format-time-string "%Y-%m-%d"))))
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
                                                 :all-pages all-pages :external nil)
             :footer (theme-footer site-footer-content)
             :modeline (theme-modeline :buffer "*sitemap*" :title title
                                       :date (format-time-string "%Y-%m-%d"))))
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
   ((equal (site--file-layout filename) "pose")
    (site-publish-pose-page plist filename pub-dir))
   (t (site-publish-single-page plist filename pub-dir))))

(defun site--distinct-sections (all-pages)
  "Return every non-empty :section value in ALL-PAGES, deduplicated."
  (delete-dups (delq nil (mapcar (lambda (p) (let ((section (plist-get p :section)))
                                                (and (not (string-empty-p section)) section)))
                                 all-pages))))

(defun site--write-term-page (term count pages buffer-name rss-url url output)
  "Write one term page (/tags/<tag>/ or /refs/<ref>/) for TERM at OUTPUT, with
no tag cloud or OG card."
  (site--write-page
   (site--wrap-page
    :rss-url rss-url
    :title term
    :url url :og-card nil
    :body (theme-post-listing
           :term-header (theme-term-header :tag term :count count)
           :article-list (theme-article-list :grouped-pages (denden-group-pages-by-year pages)
                                              :tag-icons site-tag-icons)
           :footer (theme-footer site-footer-content)
           :modeline (theme-modeline :buffer buffer-name)))
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
               :tag-cloud (theme-tag-cloud :tag-counts tag-counts)
               :article-list (theme-article-list
                              :grouped-pages (denden-group-pages-by-year (denden-pages-in-section all-pages section))
                              :tag-icons site-tag-icons)
               :footer (theme-footer site-footer-content)
               :modeline (theme-modeline :buffer (format "*%s*" section))))
       (expand-file-name (format "%s/index.html" section) pub-dir)))
    ;; No rss-url anywhere on this page: /tags/ and /refs/ never had one,
    ;; and every term page under them lost its own per-term feed to a
    ;; deferred cut -- nothing writes one to link to.
    (site--write-page
     (site--wrap-page :title "Tags" :url "tags/" :og-card nil
                      :body (theme-terms-list :tag-counts tag-counts :footer (theme-footer site-footer-content)
                                              :modeline (theme-modeline :buffer "*tags*")))
     (expand-file-name "tags/index.html" pub-dir))
    (dolist (tc tag-counts)
      (let* ((tag (plist-get tc :tag)) (tagged (denden-pages-with-tag all-pages tag)))
        (site--write-term-page tag (length tagged) tagged (format "*%s*" tag) nil
                               (format "tags/%s/" (downcase tag))
                               (expand-file-name (format "tags/%s/index.html" (downcase tag)) pub-dir))))
    (when ref-counts
      (site--write-page
       (site--wrap-page :title "Refs" :url "refs/" :og-card nil
                        :body (theme-terms-list :tag-counts ref-counts :footer (theme-footer site-footer-content)
                                                :modeline (theme-modeline :buffer "*refs*")))
       (expand-file-name "refs/index.html" pub-dir))
      (dolist (rc ref-counts)
        (let* ((ref (plist-get rc :tag)) (referring (denden-pages-with-ref all-pages ref)))
          (site--write-term-page ref (length referring) referring (format "*%s*" ref) nil
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
        (p (:class "wanted-poster-heading") "WANTED")
        (p (:class "wanted-poster-subject") "Page D. Notfound")
        (p (:class "wanted-poster-tag") "DEAD OR ALIVE")
        (p nil "Bounty: 404,069,420")
        (p nil "Last seen: " (code (:id "wanted-lastseen") "parts unknown"))
        (p (:class "wanted-poster-footer")
           "Even " (b nil "Roronoa Zoro") " would've found his way here faster."))
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
  (list 'div '(:class "post-body")
        (list 'p nil (list 'code nil "Symbol's value as variable is void: /404.html"))
        site--404-wanted-poster
        (append
         (list 'ul nil
               '(li nil (a (:href "/") "Home"))
               '(li nil (a (:href "/log/") "Log")))
         (let ((latest-item (site--404-latest-post-item all-pages))) (when latest-item (list latest-item))))
        '(p nil "Or open the command palette for everything else:")
        '(button (:type "button" :class "tag-cloud-btn center" :data-action "open-palette") "M-x (:Command palette)")
        site--404-wanted-lastseen-script))

(defun site-404-page (all-pages)
  "Return the 404 page, using ALL-PAGES for the latest-post link, in the usual
buffer/article/modeline shell."
  (list 'section '(:class "buffer buffer-content active" :id "buffer-content"
                   :role "region" :aria-label "Page not found")
        (list 'div '(:class "buffer-body")
              (list 'article '(:class "post-content")
                    '(div (:class "post-header") (h1 (:class "post-title") "Page not found"))
                    (site--404-body all-pages)))
        (theme-modeline :buffer "*Messages*")))

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
                                    author-name author-email favicon-url copyright)
  "Write real Atom feed XML to DIRECTORY/index.xml, rss.xml and feed.xml
alike: three conventional feed URLs, same content, each with its own
`self' link. A meta-refresh HTML redirect at rss.xml/feed.xml (the
previous approach) breaks any client that fetches a .xml URL and parses
the body as XML by extension/MIME type -- a feed reader, or a browser
rendering it directly -- since that never runs the HTML meta-refresh."
  (dolist (name '("index.xml" "rss.xml" "feed.xml"))
    (let* ((self-url (concat (file-name-as-directory base-url) name))
           (xml (denden-atom-feed :pages (site--feed-pages pages) :site-title feed-site-title
                                   :description description :base-url base-url :self-url self-url
                                   :author-name author-name :author-email author-email
                                   :favicon-url favicon-url :copyright copyright)))
      (site--write-string xml (expand-file-name name directory)))))

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

(defun site-build-wander-js (wander-source-file pub-dir)
  "Write PUB-DIR/wander/console/wander.js from WANDER-SOURCE-FILE, split into
consoles and pages by H2 label."
  (let (consoles pages)
    (dolist (group (denden-parse-topic-list wander-source-file))
      (let ((is-console (string-match-p "console" (downcase (plist-get group :label)))))
        (dolist (item (plist-get group :items))
          (if is-console (push (plist-get item :url) consoles) (push (plist-get item :url) pages)))))
    (site--write-string
     (format "const wander = { consoles:\n[%s],\npages:\n[%s],\nstyles: [\"wander-theme.css\"], ignore: [], }\n"
             (site--wander-js-array (nreverse consoles)) (site--wander-js-array (nreverse pages)))
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
  "Return PRETTY-URL's absolute OG-image URL, or nil if no PNG exists yet."
  (let* ((slug (site--og-slug pretty-url))
         (png (expand-file-name (concat slug ".png") site-og-png-directory)))
    (when (file-exists-p png)
      (concat (string-remove-suffix "/" (site-base-url)) "/og/" slug ".png"))))

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
  "Return PAGE's OG-card excerpt: the first two body-prose <p>s of its
rendered content, as blank-line separated plain text. Skips any <p> that
is really an image or its caption; see `site--og-prose-paragraphs'."
  (let* ((dom (with-temp-buffer (insert (plist-get page :content-html))
                                (libxml-parse-html-region (point-min) (point-max))))
         (paragraphs (seq-take (site--og-prose-paragraphs dom) 2)))
    (mapconcat (lambda (p) (string-trim (dom-texts p))) paragraphs "\n\n")))

(defun site--meta-description-for-page (page)
  "Return PAGE's meta-description text: its OG excerpt, collapsed to one line
and capped at 160 characters."
  (let ((text (replace-regexp-in-string "[ \t\n\r]+" " " (site--og-excerpt-for-page page))))
    (if (> (length text) 160) (concat (substring text 0 159) "…") text)))

(cl-defun site-build-og-cards (&key pages card-site-title favicon-path pub-dir word-count-fn)
  "Write one OG-card SVG per page in PAGES under PUB-DIR, titled
CARD-SITE-TITLE, with FAVICON-PATH embedded."
  (dolist (page pages)
    (site--write-string
     (site-og-card-svg :title (plist-get page :title)
                        :excerpt (site--og-excerpt-for-page page)
                        :tags (plist-get page :tags)
                        :slug (file-name-nondirectory (directory-file-name (plist-get page :url)))
                        :date (plist-get page :date) :meta-right (funcall word-count-fn page)
                        :card-site-title card-site-title :favicon-path favicon-path)
     (site--og-svg-output-path page pub-dir))))

(cl-defun site-build-section-og-card (&key title slug entry-count card-site-title favicon-path output-path)
  "Write one home/section-shaped OG card for TITLE/SLUG to OUTPUT-PATH, with
ENTRY-COUNT instead of a word count."
  (site--write-string
   (site-og-card-svg :title title :excerpt "" :tags nil :slug slug :date nil
                      :meta-right (format "%d entries" entry-count)
                      :card-site-title card-site-title :favicon-path favicon-path)
   output-path))

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
    ;; Log is the only section meant to be syndicated: the rest (Wander,
    ;; Media, Quotes, and every standalone page) are for browsing, not RSS.
    ;; The main feed and /log/'s own feed carry the same Log-only content.
    (site-write-feed-trio (denden-pages-in-section regular "log") pub-dir (site-base-url) site-title
                          site-description site-author-name site-author-email nil site-copyright)
    (site-write-feed-trio (denden-pages-in-section regular "log") (expand-file-name "log" pub-dir)
                          (site-base-url) site-title site-description
                          site-author-name site-author-email nil site-copyright)
    ;; Per-term (tag/ref) feeds are a deferred cut -- home and every
    ;; section still get one.
    (site-build-sitemap enriched pub-dir)
    (site-build-robots (site-base-url) pub-dir)
    (site-build-aliases enriched pub-dir)
    (site-build-legacy-redirects (site-base-url) pub-dir)
    (site-build-search-index regular pub-dir)
    (site-build-wander-js (expand-file-name "content/wander.org" repository-directory) pub-dir)
    (site-build-wander-theme-css pub-dir)
    (site-build-og-cards :pages regular :card-site-title site-title :favicon-path favicon-path
                         :pub-dir pub-dir :word-count-fn #'site--word-count-meta)
    (site-build-section-og-card :title site-title :slug nil :entry-count (length regular)
                                :card-site-title site-title :favicon-path favicon-path
                                :output-path (expand-file-name "og.svg" pub-dir))
    (dolist (section (site--distinct-sections regular))
      (site-build-section-og-card :title (capitalize section) :slug section
                                  :entry-count (length (denden-pages-in-section regular section))
                                  :card-site-title site-title :favicon-path favicon-path
                                  :output-path (expand-file-name (format "%s/og.svg" section) pub-dir)))
    (site-build-404-page all-pages pub-dir)))

;;;; org-publish project definition, real build entry points

;; sidenote is inline (mid-sentence), unlike note/tip/warn -- Org special
;; blocks are always block-level, so there's no equivalent syntax for
;; those. A global macro is the idiomatic fit instead: {{{sidenote(text)}}}
;; anywhere in a post expands via this @@html:...@@ export snippet, no
;; per-file #+macro: declaration needed. Text inside is normal Org content
;; (formatting like *bold* still works), unlike Hugo's {{< sidenote >}}
;; shortcode, whose .Inner went through markdownify -- a real behaviour
;; difference from the old mechanism, not just a syntax port.
(add-to-list 'org-export-global-macros
             (cons "sidenote" "@@html:<aside class=\"sidenote\">@@$1@@html:</aside>@@"))

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
(setq denden-full-build-function #'site-build)
(setq denden-build-function #'site-build-async)
(setq denden-build-file-function #'site-build-file-async)

;;;; This site's own M-x commands, via `denden-define-command'

(denden-define-command idlip og-regenerate-all ()
  "Regenerate every regular page's OG card SVG, without a full rebuild."
  (let* ((leaves (org-publish-expand-projects (list (assoc "site" org-publish-project-alist))))
         (all-pages (denden-collect-page-metadata leaves))
         (enriched (mapcar (lambda (p) (site--enrich-page p (site-base-url) all-pages)) all-pages))
         (regular (site--regular-pages enriched))
         (favicon-path (expand-file-name site-favicon-relative-path
                                         (expand-file-name "static" denden-repository-directory))))
    (site-build-og-cards :pages regular :card-site-title site-title :favicon-path favicon-path
                          :pub-dir site-publishing-directory :word-count-fn #'site--word-count-meta)))

(provide 'site)
;;; site.el ends here
