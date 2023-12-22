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
;; (require 'ox-rss)
;; (require 'webfeeder)
;; (require 'esxml)

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
         (trans . "<span class=\"cbnil\"> </span>"))))

(setq org-html-checkbox-type 'nerd-icon)

(setq org-publish-project-alist
      (list
       (list "content"
             :recursive t
             :base-directory "./content" ;; wherever the file is
             :base-extension "org"
             :publishing-directory "./public"
             :publishing-function 'org-html-publish-to-html
             :headline-levels 4
             :auto-preamble t
             :html-doctype "html5"
             :html-html5-fancy t
             :html-head-include-scripts nil
             :html-head-include-default-style nil
             :html-head "<link rel=\"stylesheet\" href=\"/stylesheet.css\" type=\"text/css\"/>"
             :html-preamble (file-contents "./assets/pre.html")
             :html-postamble (file-contents "./assets/post.html")
             :with-author t
             :with-creator t
             :with-toc nil
             :section-numbers nil
             :time-stamp-file nil
             :htmlized-source t
             :html-divs '((preamble "nav" "preamble")
			              (content "main" "content") ;; necessary to get the right styling
			              (postamble "footer" "postamble"))
             :auto-sitemap t
             :sitemap-filename "sitemap.org"
             ;; :sitemap-format-entry 'dw/format-news-entry
             :sitemap-style 'list
             :sitemap-sort-files 'anti-chronologically
             :with-title t
             :with-timestamps nil

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
       '("org" :components ("content" "assets" "static"))

       ))

(org-publish-all t)
