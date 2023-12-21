;; inspired by @djliden : https://djliden.github.io

;; just to add class for toc
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

(setq org-html-htmlize-output-type 'inline-css)

(setq org-publish-project-alist
      (list
       (list "content"
             :recursive t
             :base-directory (expand-file-name "content/" default-directory) ;; wherever the file is
             :base-extension "org"
             :publishing-directory (expand-file-name "public/" default-directory)
             :publishing-function 'org-html-publish-to-html
             :headline-levels 4
             :auto-preamble t
             :html-doctype "html5"
             :html-html5-fancy t
             :html-head-include-scripts nil
             :html-head-include-default-style nil
             :html-head "<link rel=\"stylesheet\" href=\"/stylesheet.css\" type=\"text/css\"/>"
             :html-preamble (file-contents (expand-file-name "assets/pre.html" default-directory))
             :html-postamble (file-contents (expand-file-name "assets/post.html" default-directory))
             :with-author t
             :with-creator t
             :with-toc nil
             :section-numbers nil
             :time-stamp-file nil
             :htmlized-source t
             :auto-sitemap t
             :sitemap-filename "sitemap.org"
             ;; :sitemap-format-entry 'dw/format-news-entry
             :sitemap-style 'list
             :sitemap-sort-files 'anti-chronologically
             :with-title nil
              :with-timestamps nil

             )

       (list "static"
             :base-directory (expand-file-name "content/" default-directory)
             :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|svg"
             :publishing-directory (expand-file-name "public/" default-directory)
             :recursive t
             :publishing-function 'org-publish-attachment
             ;; :exclude ".*/posts/drafts/.*"  ; Exclude drafts directory from publishing
             )

       (list "assets"
             :base-directory (expand-file-name "assets/" default-directory)
             :base-extension ".*"
             :publishing-directory (expand-file-name "public/" default-directory)
             :recursive t ;; for fonts
             :publishing-function 'org-publish-attachment
             )
       '("org" :components ("content" "assets" "static"))

       ))
