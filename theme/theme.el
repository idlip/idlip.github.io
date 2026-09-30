;;; theme.el --- sexp-HTML templates for the site theme -*- lexical-binding: t; -*-

;;; Commentary:

;; Templates (sexp-HTML) for the Emacs-frame chrome, single-post pages,
;; listing pages, topic-list pages and the themes gallery. Generic
;; templates only -- no site config data lives here; the site layer
;; (site.el) supplies it.
;;
;; Menu-bar dropdowns and the scheme popup are <details>/<summary> (native
;; open/close, one-at-a-time via name="menu"), not JS-toggled divs.
;; Font-size +/- and text-alignment cycling are not offered (browser zoom
;; already covers the former; the latter's justify/columns options fight
;; WCAG 1.4.8/1.4.10). Only x, Ctrl/Cmd-K, Ctrl/Cmd-S and Alt-X open the
;; command palette; no other single-key shortcuts exist, since the chrome
;; is mouse/touch-first. The topic-list/themes-gallery search box and
;; view-toggle are real markup (view-toggle is a checkbox + CSS :has(),
;; not a JS-toggled class); their filtering behaviour needs the site
;; layer's own JS to reach the page. "Launch Wander Console" is a plain
;; <a href>, not JS-dependent.

;;; Code:

(require 'cl-lib)
(require 'denden)

(defun theme--url-domain (url)
  "Return URL's bare domain, e.g. \"example.com\" from
\"https://example.com/x\"."
  (replace-regexp-in-string "/.*\\'" "" (replace-regexp-in-string "\\`https?://\\(www\\.\\)?" "" url)))

(defun theme--tag-icon (tags tag-icons)
  "Return the first of TAGS with an entry in TAG-ICONS, else \"_default\",
else \"\"."
  (or (cl-some (lambda (tag) (cdr (assoc (downcase tag) tag-icons))) tags)
      (cdr (assoc "_default" tag-icons))
      ""))

;;;; Emacs-frame chrome: menu bar, modeline, echo area, lightbox, footer

(defun theme--dropdown-link (url label)
  "A menu-dropdown-item <a> to URL with text LABEL."
  (list 'a (list :href url :class "menu-dropdown-item" :role "menuitem")
        (list 'span nil label)))

(defun theme--dropdown-action (action label &optional shortcut)
  "A menu-dropdown-item <button> firing data-action ACTION, with LABEL and an
optional SHORTCUT shown at right."
  (append
   (list 'button (list :class "menu-dropdown-item" :role "menuitem" :data-action action)
         (list 'span nil label))
   (when shortcut (list (list 'span '(:class "menu-shortcut") shortcut)))))

(defconst theme--menu-separator '(div (:class "menu-separator" :role "separator")))

(cl-defun theme--buffers-menu (&key menu-items rss-url)
  "The Buffers dropdown: MENU-ITEMS (:name :url plists), a Tags link, RSS-URL."
  (list 'details '(:class "menu-item" :name "menu" :role "none")
        '(summary (:role "menuitem" :aria-haspopup "true" :aria-expanded "false")
                 (span (:class "underline") "B") "uffers")
        (append
         (list 'div '(:class "menu-dropdown" :role "menu"))
         (mapcar (lambda (item) (theme--dropdown-link (plist-get item :url) (plist-get item :name)))
                 menu-items)
         (list theme--menu-separator (theme--dropdown-link "/tags/" "Tags"))
         (when rss-url
           (list theme--menu-separator
                 (list 'a (list :href rss-url :class "menu-dropdown-item" :role "menuitem" :target "_blank")
                       (list 'span nil "RSS Feed")))))))

(defun theme--scheme-option-button (scheme swatch-style)
  "A scheme-picker button for SCHEME (:name :label plist), styled
SWATCH-STYLE."
  (list 'button (list :class "menu-dropdown-item scheme-option" :role "menuitem"
                       :data-scheme (plist-get scheme :name) :style swatch-style)
        '(span (:class "scheme-dot" :aria-hidden "true"))
        (list 'span nil (plist-get scheme :label))))

(cl-defun theme--view-menu (&key color-schemes swatch-style-fn)
  "The View dropdown: theme toggle, COLOR-SCHEMES (styled via
SWATCH-STYLE-FN)."
  (list 'details '(:class "menu-item" :name "menu" :role "none")
        '(summary (:role "menuitem" :aria-haspopup "true" :aria-expanded "false")
                 (span (:class "underline") "V") "iew")
        (append
         (list 'div '(:class "menu-dropdown" :role "menu")
               (theme--dropdown-action "toggle-theme" "Toggle Dark/Light")
               theme--menu-separator)
         (mapcar (lambda (scheme) (theme--scheme-option-button scheme (funcall swatch-style-fn scheme)))
                 color-schemes))))

(defun theme--social-link (link)
  "An <a> for social LINK; adds target=_blank and rel for anything but a
mailto: link."
  (let* ((url (plist-get link :url))
         (extra-rel (plist-get link :rel))
         (rel (if extra-rel (format "noopener noreferrer %s" extra-rel) "noopener noreferrer"))
         (external (not (string-prefix-p "mailto:" url))))
    (append
     (list 'a (list :href url :class "menu-dropdown-item" :role "menuitem"
                     :target (and external "_blank") :rel (and external rel))
           (list 'span '(:class "nf") (plist-get link :icon)))
     (list (list 'span nil (plist-get link :label))))))

(defun theme--social-link-item (link)
  "One <a class=\"social-link\"> for LINK, the body-content shape used by
`theme-social-links-grid'."
  (let* ((url (plist-get link :url))
         (extra-rel (plist-get link :rel))
         (rel (if extra-rel (format "noopener noreferrer %s" extra-rel) "noopener noreferrer"))
         (external (not (string-prefix-p "mailto:" url))))
    (list 'a (list :href url :class "social-link"
                   :target (and external "_blank") :rel (and external rel))
          (list 'span '(:class "nf" :aria-hidden "true") (plist-get link :icon))
          (list 'span '(:class "social-label") (plist-get link :label)))))

(defun theme-social-links-grid (links)
  "A standalone social-links grid for body content (LINKS). Only the grid
variant exists; \"is-grid\" is a separate class."
  (append
   (list 'div '(:class "social-links is-grid"))
   (mapcar #'theme--social-link-item links)))

(cl-defun theme--help-menu (&key social-links)
  "The Help dropdown: shortcuts, an About link, SOCIAL-LINKS."
  (append
   (list 'details '(:class "menu-item" :name "menu" :role "none")
         '(summary (:role "menuitem" :aria-haspopup "true" :aria-expanded "false")
                  (span (:class "underline") "H") "elp")
         (append
          (list 'div '(:class "menu-dropdown" :role "menu")
                theme--menu-separator
                (theme--dropdown-link "/about/" "About"))
          (when social-links
            (cons theme--menu-separator (mapcar #'theme--social-link social-links)))))))

(defun theme--mx-menu ()
  "The command dropdown: every JS-callable action, static (no site data)."
  (list 'details '(:class "menu-item" :name "menu" :role "none")
        '(summary (:role "menuitem" :aria-haspopup "true" :aria-expanded "false")
                 (span (:class "underline") "M") "-x")
        (list 'div '(:class "menu-dropdown" :role "menu")
              (theme--dropdown-action "open-palette" "Open Command Palette" "x")
              theme--menu-separator
              (theme--dropdown-action "toggle-theme" "Toggle Dark/Light")
              (theme--dropdown-action "cycle-font" "Cycle Font Mode")
              (theme--dropdown-action "cycle-width" "Cycle Content Width")
              (theme--dropdown-action "browse-schemes" "Browse All Schemes")
              theme--menu-separator
              ;; menuitemcheckbox, not menuitem: this is a toggle, and
              ;; aria-pressed is not valid on a menuitem.
              '(button (:class "menu-dropdown-item" :role "menuitemcheckbox"
                        :aria-checked "false" :data-action "fix-scheme")
                       (span nil "Pin / Unpin Scheme"))
              '(button (:class "menu-dropdown-item" :role "menuitem" :data-action "toggle-keys")
                       (span nil "Enable / disable \"x\" shortcut")))))

(cl-defun theme--menu-bar-right (&key site-title color-schemes swatch-style-fn)
  "The right-hand controls: title link (SITE-TITLE), palette/font/width
buttons, and the scheme popup."
  (append
   (list 'div '(:class "menu-bar-right")
         (list 'a '(:href "/log/" :class "menu-bar-title") site-title)
         '(button (:class "tag-cloud-btn" :title "Open Search + M-x Command palette Dialog"
                   :aria-label "Open Search + Command palette Dialog" :data-action "open-palette")
                  (span (:class "nf" :aria-hidden "true") "󰨈 ")
                  " Log pose "
                  (span (:class "nf" :aria-hidden "true") " 󰠳"))
         '(button (:class "menu-bar-btn" :id "font-cycle-btn"
                   :title "Cycle font: mono → sans → mixed" :aria-label "Cycle font mode"
                   :data-action "cycle-font")
                  (span (:class "nf" :aria-hidden "true") ""))
         '(button (:class "menu-bar-btn" :id "ml-width-btn"
                   :title "Cycle content width [100% → 80ch → 60ch → 840px]"
                   :aria-label "Cycle content width" :data-action "cycle-width")
                  (span (:class "nf" :aria-hidden "true") "󰭣 ")))
   (when color-schemes
     (list
      (append
       (list 'details '(:class "scheme-popup-container" :id "scheme-popup-container")
             '(summary (:class "menu-bar-btn scheme-popup-btn" :id "scheme-popup-btn"
                       :aria-label "Color scheme" :title "Color scheme"
                       :aria-expanded "false" :aria-haspopup "true")
                      (span (:class "nf" :aria-hidden "true") "")))
       (list
        (append
         (list 'div '(:class "scheme-popup" :id "scheme-popup" :role "menu" :aria-label "Color schemes"))
         (mapcar (lambda (scheme) (theme--scheme-option-button scheme (funcall swatch-style-fn scheme)))
                 color-schemes)
         (list theme--menu-separator
               '(div (:class "scheme-popup-actions")
                     (button (:class "scheme-action-btn" :id "pin-scheme-btn" :data-action "fix-scheme"
                              :aria-pressed "false"
                              :title "Pin: lock current scheme, or unpin to go random each session")
                             (span (:class "nf" :aria-hidden "true") "󰐅 ")
                             (span (:id "pin-scheme-label") "Pin")))))))))
   (list '(button (:class "menu-bar-btn" :aria-label "Toggle dark/light"
                   :data-action "toggle-theme" :title "Toggle dark/light")
                  (span (:class "nf theme-icon-dark" :aria-hidden "true") "")
                  (span (:class "nf theme-icon-light" :aria-hidden "true") "")))))

(cl-defun theme-menu-bar (&key menu-items color-schemes social-links site-title rss-url
                                (swatch-style-fn (lambda (_scheme) "")))
  "The full menu-bar header plus its backdrop div, titled SITE-TITLE."
  (let ((nav-node
         (append
          (list 'nav '(:class "menu-items" :role "menubar" :aria-label "Site navigation"))
          (list (theme--buffers-menu :menu-items menu-items :rss-url rss-url)
                (theme--view-menu :color-schemes color-schemes :swatch-style-fn swatch-style-fn)
                (theme--help-menu :social-links social-links)
                (theme--mx-menu)))))
    (list
     (list 'header '(:class "menu-bar")
           '(button (:class "menu-hamburger" :aria-label "Toggle menu" :aria-expanded "false")
                    (span (:aria-hidden "true") "☰"))
           nav-node
           (theme--menu-bar-right :site-title site-title :color-schemes color-schemes
                                   :swatch-style-fn swatch-style-fn))
     '(div (:class "menu-backdrop" :id "menu-backdrop" :aria-hidden "true")))))

(cl-defun theme-modeline (&key buffer title wordcount readingtime date widthtoggle progress)
  "The Emacs-style status bar for
BUFFER/TITLE/WORDCOUNT/READINGTIME/DATE/PROGRESS; BUFFER defaults to
*scratch*."
  (ignore widthtoggle)
  (let ((buffer (or buffer "*scratch*")))
    (append
     (list 'div '(:class "modeline" :role "status"))
     (when progress (list '(div (:class "read-progress" :id "read-progress" :aria-hidden "true"))))
     (list
      (append
       (list 'div '(:class "ml-left"))
       (when date
         (list (list 'span '(:class "ml-group ml-hide-mobile")
                     (list 'span '(:class "nf ml-date-icon" :aria-hidden "true") " ")
                     (list 'time (list :class "ml-date" :datetime date) (concat " " date)))
               '(span (:class "ml-sep ml-hide-mobile" :aria-hidden "true") "·")))
       (list (list 'span '(:class "ml-group")
                   (list 'button '(:class "ml-buffer" :data-action "open-palette"
                                          :title "Open command palette (x)")
                         (concat " " (truncate-string-to-width (or title buffer) 80)))))
       (when readingtime
         (list '(span (:class "ml-sep" :aria-hidden "true") "·")
               (list 'span '(:class "ml-readtime ml-hide-mobile") (format " %s min" readingtime))))
       (when wordcount
         (list '(span (:class "ml-sep" :aria-hidden "true") "·")
               (list 'span '(:class "ml-wc") (format "%sw" wordcount))))))
     (list
      '(span (:class "ml-fill" :aria-hidden "true"))
      '(div (:class "ml-right")
            (button (:class "ml-pin-btn ml-hide-mobile" :id "ml-pin-btn" :data-action "fix-scheme"
                            :aria-pressed "false" :title "Pin / unpin color scheme")
                    (span (:id "ml-pin-label") "Pin"))
            )))))

(defconst theme-echo-area
  '(dialog (:id "palette-dialog" :aria-label "Command palette")
           (div (:class "palette-input-wrap")
                (input (:type "text" :id "palette-input" :class "palette-input"
                        :placeholder "Search commands and posts…" :autocomplete "off"
                        :autocapitalize "off" :spellcheck "false")))
           (div (:id "palette-results" :role "listbox")))
  "The command palette dialog, a native <dialog> element.")

(defun theme-footer (footer-content)
  "Return FOOTER-CONTENT unchanged, with no wrapper markup of its own."
  footer-content)

(defconst theme--rain-confetti-spans
  '(span (:class "rain-confetti" :aria-hidden "true")
    (span nil "0") (span nil "1") (span nil "{") (span nil "}")
    (span nil "<") (span nil ">") (span nil "/") (span nil "\\")
    (span nil ";") (span nil ":") (span nil "+") (span nil "~")
    (span nil "=") (span nil "-") (span nil "_") (span nil "|")
    (span nil "#") (span nil "$") (span nil "%") (span nil "&")
    (span nil "(") (span nil ")") (span nil "[") (span nil "]"))
  "The ascii-rain hover easter egg. Its text still counts in `dom-texts',
since aria-hidden is not respected there.")


(cl-defun theme-badge (&key name logo color link subtitle tooltip)
  "One badge link for NAME (icon + optional subtitle + optional name pill).
COLOR, if given, also sets --glow (theme.css's rotating gradient ring,
shared by every card/button-shaped element, reads it on hover). Sets
border-width/style/color as three longhands, not the border shorthand:
the shorthand also resets border-image back to none, and being inline
that reset would outrank theme.css's own hover rule for it."
  (let ((tooltip (or tooltip (and subtitle name (format "%s %s" subtitle name)) subtitle name "")))
    (append
     (list 'a (list :href (or link "#") :class "badge rain-hover" :title tooltip
                     :style (and color (format "border-width:1px;border-style:solid;border-color:%s;--glow:%s"
                                                color color))))
     (list (list 'span '(:class "badge-icon") (list 'img (list :src logo :alt (or name "") :loading "lazy"))))
     (when subtitle (list (list 'span '(:class "badge-subtitle") subtitle)))
     (when name (list (list 'span (list :class "badge-name" :style (and color (format "background:%s" color)))
                            name)))
     (list theme--rain-confetti-spans))))

(defconst theme-lightbox
  '(dialog (:id "image-lightbox" :aria-label "Image preview")
           (img (:id "lightbox-img" :src "" :alt "")))
  "The image lightbox dialog. :src/:alt stay empty strings, not bare, so
libxml keeps them for the alt-text lint.")

(defconst theme-pose-dialog
  '(dialog (:id "pose-dialog" :aria-label "Pose entry")
           (h2 (:id "pose-dialog-title"))
           (div (:id "pose-dialog-content" :class "post-body")))
  "The shared Pose entry dialog: the same look as `theme-lightbox' (CSS
groups the two by selector, nothing new), content styled by the existing
`post-body' class rather than a dedicated one. JS fills title/content in
from `window.__poseEntries', keyed by the clicked card's own heading id.")


(defconst theme--base16-keys
  ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07"
   "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"]
  "The 16 base16 CSS custom-property names, in order, shared with palette.js's
BASE_KEYS.")


(defun theme--pre-paint-script (color-schemes schemes-url)
  "The theme/scheme pre-paint script, using COLOR-SCHEMES and SCHEMES-URL,
applied before first paint."
  (let ((scheme-keys (vconcat (mapcar (lambda (s) (plist-get s :name)) color-schemes))))
    (list 'raw-html nil
          (format "<script>
window.__schemesUrl=%s;
(function(){
var r=document.documentElement;
var t=localStorage.getItem('emacs-theme');
if(t)r.setAttribute('data-theme',t);
var cp=localStorage.getItem('emacs-custom-palette');
if(cp){
try{
var d=JSON.parse(cp);
var ks=%s;
d.colors.forEach(function(c,i){if(c)r.style.setProperty('--'+ks[i],c);});
}catch(e){}
}else{
var fixed=localStorage.getItem('emacs-scheme-fixed');
if(fixed!==null){
if(fixed)r.setAttribute('data-scheme',fixed);else r.removeAttribute('data-scheme');
}else{
var nav=(performance.getEntriesByType('navigation')[0]||{}).type;
var last=localStorage.getItem('emacs-scheme-last');
var pick;
if(nav==='back_forward'&&last!==null){
pick=last;
}else{
var S=%s;
pick=S[Math.floor(Math.random()*S.length)];
}
if(pick)r.setAttribute('data-scheme',pick);else r.removeAttribute('data-scheme');
localStorage.setItem('emacs-scheme-last',pick||'');
}
}
})();
</script>"
                  (json-serialize schemes-url) (json-serialize theme--base16-keys)
                  (json-serialize scheme-keys)))))

(defconst theme-color-meta-value "#0a0f0a"
  "The <meta name=\"theme-color\"> browser-chrome tint, fixed since scheme
picking happens after paint.")


(cl-defun theme--seo-head-nodes (&key og-title description canonical-url favicon-href favicon-type
                                       og-type og-image published-time modified-time tags site-title
                                       author-name language noindex fediverse-creator)
  "The page-dependent <head> children: description, canonical, favicon,
fediverse:creator, OG/Twitter meta, and JSON-LD for articles."
  (let ((og-title (or og-title site-title)))
    (append
     (when description (list (list 'meta (list :name "description" :content description))))
     (when noindex (list '(meta (:name "robots" :content "noindex"))))
     (when fediverse-creator
       (list (list 'meta (list :name "fediverse:creator" :content fediverse-creator))
             (list 'meta (list :property "fediverse:creator" :content fediverse-creator))))
     (when canonical-url (list (list 'link (list :rel "canonical" :href canonical-url))))
     (when favicon-href (list (list 'link (list :rel "icon" :type favicon-type :href favicon-href))))
     (when canonical-url
       (append
        (list (list 'meta (list :property "og:title" :content og-title))
              (list 'meta (list :property "og:type" :content (or og-type "website")))
              (list 'meta (list :property "og:url" :content canonical-url))
              (list 'meta (list :property "og:site_name" :content site-title))
              (list 'meta (list :property "og:locale" :content language)))
        (when description (list (list 'meta (list :property "og:description" :content description))))
        (when published-time
          (list (list 'meta (list :property "article:published_time" :content published-time))))
        (when modified-time
          (list (list 'meta (list :property "article:modified_time" :content modified-time))))
        (mapcar (lambda (tag) (list 'meta (list :property "article:tag" :content tag))) tags)
        (when og-image
          (list (list 'meta (list :property "og:image" :content og-image))
                '(meta (:property "og:image:width" :content "1200"))
                '(meta (:property "og:image:height" :content "630"))
                (list 'meta (list :property "og:image:alt" :content og-title))
                (list 'meta (list :name "twitter:image" :content og-image))))
        (list '(meta (:name "twitter:card" :content "summary_large_image")))))
     (when (and (equal og-type "article") description published-time)
       (list (list 'script '(:type "application/ld+json")
                   (list 'raw-html nil
                         (json-serialize
                          (append
                           `((@context . "https://schema.org") (@type . "BlogPosting")
                             (headline . ,og-title) (description . ,description)
                             (datePublished . ,published-time)
                             (author . ((@type . "Person") (name . ,author-name)))
                             (publisher . ((@type . "Person") (name . ,author-name)))
                             (mainEntityOfPage . ((@type . "WebPage") (@id . ,canonical-url)))
                             (url . ,canonical-url))
                           (when modified-time `((dateModified . ,modified-time)))
                           (when og-image `((image . [,og-image])))
                           (when tags `((keywords . ,(mapconcat #'identity tags ", ")))))))))))))

(defun theme--analytics-script (script-url website-id)
  "The Umami loader <script> for SCRIPT-URL/WEBSITE-ID, or nil if either is
nil. Injected via `requestIdleCallback'."
  (when (and script-url website-id)
    (list 'raw-html nil
          (format "<script>
(function(){
function loadUmami(){
var s=document.createElement('script');
s.defer=true;
s.src=%s;
s.setAttribute('data-website-id',%s);
document.head.appendChild(s);
}
if('requestIdleCallback' in window) requestIdleCallback(loadUmami);
else setTimeout(loadUmami,2000);
})();
</script>" (json-serialize script-url) (json-serialize website-id)))))

(cl-defun theme-baseof (&key language body palette-data-script stylesheet-href script-href page-title
                              og-title menu-items color-schemes social-links site-title rss-url
                              schemes-url description canonical-url favicon-href favicon-type og-type
                              og-image published-time modified-time tags author-name noindex
                              fediverse-creator analytics-script-url analytics-website-id
                              (swatch-style-fn (lambda (_scheme) "")))
  "The page skeleton for LANGUAGE and BODY, as a single <html> node.
PALETTE-DATA-SCRIPT must be a `(raw-html nil STRING)' node."
  (let ((menu-bar-nodes (theme-menu-bar :menu-items menu-items :color-schemes color-schemes
                                         :social-links social-links :site-title site-title
                                         :rss-url rss-url :swatch-style-fn swatch-style-fn)))
    (list 'html (list :lang language :data-theme "dark" :data-scheme "haki")
          (append (list 'head nil '(meta (:charset "utf-8")))
                  (when schemes-url (list (theme--pre-paint-script color-schemes schemes-url)))
                  (list '(meta (:name "viewport" :content "width=device-width, initial-scale=1.0"))
                        '(meta (:name "color-scheme" :content "dark light"))
                        (list 'meta (list :name "theme-color" :content theme-color-meta-value))
                        '(meta (:name "view-transition" :content "same-origin")))
                  (when page-title (list (list 'title nil page-title)))
                  (theme--seo-head-nodes :og-title og-title :description description
                                         :canonical-url canonical-url :favicon-href favicon-href
                                         :favicon-type favicon-type :og-type og-type :og-image og-image
                                         :published-time published-time :modified-time modified-time
                                         :tags tags :site-title site-title :author-name author-name
                                         :language language :noindex noindex
                                         :fediverse-creator fediverse-creator)
                  (when stylesheet-href (list (list 'link (list :rel "stylesheet" :href stylesheet-href))))
                  (when script-href (list (list 'script (list :src script-href :defer "defer"))))
                  (let ((analytics (theme--analytics-script analytics-script-url analytics-website-id)))
                    (when analytics (list analytics))))
          (append
           (list 'body nil
                 '(a (:class "skip-link" :href "#buffer-container") "Skip to content")
                 (append
                  (list 'div '(:class "emacs-frame"))
                  menu-bar-nodes
                  (list (list 'main '(:class "buffer-container" :id "buffer-container") body)
                        theme-echo-area theme-lightbox theme-pose-dialog)))
           (when palette-data-script (list palette-data-script))))))

;;;; Single post/page

(cl-defun theme-breadcrumbs (&key ancestors title)
  "Breadcrumbs from ANCESTORS, a list of (:title :url) plists home first, to
the current page's TITLE."
  (append
   (list 'nav '(:class "breadcrumbs" :aria-label "breadcrumb")
         '(a (:href "/") "~"))
   (mapcan (lambda (ancestor)
             (list '(span (:class "breadcrumb-sep") "/")
                   (list 'a (list :href (plist-get ancestor :url)) (downcase (plist-get ancestor :title)))))
           ancestors)
   (list '(span (:class "breadcrumb-sep") "/")
         (list 'span '(:class "breadcrumb-current") (truncate-string-to-width title 40)))))

(cl-defun theme-post-header (&key title date lastmod wordcount readingtime tags)
  "The post header for TITLE: date, word count, tags. A nil DATE or LASTMOD
hides that field."
  (list 'div '(:class "post-header")
        (list 'h1 '(:class "post-title") title)
        (append
         (list 'div '(:class "post-meta"))
         (when date
           (list (list 'span '(:class "post-date" :title "Created on")
                       '(span (:class "nf" :aria-hidden "true") "")
                       '(span (:class "visually-hidden") "Created on: ")
                       (list 'time (list :datetime date) date))))
         (when (and lastmod date (not (equal lastmod date)))
           (list (list 'span '(:class "post-date-updated" :title "Updated on")
                       '(span (:class "nf" :aria-hidden "true") "󰚰")
                       '(span (:class "visually-hidden") "Updated on: ")
                       (list 'time (list :datetime lastmod) lastmod))))
         (list (list 'span '(:class "post-reading-time")
                     (format "%s min read (%s words)" (or readingtime 0) (or wordcount 0))))
         (when tags
           (list (append
                  (list 'div '(:class "post-tags"))
                  (mapcar (lambda (tag)
                            (list 'a (list :href (format "/tags/%s/" (downcase tag)) :class "post-tag")
                                  tag))
                          tags)))))))

(defun theme-comment (email title unique-id)
  "The mailto:-based comment box: EMAIL to send to, TITLE as the mail subject,
UNIQUE-ID as its DOM id."
  (list
   (list 'div '(:class "post-comment")
         (list 'label (list :class "comment-label" :for (format "comment-%s" unique-id)) "Leave a comment")
         (list 'textarea (list :id (format "comment-%s" unique-id) :class "comment-textarea"
                                :placeholder "Write your thoughts…" :rows "4"))
         (list 'div '(:class "comment-actions")
               (list 'button (list :class "comment-submit" :type "button" :data-email email
                                    :data-subject (format "Re: %s" title) :data-uid unique-id)
                     "Comment")))
   (list 'script nil
         (format "(function () {
  var btn = document.querySelector('.comment-submit[data-uid=\"%s\"]');
  if (!btn) return;
  btn.addEventListener('click', function () {
    var body    = document.getElementById('comment-%s').value;
    var subject = encodeURIComponent(btn.dataset.subject);
    var bodyEnc = encodeURIComponent(body);
    window.location.href =
      'mailto:' + btn.dataset.email +
      '?subject=' + subject +
      (bodyEnc ? '&body=' + bodyEnc : '');
  });
})();" unique-id unique-id))))

(defun theme--reference-item (ref)
  "One <li> for REF, a (:href :label :internal) plist."
  (if (plist-get ref :internal)
      (list 'li nil (list 'a (list :href (plist-get ref :href)) (plist-get ref :label)))
    (append
     (list 'li nil
           (list 'a (list :href (plist-get ref :href) :target "_blank" :rel "noopener noreferrer")
                 (or (plist-get ref :label) (plist-get ref :href))))
     (when (and (plist-get ref :label) (not (equal (plist-get ref :label) (plist-get ref :href))))
       (list (list 'span '(:class "references-url") (theme--url-domain (plist-get ref :href))))))))

(defun theme--format-related-date (iso-date)
  "Return ISO-DATE (\"YYYY-MM-DD\") as \"02 Jan 2006\"-shaped display text,
for the See Also list."
  (denden-format-iso-date iso-date "%d %b %Y"))

(defun theme--related-item (page)
  "One <li> for PAGE (a page-metadata plist), used in the See Also list."
  (list 'li (list :class "article-item" :data-url (concat "/" (plist-get page :url))
                   :data-title (downcase (plist-get page :title)))
        (list 'a (list :href (concat "/" (plist-get page :url)) :class "article-link")
              (list 'span '(:class "article-meta")
                    (list 'time (list :class "article-date" :datetime (plist-get page :date))
                          '(span (:class "nf nf-sm" :aria-hidden "true") " ")
                          (theme--format-related-date (plist-get page :date))))
              (list 'span '(:class "article-title") (plist-get page :title)))
        (when (plist-get page :tags)
          (append
           (list 'span '(:class "post-tags"))
           (mapcar (lambda (tag)
                     (list 'a (list :href (format "/tags/%s/" (downcase tag)) :class "post-tag")
                           tag))
                   (seq-take (plist-get page :tags) 2))))))

(cl-defun theme-references (&key refs related)
  "Render the References section for REFS and the See Also section for
RELATED; either omitted when empty."
  (append
   (when refs
     (list (append
            (list 'section '(:class "references" :aria-labelledby "references-heading")
                  '(h2 (:id "references-heading" :class "references-title") "References"))
            (list (append (list 'ol '(:class "references-list")) (mapcar #'theme--reference-item refs))))))
   (when related
     (list (append
            (list 'ul '(:class "article-list similar-posts" :role "list" :aria-label "Related posts")
                  '(li (:class "year-divider") (span (:class "year-label") "▷ See Also")))
            (mapcar #'theme--related-item related))))))

(cl-defun theme-post-navigation (&key prev next)
  "PREV/NEXT are (:title :url) page-metadata-shaped plists or nil."
  (append
   (list 'nav '(:class "post-navigation"))
   (list
    (append
     (list 'div nil)
     (when prev (list (list 'a (list :id "post-prev" :href (concat "/" (plist-get prev :url)))
                             (concat "← " (truncate-string-to-width (plist-get prev :title) 40 nil nil " …")))))
     (list '(span nil))
     (when next (list (list 'a (list :id "post-next" :href (concat "/" (plist-get next :url)))
                             (concat (truncate-string-to-width (plist-get next :title) 40 nil nil " …") " →"))))))))

(cl-defun theme-single-page (&key breadcrumbs post-header toc body-html references comment
                                   post-navigation footer modeline)
  "Assemble the single-post section from BREADCRUMBS, POST-HEADER, TOC,
BODY-HTML, and the rest; any can be nil."
  (append
   (list 'section '(:class "buffer buffer-content active" :id "buffer-content"
                    :role "region" :aria-label "Article content"))
   (list
    (append
     (list 'div '(:class "buffer-body" :id "content-body"))
     (list
      (append
       (list 'article '(:class "post-content" :id "article-content")
             breadcrumbs post-header)
       (when toc (list toc))
       (list (list 'div '(:class "post-body") (list 'raw-html nil body-html)))
       (or references nil)
       (or comment nil)
       (when post-navigation (list post-navigation))))
     (when footer (list (list 'footer nil footer)))))
   (when modeline (list modeline))))

(cl-defun theme-home-page (&key title body-html footer modeline)
  "The home page for TITLE/BODY-HTML: just title, body, footer and modeline,
no breadcrumbs or tags."
  (list 'section '(:class "buffer buffer-content active" :id "buffer-content"
                   :role "region" :aria-label "Home")
        (list 'div '(:class "buffer-body")
              (list 'article '(:class "post-content")
                    (list 'div '(:class "post-header") (list 'h1 '(:class "post-title") title))
                    (list 'div '(:class "post-body") (list 'raw-html nil body-html)))
              (append (list 'footer nil) (when footer (list footer))))
        modeline))

(cl-defun theme-pose-page (&key title intro-html entries entries-data-script footer modeline)
  "The Pose layout for TITLE/ENTRIES: one page of short-form cards, each with
its own shareable heading id and a click-to-expand dialog for its full
content (ENTRIES-DATA-SCRIPT, a <script> tag, supplies that full content
to the dialog; see `site--pose-entries-data-script')."
  (let* ((pose-list (append (list 'ul '(:class "pose-list"))
                             (mapcar
                              (lambda (entry)
                                (list 'li '(:class "pose-card")
                                      (list 'h2 (list :id (plist-get entry :id))
                                            (list 'button '(:type "button" :class "pose-card-trigger")
                                                  (plist-get entry :title)))
                                      (list 'raw-html nil (plist-get entry :teaser-html))))
                              entries)))
         (article (append
                   (list 'article '(:class "post-content")
                         (list 'div '(:class "post-header") (list 'h1 '(:class "post-title") title)))
                   (unless (or (null intro-html) (string-empty-p intro-html))
                     (list (list 'div '(:class "post-body") (list 'raw-html nil intro-html))))
                   (list pose-list))))
    (append
     (list 'section (list :class "buffer buffer-content active" :id "buffer-content"
                           :role "region" :aria-label title)
           (list 'div '(:class "buffer-body")
                 article
                 (append (list 'footer nil) (when footer (list footer))))
           modeline)
     (when entries-data-script (list entries-data-script)))))

;;;; Listing pages

(cl-defun theme-tag-cloud (&key tag-counts)
  "TAG-COUNTS is `denden-tag-counts' output, already count-sorted."
  (append
   (list 'div '(:class "tag-cloud" :id "tag-cloud"))
   (mapcar (lambda (tc)
             (list 'button (list :class "tag-cloud-btn" :data-tag (downcase (plist-get tc :tag)) :type "button")
                   (concat "#" (plist-get tc :tag))
                   (list 'span '(:class "tag-cloud-count") (number-to-string (plist-get tc :count)))))
           tag-counts)))

(cl-defun theme-article-item (&key page index tag-icons)
  "One <li> for PAGE, a page-metadata plist, at position INDEX, with tags via
TAG-ICONS."
  (let ((tags (plist-get page :tags)))
    (append
     (list 'li (list :class "article-item" :data-index (number-to-string index)
                      :data-year (if (plist-get page :date) (substring (plist-get page :date) 0 4) "")
                      :data-url (concat "/" (plist-get page :url)) :data-title (downcase (plist-get page :title))
                      :data-tags (mapconcat #'downcase tags ""))
           (list 'a (list :href (concat "/" (plist-get page :url)) :class "article-link")
                 (list 'span '(:class "article-meta")
                       (list 'span '(:class "article-reading-time")
                             '(span (:class "nf nf-sm" :aria-hidden "true") " ")
                             (format "%sm" (or (plist-get page :readingtime) 1)))
                       (list 'time (list :class "article-date" :datetime (plist-get page :date))
                             '(span (:class "nf nf-sm" :aria-hidden "true") " ")
                             (denden-format-iso-date (plist-get page :date) "%d %b")))
                 (list 'span '(:class "article-type-icon nf" :aria-hidden "true")
                       (theme--tag-icon tags tag-icons))
                 (list 'span '(:class "article-title") (plist-get page :title))))
     (when tags
       (list (append
              (list 'span '(:class "post-tags"))
              (mapcar (lambda (tag)
                        (list 'a (list :href (format "/tags/%s/" (downcase tag)) :class "post-tag")
                              tag))
                      (seq-take tags 3))))))))

(defun theme--year-divider (year)
  "One year-divider <li> labeled YEAR."
  (list 'li (list :class "year-divider" :data-year-sep year) (list 'span '(:class "year-label") year)))

(cl-defun theme-article-list (&key grouped-pages tag-icons)
  "The article list for GROUPED-PAGES (`denden-group-pages-by-year' output),
tags via TAG-ICONS."
  (if (null grouped-pages)
      '(ul (:class "article-list" :id "article-list" :role "list")
           (li (:class "article-item no-articles") "No articles found."))
    (let ((index 0))
      (append
       (list 'ul '(:class "article-list" :id "article-list" :role "list"))
       (mapcan
        (lambda (group)
          (cons (theme--year-divider (car group))
                (mapcar (lambda (page)
                          (prog1 (theme-article-item :page page :index index :tag-icons tag-icons)
                            (setq index (1+ index))))
                        (cdr group))))
        grouped-pages)))))

(cl-defun theme-terms-list (&key tag-counts footer modeline)
  "The /tags/ index: every tag from TAG-COUNTS, alphabetically linked, with
FOOTER/MODELINE."
  (let* ((sorted (sort (copy-sequence tag-counts)
                        (lambda (a b) (string< (plist-get a :tag) (plist-get b :tag)))))
         (items (if sorted
                    (mapcar (lambda (tc)
                              (list 'li (list :class "article-item"
                                              :data-url (format "/tags/%s/" (downcase (plist-get tc :tag))))
                                    (list 'a (list :href (format "/tags/%s/" (downcase (plist-get tc :tag)))
                                                   :class "article-link")
                                          (list 'span '(:class "post-tag") (plist-get tc :tag))
                                          (list 'span '(:class "article-meta" :style "margin-left:auto")
                                                (list 'span '(:class "article-reading-time")
                                                      (format "%d posts" (plist-get tc :count)))))))
                            sorted)
                  (list '(li (:class "article-item no-articles") "No tags found.")))))
    (append
     (list 'section '(:class "buffer buffer-list active" :id "buffer-list"
                      :role "region" :aria-label "Tags")
           (list 'div '(:class "buffer-body")
                 (append (list 'div '(:class "list-content"))
                         (list (append (list 'ul '(:class "article-list" :id "article-list" :role "list"))
                                       items))
                         (list (append (list 'footer '(:class "list-footer")) (when footer (list footer)))))))
     (when modeline (list modeline)))))

(cl-defun theme-term-header (&key tag count)
  "The /tags/TAG/ page header: tag name, post COUNT, a link back to /tags/."
  (list 'div '(:class "term-header")
        (list 'span '(:class "term-tag-name") (concat "#" tag))
        (list 'span '(:class "article-reading-time")
              (format "— %d %s" count (if (= count 1) "post" "posts")))
        '(a (:href "/tags/" :class "term-back") "← all tags")))

(defconst theme--list-search-box
  '(div (:class "list-search" :role "search")
        (span (:class "list-search-prompt") "Search:")
        (input (:type "text" :id "post-search" :class "list-search-input"
                :placeholder "search… #emacs  (/ to focus, Esc to clear)"
                :autocomplete "off" :autocapitalize "off" :spellcheck "false"))
        (span (:id "search-count" :class "list-search-count")))
  "The search box markup; filtering behavior comes from
`theme--post-listing-search-script'.")


(defconst theme--post-listing-search-script
  (list 'raw-html nil
        "<script>
(function () {
  'use strict';
  var inp = document.getElementById('post-search');
  var count = document.getElementById('search-count');
  if (!inp) return;

  function run(raw) {
    var q = raw.toLowerCase().trim();
    var tag = q.charAt(0) === '#' ? q.slice(1) : null;
    var n = 0;

    document
      .querySelectorAll('#article-list .article-item[data-title]')
      .forEach(function (el) {
        var ok;
        if (!q) {
          ok = true;
        } else if (tag !== null) {
          ok = tag.length > 0 && (el.dataset.tags || '').indexOf(tag) !== -1;
        } else {
          ok =
            (el.dataset.title || '').indexOf(q) !== -1 ||
            (el.dataset.tags || '').indexOf(q) !== -1;
        }
        el.style.display = ok ? '' : 'none';
        if (ok) n++;
      });

    document
      .querySelectorAll('#article-list .year-divider[data-year-sep]')
      .forEach(function (d) {
        var sel =
          '#article-list .article-item[data-year=\"' +
          d.dataset.yearSep +
          '\"]:not([style*=\"none\"])';
        d.style.display = document.querySelector(sel) ? '' : 'none';
      });

    count.textContent = q ? n + ' match' + (n !== 1 ? 'es' : '') : '';
  }

  inp.addEventListener('input', function () {
    run(this.value);
  });

  document.querySelectorAll('.tag-cloud-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var tag = '#' + this.dataset.tag;
      var active = this.classList.contains('active');
      document.querySelectorAll('.tag-cloud-btn').forEach(function (b) {
        b.classList.remove('active');
      });
      if (active) {
        inp.value = '';
        run('');
      } else {
        this.classList.add('active');
        inp.value = tag;
        run(tag);
      }
      inp.focus();
    });
  });

  document.addEventListener('keydown', function (e) {
    if (
      e.key === '/' &&
      document.activeElement !== inp &&
      document.activeElement.tagName !== 'INPUT' &&
      document.activeElement.tagName !== 'TEXTAREA'
    ) {
      e.preventDefault();
      inp.focus();
      inp.select();
    }
    if (e.key === 'Escape' && document.activeElement === inp) {
      inp.value = '';
      run('');
      inp.blur();
    }
  });
})();
</script>")
  "Post-listing page's search-filter and tag-cloud-button script, ported
verbatim from list-search-js.html.")


(cl-defun theme-post-listing (&key list-header term-header tag-cloud article-list footer modeline)
  "Assemble the listing section around ARTICLE-LIST, with optional
LIST-HEADER, TERM-HEADER, or TAG-CLOUD."
  (let* ((list-content
          (append
           (list 'div '(:class "list-content"))
           (when list-header (list (list 'div '(:class "list-header") list-header)))
           (when term-header (list term-header))
           (when tag-cloud (list tag-cloud))
           (list theme--list-search-box article-list theme--post-listing-search-script)
           (list (append (list 'footer '(:class "list-footer")) (when footer (list footer))))))
         (buffer-body (list 'div '(:class "buffer-body") list-content)))
    (append
     (list 'section '(:class "buffer buffer-list active" :id "buffer-list"
                      :role "region" :aria-label "list")
           buffer-body)
     (when modeline (list modeline)))))

(defun theme--sitemap-item (page tag-icons)
  "One <li> for PAGE in the sitemap listing: icon and title only, no date or
tags."
  (list 'li '(:class "article-item")
        (list 'a (list :href (concat "/" (plist-get page :url)) :class "article-link")
              (list 'span '(:class "article-type-icon nf" :aria-hidden "true")
                    (theme--tag-icon (plist-get page :tags) tag-icons))
              (list 'span '(:class "article-title") (plist-get page :title)))))

(defun theme--sitemap-group-label (label count)
  "One year-divider <li> labeled LABEL, with a COUNT badge span if COUNT is
non-nil."
  (list 'li '(:class "year-divider")
        (append (list 'span '(:class "year-label") label)
                (when count (list (list 'span '(:class "year-count") (format "(%d)" count)))))))

(cl-defun theme-sitemap-page (&key title body-html groups tag-icons footer modeline)
  "The sitemap page: header, body, then every GROUPS bucket as a year-divider
run, tagged via TAG-ICONS."
  (append
   (list 'section (list :class "buffer buffer-content active" :id "buffer-content"
                         :role "region" :aria-label title)
         (list 'div '(:class "buffer-body" :id "content-body")
               (list 'article '(:class "post-content" :id "article-content")
                     (list 'div '(:class "post-header") (list 'h1 '(:class "post-title") title))
                     (list 'div '(:class "post-body") (list 'raw-html nil body-html))
                     (append
                      (list 'ul '(:class "article-list is-grid" :role "list"))
                      (mapcan (lambda (group)
                                (cons (theme--sitemap-group-label (plist-get group :label) (plist-get group :count))
                                      (mapcar (lambda (p) (theme--sitemap-item p tag-icons)) (plist-get group :pages))))
                              groups)))
               (append (list 'footer nil) (when footer (list footer)))))
   (when modeline (list modeline))))

;;;; Topic-list pages (wander, projects, media, quotes, uses)
;;
;; Refs backlinks resolve against this build's own page metadata
;; (denden-pages-with-ref), not a separate /refs/ taxonomy page.

(defun theme--topic-part-chip (part tag-icons all-pages)
  "One metadata chip for PART, a \"key: value\" string; a \"refs:\" value
links to /refs/ only if ALL-PAGES has a match."
  (ignore tag-icons)
  (let* ((colon (string-match ":" part))
         (key (if colon (string-trim (substring part 0 colon)) part))
         (value (if colon (string-trim (substring part (1+ colon))) "")))
    (cond
     ((string-empty-p value) nil)
     ((equal key "tag")
      (list 'a (list :href (format "/tags/%s/" (downcase value)) :class "project-tag"
                      :title (format "check posts tagged as %s" value))
            value))
     ((equal key "refs")
      (if (and all-pages (denden-pages-with-ref all-pages value))
          (list 'a (list :href (format "/refs/%s/" (downcase value)) :class "project-tag"
                          :title (format "check posts referencing %s" value))
                value)
        (list 'span (list :class "project-tag" :title (format "site references %s" value)) value)))
     ((string-prefix-p "http" value)
      (list 'a (list :href value :class "project-tag" :target "_blank" :rel "noopener" :aria-label key)
            (concat key " ↗")))
     (t (list 'span '(:class "project-tag") (format "%s: " key)
              (list 'raw-html nil (denden-export-org-fragment value)))))))

(defun theme--topic-refs-backlinks (item all-pages)
  "The [1] [2] backlink chips for ITEM's \"refs:\" part, linking to ALL-PAGES
that share that ref."
  (let ((ref (cl-some (lambda (p) (and (string-prefix-p "refs:" p) (string-trim (substring p 5))))
                      (plist-get item :parts))))
    (when ref
      (let ((pages (denden-pages-with-ref all-pages ref)))
        (when pages
          (append
           (list 'span '(:class "project-refs" :aria-label "related posts"))
           (let ((i 0))
             (mapcar (lambda (p)
                       (setq i (1+ i))
                       (list 'a (list :href (concat "/" (plist-get p :url)) :class "project-ref-link"
                                      :title (plist-get p :title))
                             (format "[%d]" i)))
                     pages))))))))

(cl-defun theme-topic-item (&key item icon chip-color all-pages tag-icons)
  "One topic-list <li> for ITEM, a `denden-parse-topic-item' plist, using
ICON, CHIP-COLOR and ALL-PAGES."
  (let* ((chips (delq nil (mapcar (lambda (p) (theme--topic-part-chip p tag-icons all-pages)) (plist-get item :parts))))
         (refs-node (theme--topic-refs-backlinks item all-pages))
         (url (plist-get item :url))
         ;; A term with no [[link]] at all parses to "" (denden--item-link),
         ;; and only its truthiness is checked, not string content -- so a
         ;; placeholder like "." (a non-empty string) still renders as a
         ;; real, if odd, self-referencing <a href=".">.
         (has-url (and url (not (string-empty-p url))))
         (name (plist-get item :name)))
    (list 'li (list :class "article-item topic-item"
                     :data-url (and has-url url) :data-external (and has-url "true")
                     :data-title (downcase (concat name " "
                                                    (replace-regexp-in-string "<[^>]+>" "" (plist-get item :desc))
                                                    " " (mapconcat #'identity (plist-get item :parts) " ")))
                     :style (if chip-color (format "--chip-color: var(--%s)" chip-color) ""))
          (list 'div '(:class "project-left") (list 'span '(:class "project-icon nf" :aria-hidden "true") icon))
          (append
           (list 'div '(:class "article-link"))
           (list
            (append
             (list 'div '(:class "project-header"))
             (list (if has-url
                       (list 'a (list :href url :class "article-title project-name" :target "_blank" :rel "noopener")
                             name)
                     (list 'span '(:class "article-title project-name") name)))
             (when refs-node (list refs-node))))
           (when (not (string-empty-p (plist-get item :desc)))
             (list (list 'span '(:class "wander-desc") (list 'raw-html nil (plist-get item :desc)))))
           (when chips (list (append (list 'span '(:class "project-tags" :aria-label "metadata")) chips)))))))

(defun theme--topic-group-divider (label count)
  "One year-divider <li> for a topic-list group, LABEL plus item COUNT."
  (list 'li '(:class "year-divider")
        (list 'span nil label (list 'span '(:class "year-count") (format "(%d)" count)))))

(defun theme--topic-item-tags (item)
  "The bare tag values (no \"tag:\" prefix) among ITEM's :parts."
  (delq nil (mapcar (lambda (p) (and (string-prefix-p "tag:" p) (string-trim (substring p 4))))
                    (plist-get item :parts))))

(defun theme--topic-group-items (group tag-icons chip-color all-pages)
  "The rendered <li> items for one GROUP, group icon falling back per item."
  (let ((label (plist-get group :label)))
    (mapcar
     (lambda (item)
       ;; Item-level "tag:" parts win over the group label's own icon,
       ;; which is only the fallback.
       (let ((icon (theme--tag-icon (append (theme--topic-item-tags item) (list (downcase label))) tag-icons)))
         (theme-topic-item :item item :icon icon :chip-color chip-color :all-pages all-pages)))
     (plist-get group :items))))

(defun theme-topic-list-items (&rest args)
  "The full <ul>: one year-divider header per group plus its items, from
ARGS's :groups and friends."
  (let ((groups (plist-get args :groups))
        (tag-icons (plist-get args :tag-icons))
        (chip-color (plist-get args :chip-color))
        (all-pages (plist-get args :all-pages)))
    (append
     (list 'ul '(:class "article-list wander-list" :id "article-list" :role "list"))
     (mapcan
      (lambda (group)
        (cons (theme--topic-group-divider (plist-get group :label) (length (plist-get group :items)))
              (theme--topic-group-items group tag-icons chip-color all-pages)))
      groups))))

(cl-defun theme--list-search (&key placeholder count-text)
  "The search box and list/grid view-toggle shared by topic-list and the
themes gallery."
  (list 'div '(:class "list-search" :role "search")
        '(span (:class "list-search-prompt") "Search:")
        (list 'input (list :type "text" :id "topic-search" :class "list-search-input"
                           :placeholder placeholder :autocomplete "off"
                           :autocapitalize "off" :spellcheck "false"))
        (list 'span (list :id "topic-count" :class "list-search-count") (or count-text ""))
        '(input (:type "checkbox" :id "view-toggle" :class "view-toggle-input"
                 :aria-label "Toggle list / grid view" :title "Toggle list / grid view"))
        '(label (:for "view-toggle" :class "tag-cloud-btn")
                (span (:class "nf" :aria-hidden "true") "󰕰 "))))

(defconst theme--topic-list-search-script
  (list 'raw-html nil
        "<script>
(function () {
  'use strict';
  var list = document.getElementById('article-list');
  if (!list) return;

  var vbox = document.getElementById('view-toggle');
  if (vbox) {
    var VIEW_KEY = 'topic-view';
    vbox.checked = localStorage.getItem(VIEW_KEY) === 'grid';
    vbox.addEventListener('change', function () {
      localStorage.setItem(VIEW_KEY, vbox.checked ? 'grid' : 'list');
    });
  }

  function groupItems(divider) {
    var items = [];
    var el = divider.nextElementSibling;
    while (el && !el.classList.contains('year-divider')) {
      if (el.classList.contains('article-item')) items.push(el);
      el = el.nextElementSibling;
    }
    return items;
  }

  var inp = document.getElementById('topic-search');
  var count = document.getElementById('topic-count');
  if (!inp) return;

  function run(raw) {
    var q = raw.toLowerCase().trim();
    var tokens = q ? q.split(/\\s+/) : [];
    var n = 0;

    list.querySelectorAll('.topic-item[data-title]').forEach(function (el) {
      var hay = el.dataset.title || '';
      var ok =
        !q ||
        tokens.every(function (t) {
          return hay.indexOf(t) !== -1;
        });
      el.dataset.searchHidden = ok ? '' : '1';
      el.style.display = q ? (ok ? '' : 'none') : '';
      if (ok) n++;
    });

    list.querySelectorAll('.year-divider').forEach(function (div) {
      var hasVisible = groupItems(div).some(function (el) {
        return el.style.display !== 'none';
      });
      div.style.display = hasVisible ? '' : 'none';
    });

    if (count)
      count.textContent = q ? n + ' match' + (n !== 1 ? 'es' : '') : '';
  }

  inp.addEventListener('input', function () {
    run(this.value);
  });

  document.addEventListener('keydown', function (e) {
    if (
      e.key === '/' &&
      document.activeElement !== inp &&
      document.activeElement.tagName !== 'INPUT' &&
      document.activeElement.tagName !== 'TEXTAREA'
    ) {
      e.preventDefault();
      inp.focus();
      inp.select();
    }
    if (e.key === 'Escape' && document.activeElement === inp) {
      inp.value = '';
      run('');
      inp.blur();
    }
  });
})();
</script>")
  "Topic-list page's search-filter and view-toggle-persistence script, ported
verbatim from topic-list-js.html.")


(defconst theme--wander-launch-button
  '(div (:class "wander-launch")
        (a (:href "/wander/console/" :class "wander-btn")
           (span (:class "nf" :aria-hidden "true") " ")
           " Launch Wander Console")
        (span (:class "wander-hint") "browse random sites from this network")))

(defun theme-topic-list-page (&rest args)
  "Assemble a topic-list page from ARGS: title, date, intro prose, optional
Wander launch link, items, footer."
  (let* ((title (plist-get args :title))
         (date (plist-get args :date))
         (intro-html (plist-get args :intro-html))
         (show-console (plist-get args :show-console))
         (items-node (plist-get args :items-node))
         (footer (plist-get args :footer))
         (modeline (plist-get args :modeline))
         (post-header (list 'div '(:class "post-header") (list 'h1 '(:class "post-title") title)))
         (date-node (and date (list 'div '(:class "post-meta") (list 'time (list :datetime date) date))))
         (intro-node (and intro-html (not (string-empty-p intro-html))
                          (list 'div '(:class "post-body") (list 'raw-html nil intro-html))))
         (search-node (theme--list-search :placeholder "filter… (/ to focus, Esc to clear)"))
         (article-children (delq nil (list post-header date-node intro-node
                                            (and show-console theme--wander-launch-button)
                                            search-node items-node
                                            theme--topic-list-search-script)))
         (article (append (list 'article '(:class "post-content" :id "article-content")) article-children))
         (footer-node (append (list 'footer nil) (and footer (list footer))))
         (buffer-body (list 'div '(:class "buffer-body" :id "content-body") article footer-node))
         (section-children (delq nil (list buffer-body modeline))))
    (append (list 'section '(:class "buffer buffer-content active" :id "buffer-content"
                             :role "region" :aria-label title))
            section-children)))

;;;; /themes/ gallery

(defun theme--scheme-card (scheme)
  "One <li> scheme card for SCHEME (a `site-all-schemes' entry: :key :name
:author-name :author-url :variant :colors)."
  (let* ((name (plist-get scheme :name))
         (author-name (plist-get scheme :author-name))
         (author-url (plist-get scheme :author-url))
         (variant (plist-get scheme :variant))
         (colors (plist-get scheme :colors))
         (search-text (downcase (concat name " " author-name))))
    (list 'li (list :class "article-item topic-item scheme-card" :data-title search-text)
          (append
           (list 'button (list :class "scheme-card-btn" :data-key (plist-get scheme :key)
                                :data-name name :data-colors (json-serialize (vconcat colors))))
           (list (append (list 'span '(:class "scheme-card-head"))
                         (list (list 'span '(:class "scheme-card-name") name))
                         (when (and variant (not (string-empty-p variant)))
                           (list (list 'span '(:class "scheme-card-variant") variant)))))
           (list (append (list 'span '(:class "scheme-card-swatches" :aria-hidden "true"))
                         (mapcar (lambda (c) (list 'span (list :class "swatch" :style (format "background:%s" c))))
                                 colors))))
          (if (and author-url (not (string-empty-p author-url)))
              (list 'a (list :href author-url :class "scheme-card-author" :target "_blank" :rel "noopener")
                    author-name)
            (list 'span '(:class "scheme-card-author") author-name)))))

(cl-defun theme-themes-gallery-page (&key title body-html cards footer modeline)
  "Assemble the /themes/ gallery page titled TITLE, one scheme-card per CARDS.
Also BODY-HTML as the page's own intro prose, the search box +
view-toggle (an upfront \"N schemes\" count, matching the Hugo
partial), FOOTER, MODELINE."
  (let* ((post-header (list 'div '(:class "post-header") (list 'h1 '(:class "post-title") title)))
         (body-node (and body-html (not (string-empty-p body-html))
                         (list 'div '(:class "post-body") (list 'raw-html nil body-html))))
         (search-node (theme--list-search :placeholder "filter by name or author… (/ to focus, Esc to clear)"
                                           :count-text (format "%d schemes" (length cards))))
         (list-node (append (list 'ul '(:class "article-list" :id "article-list" :role "list"))
                             (mapcar #'theme--scheme-card cards)))
         (article-children (delq nil (list post-header body-node search-node list-node)))
         (article (append (list 'article '(:class "post-content" :id "article-content")) article-children))
         (footer-node (append (list 'footer nil) (and footer (list footer))))
         (buffer-body (list 'div '(:class "buffer-body" :id "content-body") article footer-node))
         (section-children (delq nil (list buffer-body modeline))))
    (append (list 'section '(:class "buffer buffer-content active" :id "buffer-content"
                             :role "region" :aria-label title))
            section-children)))

(provide 'theme)
;;; theme.el ends here
