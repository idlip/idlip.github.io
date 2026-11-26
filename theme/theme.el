;;; theme.el --- Templates of idlip.in -*- lexical-binding: t; -*-

;;; Commentary:

;; Templates for the page shell, single pages, listing pages and
;; topic-list pages of idlip.in.  Each template returns a node, a Lisp
;; list that `denden-serialize-node' turns into HTML.  No site data lives
;; here; site.el passes it in.
;;
;; The markup is plain semantic HTML: body > header (site name, nav,
;; toolbar), main, body > footer.  Every list on the site is one
;; primitive, a <ul class="list"> of rows, grouped by <section>s with an
;; <h2> each.  Rows carry data-filter-text, which the one shared list
;; filter in index.js reads.  Controls that only work with JS render with
;; the hidden attribute, and index.js reveals them.

;;; Code:

(require 'cl-lib)
(require 'rx)
(require 'url-parse)
(require 'denden)

(defun theme--url-domain (url)
  "Return the bare domain of URL, such as \"example.com\" from \"https://example.com/x\"."
  (replace-regexp-in-string
   (rx "/" (* nonl) eos) ""
   (replace-regexp-in-string (rx bos "http" (opt "s") "://" (opt "www.")) "" url)))

(defun theme-icon-for (text tag-icons)
  "Return the first non-empty glyph of TAG-ICONS whose key matches all of TEXT.
Each key of TAG-ICONS is a regexp."
  (cdr (seq-find (lambda (entry)
                   (and (not (string-empty-p (cdr entry)))
                        (string-match-p (rx-to-string `(seq bos (regexp ,(car entry)) eos) t) text)))
                 tag-icons)))

(defun theme--tag-icon (tags tag-icons)
  "Return the icon of the first of TAGS in TAG-ICONS, else \"_default\", else \"\"."
  (or (cl-some (lambda (tag) (theme-icon-for (downcase tag) tag-icons)) tags)
      (cdr (assoc "_default" tag-icons))
      ""))

(defun theme--icon (glyph)
  "Return a decorative Nerd Font GLYPH span, hidden from screen readers."
  `(span (:class "nf" :aria-hidden "true") ,glyph))

(defun theme--heading-at (tag id &rest content)
  "Return a TAG heading (h2, h3) with ID holding CONTENT, then a link to itself."
  `(,tag (:id ,id) ,@content
         (a (:class "heading-anchor" :href ,(concat "#" id) :aria-label ,denden-heading-anchor-label)
            ,denden-heading-anchor-text)))

(defun theme--heading (id &rest content)
  "Return an h2 with ID holding CONTENT, then a link to itself."
  (apply #'theme--heading-at 'h2 id content))

(defun theme--tags (page)
  "Return the tags of PAGE."
  (denden-page-taxonomy-terms page "tags"))

(defun theme--tag-links (tags)
  "Return one #tag link per entry of TAGS, separated by spaces."
  (cdr (mapcan (lambda (tag)
                 (list " " `(a (:href ,(format "/tags/%s/" (downcase tag))) ,(concat "#" tag))))
               tags)))

(defun theme--filter-text (&rest parts)
  "Join PARTS, strings or lists of strings, into one lowercase filter text."
  (downcase (string-join (flatten-list parts) " ")))

(defun theme--date (time format)
  "Return a time node showing TIME in FORMAT, a `format-time-string' format."
  `(time (:datetime ,(format-time-string "%F" time)) ,(format-time-string format time)))

(defconst theme--list-views '(("list" "󰕲" "List") ("grid" "󰕰" "Grid"))
  "The list layouts a reader can pick, default first: value, icon, name.")

(cl-defun theme-list-filter (&key target placeholder (views t))
  "Return a filter for the rows in the element with id TARGET.
PLACEHOLDER is the hint in the search box; VIEWS non-nil adds the
list and grid choice."
  `(div (:class "list-controls" :hidden t :data-requires-js t)
        (input (:type "search" :data-filter ,target :aria-label "Filter this list"
                :placeholder ,(or placeholder "filter… (/ to focus, Esc to clear)")
                :autocomplete "off" :spellcheck "false"))
        (output (:aria-live "polite"))
        ,(and views
              `(fieldset (:class "views")
                         (legend (:class "visually-hidden") "View")
                         ,@(mapcar (lambda (view)
                                     `(label (:title ,(nth 2 view))
                                             (input (:type "radio" :name "list-view" :value ,(car view)
                                                     :aria-label ,(nth 2 view)
                                                     :checked ,(and (equal (car view) "list") t)))
                                             ,(theme--icon (nth 1 view))))
                                   theme--list-views)))))

;;;; Page shell: header, footer, palette dialog

(defun theme--nav-list (items)
  "Return a ul of links for ITEMS, plists with :name and :url."
  `(ul nil ,@(mapcar (lambda (item) `(li nil (a (:href ,(plist-get item :url)) ,(plist-get item :name))))
                     items)))

(defun theme--tool-button (action label glyph &rest extra-glyphs)
  "Return an icon button for ACTION named LABEL, showing GLYPH and EXTRA-GLYPHS."
  `(button (:type "button" :data-action ,action :aria-label ,label :title ,label)
           (span (:class "nf" :aria-hidden "true") ,glyph)
           ,@extra-glyphs))

(cl-defun theme-header (&key site-title title-quotes menu-items)
  "Return the header: SITE-TITLE with TITLE-QUOTES, MENU-ITEMS and the toolbar."
  `(header nil
           (a (:href "/" :class "site-title"
               :title ,(and title-quotes (seq-random-elt title-quotes))
               ;; json-serialize returns UTF-8 bytes; decode them, or any
               ;; non-ASCII quote turns into raw bytes the page cannot save.
               :data-quotes ,(and title-quotes
                                  (decode-coding-string (json-serialize (vconcat title-quotes)) 'utf-8)))
              ,site-title)
           (div nil
                (nav (:aria-label "Site") ,(theme--nav-list menu-items))
                (p (:class "toolbar" :hidden t :data-requires-js t)
                   ,(theme--tool-button "cycle-width" "Content width" "󰭣")
                   ,(theme--tool-button "cycle-font" "Font mode" "󰛖")
                   ,(theme--tool-button "open-schemes" "Color scheme" "󰉦")
                   ,(theme--tool-button "toggle-theme" "Dark or light" ""
                                        '(span (:class "nf" :aria-hidden "true") ""))
                   ,(theme--tool-button "random-page" "Random page" "")
                   (button (:type "button" :data-action "open-palette" :aria-keyshortcuts "x"
                            :title "Search and commands (x)")
                           "M-x " (span (:class "nf" :aria-hidden "true") "󰠳"))
                   (output (:class "toast" :popover "manual" :role "status"))))))

(defun theme--social-link (link)
  "Return a link for the social LINK; links to other sites open in a new tab."
  (let* ((url (plist-get link :url))
         (extra-rel (plist-get link :rel))
         (rel (if extra-rel (format "noopener noreferrer %s" extra-rel) "noopener noreferrer"))
         (external (not (string-prefix-p "mailto:" url))))
    `(a (:href ,url :target ,(and external "_blank") :rel ,(and external rel))
        ,(theme--icon (string-trim (plist-get link :icon)))
        " " ,(plist-get link :label))))

(defun theme-social-links-grid (links)
  "Return LINKS as a list of rows, for page content such as the About page."
  `(ul (:class "list") ,@(mapcar (lambda (link) `(li nil ,(theme--social-link link))) links)))

(cl-defun theme-footer (&key links footer-content)
  "Return the footer: every page in LINKS, then FOOTER-CONTENT."
  `(footer nil
           ,(and links `(nav (:id "all-pages" :aria-label "All pages") ,(theme--nav-list links)))
           ,footer-content))

(defconst theme-palette-dialog
  '(dialog (:id "palette-dialog" :aria-label "Command palette")
           (input (:type "text" :id "palette-input" :class "palette-input"
                   :placeholder "Search posts, pages and commands…" :autocomplete "off"
                   :autocapitalize "off" :spellcheck "false"))
           (div (:id "palette-results" :role "listbox")))
  "The command palette dialog, a native dialog element.")

(cl-defun theme-badge (&key name logo color link subtitle tooltip)
  "Return a badge linking to LINK for NAME with LOGO, SUBTITLE, COLOR and TOOLTIP."
  (let ((tooltip (or tooltip (and subtitle name (format "%s %s" subtitle name)) subtitle name "")))
    `(a (:href ,(or link "#") :class "badge" :title ,tooltip
         :style ,(and color (format "--glow:%s" color)))
        (img (:src ,logo :alt ,(or name "") :loading "lazy"))
        ,(and subtitle `(span (:class "badge-subtitle") ,subtitle))
        ,(and name `(span (:class "badge-name" :style ,(and color (format "background:%s" color)))
                          ,name)))))

(defconst theme--base16-keys
  ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07"
   "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"]
  "The 16 base16 custom property names, in order, as in index.js.")

(defun theme--pre-paint-script (schemes-url light-schemes)
  "Return the script that applies stored choices before the page paints.
SCHEMES-URL is the scheme data address; light mode applies only for
a scheme in LIGHT-SCHEMES."
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
  "The theme-color meta value: a fixed tint for the browser's own frame.")

(defun theme--analytics-script (script-url website-id)
  "Return the Umami loader for SCRIPT-URL and WEBSITE-ID, or nil without both."
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
  `(script (:type "speculationrules")
           (raw-html nil
                     ,(json-serialize
                       '((prerender . [((where . ((and . [((href_matches . "/*"))
                                                          ((not . ((href_matches . "/*.xml"))))
                                                          ((not . ((selector_matches . "[target=_blank], [download]"))))])))
                                        (eagerness . "moderate"))])))))
  "Speculation rules: prerender a link of this site the pointer rests on.")

(cl-defun theme-baseof (&key language body page-title head-nodes palette-data-script
                             stylesheet-href script-href menu-items site-title feed-url feed-title
                             schemes-url favicon-href favicon-type noindex fediverse-creator
                             analytics-script-url analytics-website-id footer-content
                             footer-links title-quotes light-schemes preload-fonts touch-icon-href)
  "Return the whole page for LANGUAGE around BODY, as one html node.
HEAD-NODES are the search engine nodes, such as those of
`denden-seo-head-nodes'.  PALETTE-DATA-SCRIPT must be a raw-html
node.  The other keys are this site's head links and chrome."
  `(html (:lang ,language :data-theme "dark" :data-scheme "haki" :data-font "mixed")
         (head nil
               (meta (:charset "utf-8"))
               ,(and schemes-url (theme--pre-paint-script schemes-url light-schemes))
               (meta (:name "viewport" :content "width=device-width, initial-scale=1.0"))
               (meta (:name "color-scheme" :content "dark"))
               (meta (:name "darkreader-lock"))
               (meta (:name "theme-color" :content ,theme-color-meta-value))
               ,(and page-title `(title nil ,page-title))
               ,@(mapcar (lambda (href)
                           `(link (:rel "preload" :href ,href :as "font" :type "font/woff2"
                                   :crossorigin "anonymous")))
                         preload-fonts)
               ,(and analytics-script-url
                     `(link (:rel "dns-prefetch"
                             :href ,(format "//%s" (url-host (url-generic-parse-url analytics-script-url))))))
               ,(and touch-icon-href `(link (:rel "apple-touch-icon" :href ,touch-icon-href)))
               ,(and noindex '(meta (:name "robots" :content "noindex")))
               ,@(and fediverse-creator
                      `((meta (:name "fediverse:creator" :content ,fediverse-creator))
                        (meta (:property "fediverse:creator" :content ,fediverse-creator))))
               ,(and favicon-href `(link (:rel "icon" :type ,favicon-type :href ,favicon-href)))
               ,(and feed-url `(link (:rel "alternate" :type "application/atom+xml"
                                      :title ,feed-title :href ,feed-url)))
               ,@head-nodes
               ,(and stylesheet-href `(link (:rel "stylesheet" :href ,stylesheet-href)))
               ,(and script-href `(script (:src ,script-href :defer "defer")))
               ,theme--speculation-rules
               ,(theme--analytics-script analytics-script-url analytics-website-id))
         (body nil
               (a (:class "skip-link" :href "#main") "Skip to content")
               ,(theme-header :site-title site-title :title-quotes title-quotes :menu-items menu-items)
               (main (:id "main") ,body)
               ,(theme-footer :links footer-links :footer-content footer-content)
               ,theme-palette-dialog
               ,palette-data-script)))

;;;; Single post and page

(cl-defun theme-post-header (&key title date lastmod word-count reading-time tags)
  "Return the header for TITLE with one line of DATE, LASTMOD, time and TAGS.
DATE and LASTMOD are time values or nil; WORD-COUNT and
READING-TIME are numbers."
  `(header nil
           (h1 nil ,title)
           (p nil
              ,(and date (theme--date date "%F"))
              ,@(and lastmod date
                     (not (equal (format-time-string "%F" lastmod) (format-time-string "%F" date)))
                     (list " · updated " (theme--date lastmod "%F")))
              ,(format "%s%s min read (%s words)" (if date " · " "") (or reading-time 0) (or word-count 0))
              ,@(and tags (cons '(br nil) (theme--tag-links tags))))))

(defun theme-comment (email title)
  "Return a comment box that index.js mails to EMAIL about TITLE."
  `(form (:class "comment" :data-email ,email :data-subject ,(format "Re: %s" title))
         (label (:for "comment-text") "Leave a comment")
         (textarea (:id "comment-text" :name "body" :rows "4" :placeholder "Write your thoughts…"))
         (button (:type "submit") "Comment")
         (small nil "Opens your email client. No public comments here.")))

(defun theme--reference-item (reference)
  "Return one li for REFERENCE, a plist with :href, :label and :internal."
  (let ((href (plist-get reference :href))
        (label (plist-get reference :label)))
    (if (plist-get reference :internal)
        `(li nil (a (:href ,href) ,label))
      `(li nil
           (a (:href ,href :target "_blank" :rel "noopener noreferrer") ,(or label href))
           ,@(and label (not (equal label href))
                  (list " " `(small nil ,(theme--url-domain href))))))))

(defun theme--page-row (page &optional tag-icons marker)
  "Return one row for PAGE: date, MARKER or an icon from TAG-ICONS, title, tags."
  (let ((date (denden-page-date page))
        (tags (theme--tags page)))
    `(li (:data-filter-text ,(theme--filter-text (denden-page-title page)
                                                 (mapcar (lambda (tag) (concat "#" tag)) tags)))
         ,(and date (theme--date date "%d %b"))
         ,@(cond (marker (list (theme--icon marker) '(span (:class "visually-hidden") "Links here: ")))
                 (tag-icons (list (theme--icon (theme--tag-icon tags tag-icons)))))
         (a (:href ,(concat "/" (denden-page-url page))) ,(denden-page-title page))
         ,(and tags `(small nil ,@(theme--tag-links (seq-take tags 3)))))))

(cl-defun theme-references (&key references backlinks related tag-icons (backlink-icon "<-"))
  "Return References, then See Also: BACKLINKS first, then RELATED pages.
REFERENCES are plists for `theme--reference-item'; BACKLINKS and
RELATED are pages, iconed by TAG-ICONS and BACKLINK-ICON."
  (list
   (and references
        `(section (:aria-labelledby "references-heading")
                  ,(theme--heading "references-heading" "References")
                  (ol (:class "list") ,@(mapcar #'theme--reference-item references))))
   (and (or backlinks related)
        `(section (:aria-labelledby "related-heading")
                  ,(theme--heading "related-heading" "See Also")
                  (ul (:class "list")
                      ,@(mapcar (lambda (page) (theme--page-row page nil backlink-icon)) backlinks)
                      ,@(mapcar (lambda (page) (theme--page-row page tag-icons)) related))))))

(cl-defun theme-post-navigation (&key previous next)
  "Return links to the PREVIOUS and NEXT pages, either of which may be nil."
  (let ((short (lambda (page) (truncate-string-to-width (denden-page-title page) 40 nil nil " …"))))
    `(nav (:class "pager" :aria-label "Post navigation")
          ,(and previous `(a (:rel "prev" :href ,(concat "/" (denden-page-url previous)))
                             ,(concat "← " (funcall short previous))))
          ,(and next `(a (:rel "next" :href ,(concat "/" (denden-page-url next)))
                         ,(concat (funcall short next) " →"))))))

(cl-defun theme-single-page (&key post-header toc body-html references comment post-navigation)
  "Return one article from POST-HEADER, TOC, BODY-HTML, REFERENCES, COMMENT
and POST-NAVIGATION; all but POST-HEADER and BODY-HTML may be nil."
  `(article nil
            ,post-header
            ,toc
            (raw-html nil ,body-html)
            ,@references
            ,comment
            ,post-navigation))

(cl-defun theme-home-page (&key title body-html)
  "Return the home page: TITLE and BODY-HTML."
  `(article nil (header nil (h1 nil ,title)) (raw-html nil ,body-html)))

(defun theme--pose-entry (entry &optional open)
  "Return one Pose ENTRY: \"date day :: title\", its tags, its body.
The body is folded unless OPEN is non-nil.  Each tag links to its
page under /tags/, which lists Log posts and Pose entries together."
  (let* ((date (plist-get entry :date))
         (heading (apply #'theme--heading-at 'h3 (plist-get entry :id)
                         (append (and date
                                      (list `(time (:datetime ,date) ,date) " "
                                            `(span (:class "day" :title ,(plist-get entry :day-title))
                                                   ,(plist-get entry :day))
                                            " :: "))
                                 (list (plist-get entry :title)))))
         (tags (plist-get entry :tags))
         (summary (list heading
                        (and tags
                             `(span (:class "tags")
                                    ,@(mapcar (lambda (tag)
                                                `(a (:href ,(format "/tags/%s/" (downcase tag)))
                                                    ,(concat "#" tag)))
                                              tags)))))
         (body (plist-get entry :html)))
    `(article (:data-filter-text ,(plist-get entry :search-text) :data-day ,(plist-get entry :weekday))
              ,@(if (string-empty-p (string-trim body))
                    summary
                  `((details (:open ,open) (summary nil ,@summary) (raw-html nil ,body)))))))

(cl-defun theme-pose-page (&key title intro-html weeks)
  "Return the Pose page: TITLE, INTRO-HTML, a filter and one section per WEEKS."
  (let ((count (apply #'+ (mapcar (lambda (week) (length (plist-get week :entries))) weeks)))
        (first-entry t))
    `(article nil
              (header nil (h1 nil ,title))
              ,(and intro-html (not (string-empty-p intro-html)) `(raw-html nil ,intro-html))
              ,(theme-list-filter :target "pose-entries" :views nil
                                  :placeholder (format "search %d entries… (/ to focus, Esc to clear)" count))
              (div (:id "pose-entries")
                   ,@(mapcar (lambda (week)
                               `(section nil
                                         ,(theme--heading (plist-get week :id) (plist-get week :label))
                                         ;; Weeks and entries are newest first; the newest entry starts open.
                                         ,@(mapcar (lambda (entry)
                                                     (prog1 (theme--pose-entry entry first-entry)
                                                       (setq first-entry nil)))
                                                   (plist-get week :entries))))
                             weeks)))))

;;;; Listing pages

(cl-defun theme-article-list (&key grouped-pages tag-icons)
  "Return one section per year of GROUPED-PAGES, each a list of rows.
GROUPED-PAGES is as `denden-group-pages-by-year' returns; TAG-ICONS
gives each row its icon."
  `(div (:id "article-list")
        ,@(if (null grouped-pages)
              (list '(p nil "No articles found."))
            (mapcar (lambda (group)
                      `(section nil
                                ,(theme--heading (car group) (car group))
                                (ul (:class "list")
                                    ,@(mapcar (lambda (page) (theme--page-row page tag-icons))
                                              (cdr group)))))
                    grouped-pages))))

(cl-defun theme-terms-list (&key title term-counts (base-url "/tags/"))
  "Return the TITLE page that lists TERM-COUNTS, each linked under BASE-URL.
TERM-COUNTS is a list of (TERM . COUNT), shown in alphabetical order."
  (let ((sorted (sort term-counts :key #'car)))
    `(article nil
              (header nil (h1 nil ,title))
              ,@(if (null sorted)
                    (list '(p nil "No tags found."))
                  (list (theme-list-filter :target "terms-list")
                        `(ul (:class "list" :id "terms-list")
                             ,@(mapcar (lambda (entry)
                                         (pcase-let ((`(,term . ,count) entry))
                                           `(li (:data-filter-text ,(downcase term))
                                                (a (:href ,(format "%s%s/" base-url (downcase term)))
                                                   ,(concat "#" term))
                                                (small nil ,(format "%d %s" count (if (= count 1) "post" "posts"))))))
                                       sorted)))))))

(cl-defun theme-term-header (&key count feed-url (back-url "/tags/"))
  "Return a term page's line: post COUNT, a FEED-URL link, a link to BACK-URL."
  `(p nil
      ,(format "%d %s" count (if (= count 1) "post" "posts"))
      ,@(and feed-url (list " · " `(a (:href ,feed-url) "RSS feed")))
      " · " (a (:href ,back-url) "all tags")))

(cl-defun theme-post-listing (&key title term-header article-list)
  "Return a listing page: TITLE, TERM-HEADER if any, a filter, ARTICLE-LIST."
  `(article nil
            (header nil (h1 nil ,title) ,term-header)
            ,(theme-list-filter :target "article-list"
                                :placeholder "filter… #emacs (/ to focus, Esc to clear)")
            ,article-list))

;;;; Topic-list pages (wander, projects, media, quotes, uses)

(defun theme--topic-part-chip (part pages)
  "Return one chip for PART, a plist with :key, :value and :html.
Refs link to their page only when one of PAGES refers to them."
  (let ((key (plist-get part :key))
        (value (plist-get part :value)))
    (cond
     ((string-empty-p value) nil)
     ((equal key "tag")
      `(a (:href ,(format "/tags/%s/" (downcase value))) ,(concat "#" value)))
     ((equal key "refs")
      (if (denden-pages-with-term pages "refs" value)
          `(a (:href ,(format "/refs/%s/" (downcase value))) ,(concat "@" value))
        `(span nil ,(concat "@" value))))
     ((string-prefix-p "http" value)
      `(a (:href ,value :target "_blank" :rel "noopener") ,(concat key " ↗")))
     (t `(span nil ,(format "%s: " key) (raw-html nil ,(plist-get part :html)))))))

(defun theme--topic-refs-backlinks (item pages)
  "Return the [1] [2] links to the PAGES that share the refs value of ITEM."
  (let ((ref (plist-get (seq-find (lambda (part) (equal (plist-get part :key) "refs"))
                                  (plist-get item :parts))
                        :value))
        (index 0))
    (and ref
         (mapcar (lambda (page)
                   (setq index (1+ index))
                   `(a (:href ,(concat "/" (denden-page-url page)) :title ,(denden-page-title page))
                       ,(format "[%d]" index)))
                 (denden-pages-with-term pages "refs" ref)))))

(cl-defun theme-topic-item (&key item icon pages (external t))
  "Return one row for the topic ITEM with ICON.
PAGES resolve refs; EXTERNAL non-nil opens the item's link in a new tab."
  (let* ((chips (delq nil (mapcar (lambda (part) (theme--topic-part-chip part pages))
                                  (plist-get item :parts))))
         (url (plist-get item :url))
         (name (plist-get item :name))
         (description (plist-get item :description)))
    `(li (:data-filter-text
          ,(theme--filter-text name
                               (replace-regexp-in-string (rx "<" (+ (not (in ">"))) ">") "" description)
                               (mapcar (lambda (part)
                                         (format "%s: %s" (plist-get part :key) (plist-get part :value)))
                                       (plist-get item :parts))))
         ,(and icon (not (string-empty-p icon)) (theme--icon icon))
         ,(if (and url (not (string-empty-p url)))
              `(a (:href ,url :target ,(and external "_blank") :rel ,(and external "noopener")) ,name)
            `(span nil ,name))
         ,@(theme--topic-refs-backlinks item pages)
         ,(and (not (string-empty-p description)) `(p nil (raw-html nil ,description)))
         ,(and chips `(small nil ,@(cdr (mapcan (lambda (chip) (list " " chip)) chips)))))))

(defun theme--topic-item-tags (item)
  "Return the tag values among the parts of ITEM."
  (mapcan (lambda (part) (and (equal (plist-get part :key) "tag") (list (plist-get part :value))))
          (plist-get item :parts)))

(cl-defun theme-topic-list-items (&key groups tag-icons pages chip-color (external t) collapsed)
  "Return one section per group of GROUPS, each a heading and a list of rows.
TAG-ICONS gives each row its icon (an item's own :icon wins),
CHIP-COLOR names a base16 slot for the chips, PAGES resolve refs,
EXTERNAL non-nil opens links in a new tab, and COLLAPSED non-nil
wraps each group in an open details element."
  `(div (:id "topic-list" :style ,(and chip-color (format "--chip-color: var(--%s)" chip-color)))
        ,@(mapcar
           (lambda (group)
             (let* ((label (plist-get group :label))
                    (items (plist-get group :items))
                    (heading (theme--heading (denden-heading-id label)
                                             label " " `(small nil ,(format "(%d)" (length items)))))
                    (rows `(ul (:class "list")
                               ,@(mapcar (lambda (item)
                                           ;; Tags of the item win over the group label's icon.
                                           (theme-topic-item
                                            :item item :pages pages :external external
                                            :icon (or (plist-get item :icon)
                                                      (theme--tag-icon (append (theme--topic-item-tags item)
                                                                               (list (downcase label)))
                                                                       tag-icons))))
                                         items))))
               (if collapsed
                   `(section nil (details (:open t) (summary nil ,heading) ,rows))
                 `(section nil ,heading ,rows))))
           groups)))

(defconst theme--wander-launch
  '(p nil (a (:href "/wander/console/" :class "wander-launch" :data-dialog "wander-dialog")
             "Wander the small web")
      " :: random sites from this network")
  "The Wander console link; with JS it opens `theme--wander-dialog' instead.")

(defconst theme--wander-dialog
  '(dialog (:id "wander-dialog" :aria-label "Wander console")
           (form (:method "dialog") (button (:type "submit") "Close"))
           (iframe (:title "Wander console" :data-src "/wander/console/")))
  "The Wander console in a dialog; index.js sets the iframe address on first open.")

(cl-defun theme-topic-list-page (&key title date intro-html items-node show-console)
  "Return a topic-list page: TITLE, DATE, INTRO-HTML, a filter, ITEMS-NODE.
DATE is a time value or nil; SHOW-CONSOLE non-nil adds the Wander
console."
  `(article nil
            (header nil
                    (h1 nil ,title)
                    ,(and date `(p nil ,(theme--date date "%F")))
                    ,(and show-console theme--wander-launch))
            ,(and intro-html (not (string-empty-p intro-html)) `(raw-html nil ,intro-html))
            ,(theme-list-filter :target "topic-list")
            ,items-node
            ,(and show-console theme--wander-dialog)))

(provide 'theme)
;;; theme.el ends here
