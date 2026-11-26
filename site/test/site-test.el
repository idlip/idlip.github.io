;;; site-test.el --- Tests for the layouts and outputs of site.el -*- lexical-binding: t; -*-

;;; Commentary:

;; Render a small fixture site through idlip.in's own layouts and
;; outputs, in memory, and check the pages and files it makes.

;;; Code:

(require 'ert)
(require 'ert-x)
(require 'dom)
(require 'site)

(defconst site-test--files
  '(("content/index.org" . "#+title: Abstract\n\nWelcome home.\n")
    ("content/log/alpha.org" . "#+title: Alpha\n#+date: [2026-01-05 Mon]\n#+tags: emacs org\n#+refs: book\n#+toc: t\n\nSee [[https://github.com/idlip][my code]] and [[file:beta.org]].\n\n* First part\nText.\n** Inner part\nMore.\n")
    ("content/log/beta.org" . "#+title: Beta\n#+date: [2026-02-10 Tue]\n#+tags: emacs\n#+no_comment: t\n\nA second post on https://example.org/page.\n")
    ("content/pose.org" . "#+title: Pose\n#+layout: pose\n\nShort notes.\n\n* [2026-03-02 Mon] First note :life:\nBody one.\n* [2026-03-02 Mon] Second note\nBody *two*.\n* [2026-03-09 Mon] Later note\n")
    ("content/wander.org" . "#+title: Wander\n#+layout: topic-list\n#+sort: name\n\nSites I read.\n\n* Consoles\n- [[https://c.example/][Console]] :: A console\n* Blogs\n- [[https://z.example/][Zed]] :: Last /one/ | tag: emacs\n- [[https://a.example/][Ann]] :: First | refs: book | author: =Ann=\n- Plain Name :: Not a link\n")
    ("content/sitemap.org" . "#+title: Sitemap\n#+layout: sitemap\n\nEvery page.\n")
    ("content/links.org" . "#+title: Links\n#+layout: links\n\nEvery link.\n")
    ("assets/css/theme.css" . "body {}\n")
    ("assets/css/wander-theme.css" . ".wander {}\n")
    ("assets/js/index.js" . "// script\n")
    ("static/og/alpha.png" . "png")
    ("static/og/home.png" . "png"))
  "Files of the fixture site, relative to its root, and their text.")

(defmacro site-test--with-site (&rest body)
  "Run BODY with `site', `pages' and `files' bound for the fixture site.
`files' is the rendered site as (URL . TEXT); nothing is written."
  (declare (indent 0) (debug t))
  `(ert-with-temp-directory root
     (pcase-dolist (`(,file . ,text) site-test--files)
       (let ((file (expand-file-name file root)))
         (make-directory (file-name-directory file) t)
         (with-temp-file file (insert text))))
     (let* ((site-root-directory root)
            (site--build-data nil)
            (denden-lastmod-from-git nil)
            (inhibit-message t)
            (site (copy-sequence idlip-site))
            (pages (progn (setf (denden-site-root-directory site) root)
                          (denden-collect-pages site)))
            (files (denden-render-site site pages)))
       (ignore files)
       ,@body)))

(defun site-test--file (url files)
  "Return the text of URL in FILES."
  (or (cdr (assoc url files)) (error "No file %s" url)))

(defun site-test--structure-problems (html)
  "Return the problems of the page HTML: not one h1, images without alt text."
  (let ((dom (denden--parse-html html)))
    (append (unless (= (length (dom-by-tag dom 'h1)) 1) (list "not exactly one h1"))
            (mapcan (lambda (image) (unless (dom-attr image 'alt) (list "image without alt")))
                    (dom-by-tag dom 'img)))))

(ert-deftest site-test-every-file-is-made ()
  "The fixture site has its pages, lists, feeds, redirects and assets."
  (site-test--with-site
    (dolist (url '("" "log/alpha/" "log/beta/" "pose/" "wander/" "sitemap/" "links/"
                   "log/" "tags/" "tags/emacs/" "refs/" "refs/book/" "404.html"
                   "index.xml" "rss.xml" "feed.xml" "log/index.xml" "pose/rss.xml"
                   "tags/emacs/rss.xml" "refs/book/rss.xml" "sitemap.xml" "robots.txt"
                   "posts/" "themes/" "search-index.json" "wander/console/wander.js"
                   "wander/console/wander-theme.css" "css/bundle.css" "js/index.js"
                   "js/schemes-data.json" "log/alpha/og.svg"))
      (should (assoc url files)))
    (should-not (assoc "og.svg" files))
    (should-not (assoc "pose/og.svg" files))))

(ert-deftest site-test-pages-are-well-formed ()
  "Every HTML page but the redirects has one h1 and image alt text."
  (site-test--with-site
    (pcase-dolist (`(,url . ,text) files)
      (when (and (string-prefix-p "<!doctype html>" text)
                 (not (member url '("posts/" "themes/"))))
        (should (equal (cons url (site-test--structure-problems text)) (list url)))))))

(ert-deftest site-test-single-page ()
  "A post has its header, table of contents, references and pager."
  (site-test--with-site
    (let ((alpha (site-test--file "log/alpha/" files))
          (beta (site-test--file "log/beta/" files)))
      (should (string-search "<title>Alpha | Dilip&#39;s Log</title>" (replace-regexp-in-string "'" "&#39;" alpha)))
      (should (string-search "<time datetime=\"2026-01-05\">2026-01-05</time>" alpha))
      (should (string-search "<details class=\"toc\"><summary>Contents</summary><ul><li><a href=\"#first-part\">First part</a><ul><li><a href=\"#inner-part\">Inner part</a>" alpha))
      (should (string-search "references-heading" alpha))
      (should (string-search "<a rel=\"next\" href=\"/log/beta/\">Beta →</a>" alpha))
      (should (string-search "class=\"comment\"" alpha))
      (should-not (string-search "class=\"comment\"" beta))
      (should-not (string-search "application/atom+xml" alpha))
      (should (string-search "type=\"application/atom+xml\" title=\"Abstract RSS feed\" href=\"/index.xml\""
                             (site-test--file "" files))))))

(ert-deftest site-test-pose-entries ()
  "Pose entries come newest first, with date anchors made unique."
  (site-test--with-site
    (let ((entries (site-pose-entries site (site-pose-page pages) pages)))
      (should (equal (mapcar (lambda (entry) (plist-get entry :id)) entries)
                     '("2026-03-09" "2026-03-02" "2026-03-02-2")))
      (should (equal (plist-get (nth 1 entries) :tags) '("life")))
      (should (string-search "<b>two</b>" (plist-get (nth 2 entries) :html)))
      (should (equal (plist-get (car entries) :day-title) "Monday · Somvar · Moon's day"))
      (should (equal (mapcar (lambda (week) (plist-get week :label)) (site--pose-weeks entries))
                     '("Week 11 · 9 to 15 Mar 2026" "Week 10 · 2 to 8 Mar 2026")))
      (should (string-search "pose/#2026-03-02-2" (site-test--file "index.xml" files))))))

(ert-deftest site-test-topic-groups ()
  "Topic lists keep groups, sort by name, and export descriptions and chips."
  (site-test--with-site
    (let* ((wander (denden-page-for-source (expand-file-name "content/wander.org" root) pages))
           (groups (site-topic-groups site wander pages))
           (blogs (plist-get (nth 1 groups) :items)))
      (should (equal (mapcar (lambda (group) (plist-get group :label)) groups) '("Consoles" "Blogs")))
      (should (equal (mapcar (lambda (item) (plist-get item :name)) blogs) '("Ann" "Plain Name" "Zed")))
      (should (equal (plist-get (nth 1 blogs) :url) ""))
      (should (string-search "<span>Plain Name</span>" (site-test--file "wander/" files)))
      (should (equal (plist-get (nth 2 blogs) :description) "Last <i>one</i>"))
      (should (equal (plist-get (nth 1 (plist-get (car blogs) :parts)) :html) "<code>Ann</code>"))
      (let ((script (site-test--file "wander/console/wander.js" files)))
        (should (string-search "consoles:\n[  \"https://c.example/\",\n]" script))))))

(ert-deftest site-test-lists-and-links ()
  "Tag pages count their posts, and the links page groups sites by domain."
  (site-test--with-site
    (should (string-search "2 posts" (site-test--file "tags/" files)))
    (should (string-search "<h1>#emacs</h1>" (site-test--file "tags/emacs/" files)))
    (let ((links (site-test--file "links/" files)))
      (should (string-search "github.com" links))
      (should (string-search "example.org" links)))
    (should (string-search "url=/log/" (site-test--file "posts/" files)))))

(ert-deftest site-test-link-dates-from-log ()
  "A link's date is its oldest addition; punctuation after a bare URL is dropped."
  (let ((dates (site--link-dates-from-log
                '("commit:2026-11-20"
                  "+See [[https://a.example/x][A]] and https://b.example/y."
                  "commit:2026-01-02"
                  "+++ b/content/old.org"
                  "+First: https://a.example/x"
                  "-Removed: https://c.example/"))))
    (should (equal (gethash "https://a.example/x" dates) "2026-01-02"))
    (should (equal (gethash "https://b.example/y" dates) "2026-11-20"))
    (should-not (gethash "https://c.example/" dates))))

(ert-deftest site-test-og-image-only-on-posts ()
  "A Log post with a card gets og:image; the home and Pose pages never do."
  (site-test--with-site
    (should (string-search "<meta property=\"og:image\" content=\"https://idlip.in/og/alpha.png\" />"
                           (site-test--file "log/alpha/" files)))
    (should (string-search "summary_large_image" (site-test--file "log/alpha/" files)))
    (dolist (url '("" "pose/" "log/beta/"))
      (should-not (string-search "og:image" (site-test--file url files)))
      (should (string-search "content=\"summary\"" (site-test--file url files))))))

(ert-deftest site-test-pose-entry-time ()
  "A Pose entry's time is its heading's clock, else the default time."
  (let ((denden-default-time "22:00"))
    (should (equal (format-time-string "%F %H:%M" (site--pose-entry-time '(:date "2026-03-02")))
                   "2026-03-02 22:00"))
    (should (equal (format-time-string "%F %H:%M"
                                       (site--pose-entry-time '(:date "2026-03-02" :clock (7 5))))
                   "2026-03-02 07:05"))))

(ert-deftest site-test-pose-tags ()
  "Pose entry tags show as chips and share /tags/ with Log posts."
  (site-test--with-site
    (should (string-search "<span class=\"tags\"><a href=\"/tags/life/\">#life</a></span>"
                           (site-test--file "pose/" files)))
    (should (string-search "<a href=\"/pose/#2026-03-02\">First note</a>"
                           (site-test--file "tags/life/" files)))
    (should (string-search "#life" (site-test--file "tags/" files)))
    (should (string-search "pose/#2026-03-02" (site-test--file "tags/life/rss.xml" files)))
    (should (string-search "\"name\":\"life\"" (site-test--file "" files)))))

(provide 'site-test)
;;; site-test.el ends here
