;;; site-async-init.el --- dedicated init file for the site's async build -*- lexical-binding: t; -*-

;; Loaded via `-Q -l' by `org-export-async-start' (see `site-build-async').
;; Unlike denden/denden-async-init.el (denden's own generic minimal init),
;; this one pulls in the whole site+theme stack `site-publish-page' needs.

;; Same reasoning as denden-async-init.el's own coding-system lines: `-Q'
;; means no user init file has set a preferred coding system, and this
;; site's nerd-font glyphs then trip `select-safe-coding-system' into an
;; interactive question with no terminal to answer it on.
(setq coding-system-for-read 'utf-8-unix)
(setq coding-system-for-write 'utf-8-unix)

;; content/_index.org embeds emacs-lisp Babel blocks ("Latest post"/"Latest
;; pose"); confirmed live that `org-export-as' -- called for EVERY page
;; during word-count metadata collection (`denden--file-word-count'), not
;; just for _index.org's own export -- otherwise hits `org-confirm-babel-
;; evaluate''s interactive y-or-n-p with no terminal to answer it on,
;; erroring "End of file during parsing: Error reading from stdin" instead
;; of hanging outright. Same class of gotcha as the coding-system lines
;; above; this content is self-authored, not third-party, so trusting it
;; here is no different from already trusting it to `org-export-as' at all.
(setq org-confirm-babel-evaluate nil)

(let ((here (file-name-directory (or load-file-name buffer-file-name))))
  (add-to-list 'load-path here)
  (add-to-list 'load-path (expand-file-name "../denden" here))
  (add-to-list 'load-path (expand-file-name "../theme" here)))
(require 'site)

(provide 'site-async-init)
;;; site-async-init.el ends here
