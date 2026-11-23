;;; theme.el --- sexp-HTML templates for the site theme -*- lexical-binding: t; -*-

;;; Commentary:

;; Templates (sexp-HTML) for the page shell, single-post pages, listing
;; pages and topic-list pages. Generic templates only -- no site config
;; data lives here; the site layer (site.el) supplies it.
;;
;; The markup is plain semantic HTML: body > header (site name, nav,
;; Search button), main, body > footer. Every list on the site is one
;; primitive, a <ul class="list"> of rows, grouped by <section>s with an
;; <h2> each. Rows carry data-filter-text, which the one shared list
;; filter in index.js reads. Controls that only work with JS (the Search
;; button, the scheme and font selects) render with the hidden attribute
;; and index.js reveals them.

;;; Code:

(require 'cl-lib)
(require 'rx)
(require 'url-parse)
(require 'denden)

(defun theme--url-domain (url)
  "Return URL's bare domain, e.g. \"example.com\" from \"https://example.com/x\"."
  (replace-regexp-in-string
   (rx "/" (* nonl) eos) ""
   (replace-regexp-in-string (rx bos "http" (opt "s") "://" (opt "www.")) "" url)))

(defun theme--tag-icon (tags tag-icons)
  "Return the first of TAGS with an entry in TAG-ICONS, else \"_default\", else \"\"."
  (or (cl-some (lambda (tag) (cdr (assoc (downcase tag) tag-icons))) tags)
      (cdr (assoc "_default" tag-icons))
      ""))

(defun theme--icon (glyph)
  "A decorative Nerd Font GLYPH span, hidden from screen readers."
  (list 'span '(:class "nf" :aria-hidden "true") glyph))

(defun theme--heading-at (tag id &rest content)
  "A TAG heading (h2, h3) with ID holding CONTENT, followed by a # link to itself."
  (append (list tag (list :id id)) content
          (list (list 'a (list :class "heading-anchor" :href (concat "#" id) :aria-label "Link to this section")
                      "#"))))

(defun theme--heading (id &rest content)
  "An <h2> with ID holding CONTENT, followed by a # link to itself."
  (apply #'theme--heading-at 'h2 id content))

(defun theme--tag-links (tags)
  "One #tag link per TAGS entry, separated by spaces."
  (cdr (mapcan (lambda (tag)
                 (list " " (list 'a (list :href (format "/tags/%s/" (downcase tag))) (concat "#" tag))))
               tags)))

(defun theme--filter-text (&rest parts)
  "Join PARTS (strings or string lists) into one lowercased data-filter-text value."
  (downcase (string-join (flatten-list parts) " ")))

(defconst theme--list-views '(("list" "󰕲" "List") ("grid" "󰕰" "Grid"))
  "The list layouts a reader can pick, default first: value, icon, name.")

(cl-defun theme-list-filter (&key target placeholder (views t))
  "A filter for rows in element id TARGET, with PLACEHOLDER, and VIEWS radios."
  (append
   (list 'div '(:class "list-controls" :hidden t :data-requires-js t)
         (list 'input (list :type "search" :data-filter target :aria-label "Filter this list"
                            :placeholder (or placeholder "filter… (/ to focus, Esc to clear)")
                            :autocomplete "off" :spellcheck "false"))
         '(output (:aria-live "polite")))
   (when views
     (list (append (list 'fieldset '(:class "views") '(legend (:class "visually-hidden") "View"))
                   (mapcar (lambda (view)
                             (list 'label (list :title (nth 2 view))
                                   (list 'input (list :type "radio" :name "list-view" :value (car view)
                                                      :aria-label (nth 2 view)
                                                      :checked (and (equal (car view) "list") t)))
                                   (theme--icon (nth 1 view))))
                           theme--list-views))))))

;;;; Page shell: header, footer, palette dialog

(defun theme--nav-list (items)
  "A <ul> of links for ITEMS, (:name :url) plists."
  (append (list 'ul nil)
          (mapcar (lambda (item) (list 'li nil (list 'a (list :href (plist-get item :url)) (plist-get item :name))))
                  items)))

(defun theme--tool-button (action label glyph &rest extra-glyphs)
  "An icon button for ACTION named LABEL, showing GLYPH and EXTRA-GLYPHS."
  (append (list 'button (list :type "button" :data-action action :aria-label label :title label)
                (list 'span '(:class "nf" :aria-hidden "true") glyph))
          extra-glyphs))

(cl-defun theme-header (&key site-title title-quotes menu-items)
  "The header: SITE-TITLE with TITLE-QUOTES, a MENU-ITEMS row and a toolbar row."
  (list 'header nil
        (list 'a (list :href "/" :class "site-title"
                       :title (and title-quotes (seq-random-elt title-quotes))
                       :data-quotes (and title-quotes
                                         ;; json-serialize returns UTF-8 bytes; decode them, or any
                                         ;; non-ASCII quote turns into raw bytes the page cannot save.
                                         (decode-coding-string (json-serialize (vconcat title-quotes)) 'utf-8)))
              site-title)
        (list 'div nil
              (list 'nav '(:aria-label "Site") (theme--nav-list menu-items))
              (list 'p '(:class "toolbar" :hidden t :data-requires-js t)
                    (theme--tool-button "cycle-width" "Content width" "󰭣")
                    (theme--tool-button "cycle-font" "Font mode" "")
                    (theme--tool-button "open-schemes" "Color scheme" "")
                    (theme--tool-button "toggle-theme" "Dark or light" ""
                                        '(span (:class "nf" :aria-hidden "true") ""))
                    (theme--tool-button "random-page" "Random page" "")
                    '(button (:type "button" :data-action "open-palette" :aria-keyshortcuts "x"
                                    :title "Search and commands (x)")
                             "M-x " (span (:class "nf" :aria-hidden "true") "󰠳"))
                    '(output (:class "toast" :popover "manual" :role "status"))))))

(defun theme--social-link (link)
  "An <a> for social LINK; external links open in a new tab."
  (let* ((url (plist-get link :url))
         (extra-rel (plist-get link :rel))
         (rel (if extra-rel (format "noopener noreferrer %s" extra-rel) "noopener noreferrer"))
         (external (not (string-prefix-p "mailto:" url))))
    (list 'a (list :href url :target (and external "_blank") :rel (and external rel))
          (theme--icon (string-trim (plist-get link :icon)))
          " " (plist-get link :label))))

(defun theme-social-links-grid (links)
  "LINKS as a list of rows, for body content such as the About page."
  (append (list 'ul '(:class "list"))
          (mapcar (lambda (link) (list 'li nil (theme--social-link link))) links)))

(cl-defun theme-footer (&key links footer-content)
  "The footer: every page in LINKS, then FOOTER-CONTENT."
  (append
   (list 'footer nil)
   (when links (list (list 'nav '(:id "all-pages" :aria-label "All pages") (theme--nav-list links))))
   (when footer-content (list footer-content))))

(defconst theme-palette-dialog
  '(dialog (:id "palette-dialog" :aria-label "Command palette")
           (input (:type "text" :id "palette-input" :class "palette-input"
                         :placeholder "Search posts, pages and commands…" :autocomplete "off"
                         :autocapitalize "off" :spellcheck "false"))
           (div (:id "palette-results" :role "listbox")))
  "The command palette dialog, a native <dialog> element.")

(cl-defun theme-badge (&key name logo color link subtitle tooltip)
  "A badge link to LINK for NAME with LOGO, SUBTITLE, COLOR and TOOLTIP."
  (let ((tooltip (or tooltip (and subtitle name (format "%s %s" subtitle name)) subtitle name "")))
    (append
     (list 'a (list :href (or link "#") :class "badge" :title tooltip
                    :style (and color (format "--glow:%s" color))))
     (list (list 'img (list :src logo :alt (or name "") :loading "lazy")))
     (when subtitle (list (list 'span '(:class "badge-subtitle") subtitle)))
     (when name (list (list 'span (list :class "badge-name" :style (and color (format "background:%s" color)))
                            name))))))

(defconst theme--base16-keys
  ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07"
   "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"]
  "The 16 base16 custom-property names, in order, as in index.js.")

(defun theme--pre-paint-script (schemes-url light-schemes)
  "Apply stored choices before paint; light only if stored and in LIGHT-SCHEMES."
  (list 'raw-html nil
        (format "<script>
window.__schemesUrl=%s;
(function(){
var r=document.documentElement,s=localStorage,k=%s,light=%s;
var cp=s.getItem('emacs-custom-palette');
if(cp){try{JSON.parse(cp).colors.forEach(function(c,i){if(c)r.style.setProperty('--'+k[i],c);});}catch(e){}}
else{var x=s.getItem('emacs-scheme-fixed');if(x!==null){if(x)r.setAttribute('data-scheme',x);else r.removeAttribute('data-scheme');}}
window.__applyVariant=function(){
var t=s.getItem('emacs-theme')||'dark';
var p=s.getItem('emacs-custom-palette');
if(p){try{t=JSON.parse(p).variant||t;}catch(e){}}
else if(t==='light'&&light.indexOf(r.getAttribute('data-scheme')||'')<0)t='dark';
r.setAttribute('data-theme',t);};
window.__applyVariant();
var f=s.getItem('emacs-font-mode');if(f)r.setAttribute('data-font',f);
var w=s.getItem('emacs-width');if(w)r.style.setProperty('--measure',w);
})();
</script>"
                (json-serialize schemes-url) (json-serialize theme--base16-keys)
                (json-serialize (vconcat light-schemes)))))

(defconst theme-color-meta-value "#0a0f0a"
  "The theme-color meta value: a fixed browser-chrome tint.")

(cl-defun theme--seo-head-nodes (&key og-title description canonical-url favicon-href favicon-type
                                      og-type og-image published-time modified-time tags site-title
                                      author-name language noindex fediverse-creator rss-url)
  "The page's SEO <head> children: meta, canonical, OG, RSS and JSON-LD."
  (let ((og-title (or og-title site-title)))
    (append
     (when description (list (list 'meta (list :name "description" :content description))))
     (when noindex (list '(meta (:name "robots" :content "noindex"))))
     (when fediverse-creator
       (list (list 'meta (list :name "fediverse:creator" :content fediverse-creator))
             (list 'meta (list :property "fediverse:creator" :content fediverse-creator))))
     (when canonical-url (list (list 'link (list :rel "canonical" :href canonical-url))))
     (when favicon-href (list (list 'link (list :rel "icon" :type favicon-type :href favicon-href))))
     (when rss-url
       (list (list 'link (list :rel "alternate" :type "application/rss+xml"
                               :title (format "%s RSS feed" og-title) :href rss-url))))
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
  "The Umami loader for SCRIPT-URL and WEBSITE-ID, or nil without both."
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
function idle(){
if('requestIdleCallback' in window) requestIdleCallback(loadUmami);
else setTimeout(loadUmami,2000);
}
if(document.prerendering) document.addEventListener('prerenderingchange',idle,{once:true});
else idle();
})();
</script>" (json-serialize script-url) (json-serialize website-id)))))

(defconst theme--speculation-rules
  (list 'script '(:type "speculationrules")
        (list 'raw-html nil
              (json-serialize
               '((prerender . [((where . ((and . [((href_matches . "/*"))
                                                  ((not . ((href_matches . "/*.xml"))))
                                                  ((not . ((selector_matches . "[target=_blank], [download]"))))])))
                                (eagerness . "moderate"))])))))
  "Speculation rules: prerender a same-site link the pointer rests on.")

(cl-defun theme-baseof (&key language body palette-data-script stylesheet-href script-href page-title
                             og-title menu-items site-title rss-url
                             schemes-url description canonical-url favicon-href favicon-type og-type
                             og-image published-time modified-time tags author-name noindex
                             fediverse-creator analytics-script-url analytics-website-id footer-content
                             footer-links title-quotes light-schemes preload-fonts touch-icon-href)
  "The page skeleton for LANGUAGE and BODY, as a single <html> node.
PALETTE-DATA-SCRIPT must be a `(raw-html nil STRING)' node."
  (list 'html (list :lang language :data-theme "dark" :data-scheme "haki" :data-font "mixed")
        (append (list 'head nil '(meta (:charset "utf-8")))
                (when schemes-url (list (theme--pre-paint-script schemes-url light-schemes)))
                (list '(meta (:name "viewport" :content "width=device-width, initial-scale=1.0"))
                      '(meta (:name "color-scheme" :content "dark"))
                      '(meta (:name "darkreader-lock"))
                      (list 'meta (list :name "theme-color" :content theme-color-meta-value)))
                (when page-title (list (list 'title nil page-title)))
                (mapcar (lambda (href)
                          (list 'link (list :rel "preload" :href href :as "font"
                                            :type "font/woff2" :crossorigin "anonymous")))
                        preload-fonts)
                (when analytics-script-url
                  (let ((url (url-generic-parse-url analytics-script-url)))
                    (list (list 'link (list :rel "dns-prefetch"
                                            :href (format "//%s" (url-host url)))))))
                (when touch-icon-href
                  (list (list 'link (list :rel "apple-touch-icon" :href touch-icon-href))))
                (theme--seo-head-nodes :og-title og-title :description description
                                       :canonical-url canonical-url :favicon-href favicon-href
                                       :favicon-type favicon-type :og-type og-type :og-image og-image
                                       :published-time published-time :modified-time modified-time
                                       :tags tags :site-title site-title :author-name author-name
                                       :language language :noindex noindex
                                       :fediverse-creator fediverse-creator :rss-url rss-url)
                (when stylesheet-href (list (list 'link (list :rel "stylesheet" :href stylesheet-href))))
                (when script-href (list (list 'script (list :src script-href :defer "defer"))))
                (list theme--speculation-rules)
                (let ((analytics (theme--analytics-script analytics-script-url analytics-website-id)))
                  (when analytics (list analytics))))
        (append
         (list 'body nil
               '(a (:class "skip-link" :href "#main") "Skip to content")
               (theme-header :site-title site-title :title-quotes title-quotes :menu-items menu-items)
               (list 'main '(:id "main") body)
               (theme-footer :links footer-links :footer-content footer-content)
               theme-palette-dialog)
         (when palette-data-script (list palette-data-script)))))

;;;; Single post/page

(cl-defun theme-post-header (&key title date lastmod wordcount readingtime tags)
  "The header for TITLE with one meta line: DATE, LASTMOD, time and TAGS."
  (list 'header nil
        (list 'h1 nil title)
        (append
         (list 'p nil)
         (when date (list (list 'time (list :datetime date) date)))
         (when (and lastmod date (not (equal lastmod date)))
           (list " · updated " (list 'time (list :datetime lastmod) lastmod)))
         (list (format "%s%s min read (%s words)" (if date " · " "") (or readingtime 0) (or wordcount 0)))
         (when tags (cons '(br nil) (theme--tag-links tags))))))

(defun theme-comment (email title)
  "A comment box that index.js mails to EMAIL about TITLE."
  (list 'form (list :class "comment" :data-email email :data-subject (format "Re: %s" title))
        '(label (:for "comment-text") "Leave a comment")
        '(textarea (:id "comment-text" :name "body" :rows "4" :placeholder "Write your thoughts…"))
        '(button (:type "submit") "Comment")
        '(small nil "Opens your email client. No public comments here.")))

(defun theme--reference-item (ref)
  "One <li> for REF, a (:href :label :internal) plist."
  (let ((href (plist-get ref :href))
        (label (plist-get ref :label)))
    (if (plist-get ref :internal)
        (list 'li nil (list 'a (list :href href) label))
      (append
       (list 'li nil (list 'a (list :href href :target "_blank" :rel "noopener noreferrer") (or label href)))
       (when (and label (not (equal label href)))
         (list " " (list 'small nil (theme--url-domain href))))))))

(defun theme--page-row (page &optional tag-icons marker)
  "One row for PAGE: date, MARKER or a TAG-ICONS icon, title and tags."
  (let ((url (concat "/" (plist-get page :url)))
        (date (plist-get page :date))
        (tags (plist-get page :tags)))
    (append
     (list 'li (list :data-filter-text (theme--filter-text (plist-get page :title)
                                                           (mapcar (lambda (tag) (concat "#" tag)) tags))))
     (when date (list (list 'time (list :datetime date) (denden-format-iso-date date "%d %b"))))
     (cond (marker (list (theme--icon marker) '(span (:class "visually-hidden") "Links here: ")))
           (tag-icons (list (theme--icon (theme--tag-icon tags tag-icons)))))
     (list (list 'a (list :href url) (plist-get page :title)))
     (when tags (list (append (list 'small nil) (theme--tag-links (seq-take tags 3))))))))

(cl-defun theme-references (&key refs backlinks related tag-icons (backlink-icon "<-"))
  "References (REFS), then See Also: BACKLINKS first, then RELATED pages."
  (append
   (when refs
     (list (list 'section '(:aria-labelledby "references-heading")
                 (theme--heading "references-heading" "References")
                 (append (list 'ol '(:class "list")) (mapcar #'theme--reference-item refs)))))
   (when (or backlinks related)
     (list (list 'section '(:aria-labelledby "related-heading")
                 (theme--heading "related-heading" "See Also")
                 (append (list 'ul '(:class "list"))
                         (mapcar (lambda (page) (theme--page-row page nil backlink-icon)) backlinks)
                         (mapcar (lambda (page) (theme--page-row page tag-icons)) related)))))))

(cl-defun theme-post-navigation (&key prev next)
  "Previous and next links; PREV and NEXT are (:title :url) plists or nil."
  (append
   (list 'nav '(:class "pager" :aria-label "Post navigation"))
   (when prev (list (list 'a (list :rel "prev" :href (concat "/" (plist-get prev :url)))
                          (concat "← " (truncate-string-to-width (plist-get prev :title) 40 nil nil " …")))))
   (when next (list (list 'a (list :rel "next" :href (concat "/" (plist-get next :url)))
                          (concat (truncate-string-to-width (plist-get next :title) 40 nil nil " …") " →"))))))

(cl-defun theme-single-page (&key post-header toc body-html references comment post-navigation)
  "One article from POST-HEADER, BODY-HTML and the optional rest."
  (append
   (list 'article nil post-header)
   (when toc (list toc))
   (list (list 'raw-html nil body-html))
   references
   (when comment (list comment))
   (when post-navigation (list post-navigation))))

(cl-defun theme-home-page (&key title body-html)
  "The home page: TITLE and BODY-HTML."
  (list 'article nil
        (list 'header nil (list 'h1 nil title))
        (list 'raw-html nil body-html)))

(defun theme--pose-entry (entry &optional open)
  "One Pose ENTRY: \"date day :: title\", its body below, OPEN or folded."
  (let* ((date (plist-get entry :date))
         (heading (apply #'theme--heading-at 'h3 (plist-get entry :id)
                         (append (when date
                                   (list (list 'time (list :datetime date) date) " "
                                         (list 'span (list :class "day" :title (plist-get entry :day-title))
                                               (plist-get entry :day))
                                         " :: "))
                                 (list (plist-get entry :title)))))
         (body (plist-get entry :html)))
    (list 'article (list :data-filter-text (plist-get entry :search-text)
                         :data-day (plist-get entry :weekday))
          (if (string-empty-p (string-trim body))
              heading
            (list 'details (list :open open) (list 'summary nil heading) (list 'raw-html nil body))))))

(cl-defun theme-pose-page (&key title intro-html weeks)
  "The Pose page: TITLE, INTRO-HTML, a filter and one section per WEEKS group."
  (let ((count (apply #'+ (mapcar (lambda (week) (length (plist-get week :entries))) weeks)))
        (first-entry t))
    (append
     (list 'article nil (list 'header nil (list 'h1 nil title)))
     (unless (or (null intro-html) (string-empty-p intro-html))
       (list (list 'raw-html nil intro-html)))
     (list (theme-list-filter :target "pose-entries" :views nil
                              :placeholder (format "search %d entries… (/ to focus, Esc to clear)" count))
           (append (list 'div '(:id "pose-entries"))
                   (mapcar (lambda (week)
                             (append (list 'section nil
                                           (theme--heading (plist-get week :id) (plist-get week :label)))
                                     ;; Weeks and entries are newest first; the newest entry starts open.
                                     (mapcar (lambda (entry)
                                               (prog1 (theme--pose-entry entry first-entry)
                                                 (setq first-entry nil)))
                                             (plist-get week :entries))))
                           weeks))))))

;;;; Listing pages

(cl-defun theme-article-list (&key grouped-pages tag-icons)
  "One section per year of GROUPED-PAGES, each a list of rows iconed by TAG-ICONS."
  (append
   (list 'div '(:id "article-list"))
   (if (null grouped-pages)
       (list '(p nil "No articles found."))
     (mapcar (lambda (group)
               (list 'section nil
                     (theme--heading (car group) (car group))
                     (append (list 'ul '(:class "list"))
                             (mapcar (lambda (page) (theme--page-row page tag-icons)) (cdr group)))))
             grouped-pages))))

(cl-defun theme-terms-list (&key title tag-counts (base-url "/tags/"))
  "The TITLE page listing TAG-COUNTS terms in order, linked under BASE-URL."
  (let ((sorted (sort (copy-sequence tag-counts)
                      (lambda (a b) (string< (plist-get a :tag) (plist-get b :tag))))))
    (append
     (list 'article nil (list 'header nil (list 'h1 nil title)))
     (if (null sorted)
         (list '(p nil "No tags found."))
       (list (theme-list-filter :target "terms-list")
             (append
              (list 'ul '(:class "list" :id "terms-list"))
              (mapcar (lambda (tc)
                        (let ((tag (plist-get tc :tag)) (count (plist-get tc :count)))
                          (list 'li (list :data-filter-text (downcase tag))
                                (list 'a (list :href (format "%s%s/" base-url (downcase tag))) (concat "#" tag))
                                (list 'small nil (format "%d %s" count (if (= count 1) "post" "posts"))))))
                      sorted)))))))

(cl-defun theme-term-header (&key count rss-url (back-url "/tags/"))
  "The term page's meta line: post COUNT, an RSS-URL link, a link back to BACK-URL."
  (append
   (list 'p nil (format "%d %s" count (if (= count 1) "post" "posts")))
   (when rss-url (list " · " (list 'a (list :href rss-url) "RSS feed")))
   (list " · " (list 'a (list :href back-url) "all tags"))))

(cl-defun theme-post-listing (&key title term-header article-list)
  "A listing page: TITLE, optional TERM-HEADER, a filter, then ARTICLE-LIST."
  (append
   (list 'article nil
         (append (list 'header nil (list 'h1 nil title)) (when term-header (list term-header))))
   (list (theme-list-filter :target "article-list"
                            :placeholder "filter… #emacs (/ to focus, Esc to clear)")
         article-list)))

;;;; Topic-list pages (wander, projects, media, quotes, uses)
;;
;; Refs backlinks resolve against this build's own page metadata
;; (denden-pages-with-ref), not a separate /refs/ taxonomy page.

(defun theme--topic-part-chip (part all-pages)
  "One chip for PART, a \"key: value\" string, checked against ALL-PAGES."
  (let* ((colon (string-search ":" part))
         (key (if colon (string-trim (substring part 0 colon)) part))
         (value (if colon (string-trim (substring part (1+ colon))) "")))
    (cond
     ((string-empty-p value) nil)
     ((equal key "tag")
      (list 'a (list :href (format "/tags/%s/" (downcase value))) (concat "#" value)))
     ((equal key "refs")
      (if (and all-pages (denden-pages-with-ref all-pages value))
          (list 'a (list :href (format "/refs/%s/" (downcase value))) (concat "@" value))
        (list 'span nil (concat "@" value))))
     ((string-prefix-p "http" value)
      (list 'a (list :href value :target "_blank" :rel "noopener") (concat key " ↗")))
     (t (list 'span nil (format "%s: " key) (list 'raw-html nil (denden-export-org-fragment value)))))))

(defun theme--topic-refs-backlinks (item all-pages)
  "The [1] [2] links to ALL-PAGES that share ITEM's \"refs:\" value."
  (let ((ref (cl-some (lambda (p) (and (string-prefix-p "refs:" p) (string-trim (substring p 5))))
                      (plist-get item :parts))))
    (when ref
      (let ((index 0))
        (mapcar (lambda (page)
                  (setq index (1+ index))
                  (list 'a (list :href (concat "/" (plist-get page :url)) :title (plist-get page :title))
                        (format "[%d]" index)))
                (denden-pages-with-ref all-pages ref))))))

(cl-defun theme-topic-item (&key item icon all-pages (external t))
  "One row for topic ITEM with ICON; EXTERNAL opens its link in a new tab."
  (let* ((chips (delq nil (mapcar (lambda (part) (theme--topic-part-chip part all-pages)) (plist-get item :parts))))
         (url (plist-get item :url))
         ;; A term with no [[link]] parses to "" (denden--item-link); only
         ;; its truthiness is checked, so "." still renders as a link.
         (has-url (and url (not (string-empty-p url))))
         (name (plist-get item :name))
         (desc (plist-get item :desc)))
    (append
     (list 'li (list :data-filter-text
                     (theme--filter-text name (replace-regexp-in-string (rx "<" (+ (not (any ">"))) ">") "" desc)
                                         (plist-get item :parts))))
     (when (and icon (not (string-empty-p icon))) (list (theme--icon icon)))
     (list (if has-url
               (list 'a (list :href url :target (and external "_blank") :rel (and external "noopener")) name)
             (list 'span nil name)))
     (theme--topic-refs-backlinks item all-pages)
     (when (not (string-empty-p desc)) (list (list 'p nil (list 'raw-html nil desc))))
     (when chips (list (append (list 'small nil) (cdr (mapcan (lambda (chip) (list " " chip)) chips))))))))

(defun theme--topic-item-tags (item)
  "The bare tag values (no \"tag:\" prefix) among ITEM's :parts."
  (delq nil (mapcar (lambda (p) (and (string-prefix-p "tag:" p) (string-trim (substring p 4))))
                    (plist-get item :parts))))

(defun theme-topic-list-items (&rest args)
  "One section per group from ARGS's :groups, each an h2 and a list of rows.
:tag-icons picks each row's icon, :chip-color names a base16 slot for the
chips, :all-pages resolves refs, and :external
\(default t) opens links in a new tab; pass nil for this site's own pages."
  (let ((groups (plist-get args :groups))
        (tag-icons (plist-get args :tag-icons))
        (all-pages (plist-get args :all-pages))
        (chip-color (plist-get args :chip-color))
        (external (if (plist-member args :external) (plist-get args :external) t)))
    (append
     (list 'div (list :id "topic-list" :style (and chip-color (format "--chip-color: var(--%s)" chip-color))))
     (mapcar
      (lambda (group)
        (let ((label (plist-get group :label))
              (items (plist-get group :items)))
          (list 'section nil
                (theme--heading (denden--slugify-heading-text label)
                                label " " (list 'small nil (format "(%d)" (length items))))
                (append
                 (list 'ul '(:class "list"))
                 (mapcar (lambda (item)
                           ;; Item-level "tag:" parts win over the group label's own icon.
                           (theme-topic-item
                            :item item :all-pages all-pages :external external
                            :icon (theme--tag-icon (append (theme--topic-item-tags item) (list (downcase label)))
                                                   tag-icons)))
                         items)))))
      groups))))

(defconst theme--wander-launch
  '(p nil (a (:href "/wander/console/" :class "wander-launch" :data-dialog "wander-dialog")
             "Wander the small web")
      " :: random sites from this network")
  "The Wander console link; with JS it opens `theme--wander-dialog' instead.")

(defconst theme--wander-dialog
  '(dialog (:id "wander-dialog" :aria-label "Wander console")
           (form (:method "dialog") (button (:type "submit") "Close"))
           (iframe (:title "Wander console" :data-src "/wander/console/")))
  "The Wander console in a dialog; index.js sets the iframe src on first open.")

(defun theme-topic-list-page (&rest args)
  "A topic-list page from ARGS (:title :date :intro-html :items-node ...)."
  (let ((title (plist-get args :title))
        (date (plist-get args :date))
        (intro-html (plist-get args :intro-html)))
    (append
     (list 'article nil
           (append (list 'header nil (list 'h1 nil title))
                   (when date (list (list 'p nil (list 'time (list :datetime date) date))))
                   (when (plist-get args :show-console) (list theme--wander-launch))))
     (when (and intro-html (not (string-empty-p intro-html))) (list (list 'raw-html nil intro-html)))
     (list (theme-list-filter :target "topic-list")
           (plist-get args :items-node))
     (when (plist-get args :show-console) (list theme--wander-dialog)))))

(provide 'theme)
;;; theme.el ends here
