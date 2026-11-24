;;; site-og-test.el --- tests for site-og -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch -L denden -L theme -L site -l ert \
;;     -l denden/denden.el -l theme/theme.el -l site/site-schemes-base16.el \
;;     -l site/site.el -l site/test/site-og-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'site)

(ert-deftest site-test-og-card-svg-basic-shape ()
  "A card with title/excerpt/tags/date/slug/meta-right renders every
piece, well-formed enough to parse back as XML."
  (let* ((svg (site-og-card-svg :title "A Short Title" :excerpt "First paragraph here.\n\nSecond one."
                                :tags '("emacs" "nix") :slug "log/my-post/" :date "2024-01-01"
                                :meta-right "119 words · 1 min" :card-site-title "Dilip's Log"))
         (dom (with-temp-buffer (insert svg) (libxml-parse-xml-region (point-min) (point-max)))))
    (should dom)
    (should (string-match-p "viewBox=\"0 0 1200 630\"" svg))
    (should (string-match-p "Dilip's Log" svg))
    (should (string-match-p "A Short Title" svg))
    (should (string-match-p ">#emacs</text>" svg))
    (should (string-match-p ">#nix</text>" svg))
    (should (string-match-p "First paragraph here\\." svg))
    (should (string-match-p "/log/my-post</text>" svg))
    (should (string-match-p "119 words" svg))))

(ert-deftest site-test-og-card-svg-no-favicon-when-path-missing ()
  (let ((svg (site-og-card-svg :title "T" :card-site-title "S" :favicon-path "/no/such/file.webp")))
    (should-not (string-match-p "<image " svg))))

(ert-deftest site-test-og-card-svg-long-title-uses-smaller-font ()
  (let ((svg (site-og-card-svg
              :title "This Is A Genuinely Very Long Title That Exceeds Fifty Two Characters Easily"
              :card-site-title "S")))
    (should (string-match-p "font-size=\"46\"" svg))))

(provide 'site-og-test)
;;; site-og-test.el ends here
