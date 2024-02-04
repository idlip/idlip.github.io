;; easy way for me to ignore these with my system config, so used by deploy CI

(require 'package)

(unless (package-installed-p 'elfeed)

;;; packages
;;;; Initialize the package system
  (require 'package)
  (setq package-user-dir (expand-file-name "./.packages"))
  (setq package-archives '(("melpa" . "https://melpa.org/packages/")
                           ("elpa" . "https://elpa.gnu.org/packages/")))

  (unless (bound-and-true-p package--initialized)
    (customize-set-variable 'package-enable-at-startup nil)
    (package-initialize))

  (unless package-archive-contents
    (package-refresh-contents))

  ;; Check and install dependencies
  (dolist (package '(htmlize
                     webfeeder
                     org-re-reveal
                     ;; julia-mode
                     ;; ess
                     ;; ox-rss webfeeder
                     ;; esxml
                     ))
    (unless (package-installed-p package)
      (package-install package))))

;; (require 'julia-mode)

;; ;; Load publishing system
(require 'ox-publish)
(require 'webfeeder)
(require 'org-re-reveal)

;; inspired by @djliden : https://djliden.github.io


;; just to add class for toc, except that its default function as it is.
(defun org-html-toc (depth info &optional scope)
  "Build a table of contents.
DEPTH is an integer specifying the depth of the table.  INFO is
a plist used as a communication channel.  Optional argument SCOPE
is an element defining the scope of the table.  Return the table
of contents as a string, or nil if it is empty."
  (let ((toc-entries
	     (mapcar (lambda (headline)
		           (cons (org-html--format-toc-headline headline info)
			             (org-export-get-relative-level headline info)))
		         (org-export-collect-headlines info depth scope))))
    (when toc-entries
      (let ((toc (concat "<div id=\"text-table-of-contents\" role=\"doc-toc\">"
			             (org-html--toc-text toc-entries)
			             "</div>\n")))
	    (if scope toc
	      (let ((outer-tag (if (org-html--html5-fancy-p info)
			                   "nav"
			                 "div")))
	        (concat (format "<%s id=\"table-of-contents\" role=\"doc-toc\">\n" outer-tag)
		            (let ((top-level (plist-get info :html-toplevel-hlevel)))
		              (format "<h%d class=\"org-toc\">%s</h%d>\n"
			                  top-level
			                  (org-html--translate "Table of Contents" info)
			                  top-level))
		            toc
		            (format "</%s>\n" outer-tag))))))))

(defun file-contents (file)
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

;; gives emacs-theme as css for code snippets.
;; if inline-css, it puts required one's inside html
;; or else we have to import it into out css file. I do that in theme.org
(setq org-html-htmlize-output-type 'css)

;;; additional settings
(setq org-html-validation-link nil
      org-export-use-babel nil)

;; for Beautiful checbox
(setq org-html-checkbox-types
      '((nerd-icon
         (on . "<span class=\"cbon\"> </span>")
         (off . "<span class=\"cboff\"> </span>")
         (trans . "<span class=\"cbnil\"> </span>")))

      org-html-checkbox-type 'nerd-icon)


(defun d/op-format-index (entry style project)
  "Format posts/snippets with author and published data in the index page."
  (cond ((not (directory-name-p entry))
         (format "[[file:%s][%s]] \n\n %s"
                 entry
                 (org-publish-find-title entry project)
                 (format-time-string "%b %d, %Y"
                                     ;; (format-time-string "%b %d, %Y" '(25994 57546 644885 340000))
                                     (org-publish-find-date entry project))
))
        ((eq style 'tree) (file-name-nondirectory (directory-file-name entry)))
        (t entry)))


(setq org-publish-use-timestamps-flag t
      org-publish-timestamp-directory "./.org-cache/"
      org-export-with-section-numbers nil
      org-export-use-babel nil
      org-export-with-smart-quotes t
      org-export-with-sub-superscripts nil
      org-export-with-tags 'not-in-toc
      org-html-htmlize-output-type 'css
      org-html-prefer-user-labels t
      org-html-link-org-files-as-html t
      org-html-html5-fancy t
      org-html-doctype "html5"
      org-html-self-link-headlines nil
      org-html-head-include-scripts nil
      org-html-head-include-default-style nil
      org-export-with-toc nil
      make-backup-files nil)



(setq org-publish-project-alist
      (list
       (list "mainpage"
             :recursive nil
             :base-directory "./content" ;; wherever the file is
             :base-extension "org"
             :publishing-directory "./public"
             :publishing-function 'org-html-publish-to-html
             :html-preamble (file-contents "./assets/pre.html")
             :html-postamble (file-contents "./assets/post.html")
             :html-divs '((preamble "nav" "preamble")
			              (content "main" "content") ;; necessary to get the right styling
			              (postamble "footer" "postamble"))
             )

       (list "posts"
             ;; index page for posts
             :html-preamble (file-contents "./assets/pre.html")
             :html-postamble (file-contents "./assets/post.html")
             :sitemap-filename "index.org"
             :sitemap-format-entry 'd/op-format-index
             :sitemap-style 'list
             ;; :with-date t
             :auto-sitemap t
             :sitemap-sort-files 'anti-chronologically
             :sitemap-title "Posts"
             :base-directory "./content/posts/"
             :publishing-directory "./public/posts/"
             :publishing-function 'org-html-publish-to-html
             )

       (list "snippets"
             ;; index page for snippets
             :html-preamble (file-contents "./assets/pre.html")
             :html-postamble (file-contents "./assets/post.html")
             :sitemap-filename "index.org"
             :sitemap-format-entry 'd/op-format-index
             :sitemap-style 'list
             :auto-sitemap t
             :sitemap-sort-files 'anti-chronologically
             :sitemap-title "Snippets"
             :base-directory "./content/snippets/"
             :publishing-directory "./public/snippets/"
             :publishing-function 'org-html-publish-to-html
             )

       (list "static" ;; for images
             :base-directory "./content/"
             :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|svg"
             :publishing-directory "./public"
             :recursive t
             :publishing-function 'org-publish-attachment
             ;; :exclude ".*/posts/drafts/.*"  ; Exclude drafts directory from publishing
             )

       (list "assets" ;; for *-amble html, css, fonts & img
             :base-directory "./assets/"
             :base-extension ".*"
             :publishing-directory "./public/"
             :recursive t ;; for fonts
             :publishing-function 'org-publish-attachment
             )

       (list "slides"
             :base-directory "./content/slides/"
             ;; :exclude ".*"
             :base-extension "org"
             :publishing-directory "./public/slides/"
             :publishing-function 'org-re-reveal-publish-to-reveal)

       ;; (list "slides-assets"
       ;;       :base-directory "./content/slides"
       ;;       :recursive t
       ;;       :base-extension ".*"
       ;;       :exclude ".*\\.org$"
       ;;       :publishing-directory "./public/slides/"
       ;;       :publishing-function 'org-publish-attachment)

       '("org" :components ("mainpage" "assets" "static" "posts" "snippets" "slides" "slides-assets"))

       ))

(org-publish-all t)

;; later generate rss feed

(webfeeder-build "rss.xml"
                 "./public"
                 "https://idlip.github.io"
                 ;; basically apart from index.html it takes all files in snippets and posts to generate a rss feed.
                 (apply #'append
                        (let ((dirs '("snippets/" "posts/")))
                          (mapcar (lambda (dir)
                                    (mapcar (lambda (file) (concat dir file))
                                            (delete "./index.html"
                                                    (let ((default-directory (expand-file-name (concat "./public/" dir))))
                                                      (directory-files-recursively "./" ".*\\.html$")))))
                                  dirs)))
                 :builder 'webfeeder-make-rss
                 :title "Dilip Logs"
                 :description "Dilip's blog posts and snippets"
                 :author "Dilip")
