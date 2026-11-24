;;; site-schemes-generate-test.el --- tests for site-schemes-generate -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch -L denden -L theme -L site -l ert \
;;     -l denden/denden.el -l theme/theme.el -l site/site-schemes-base16.el \
;;     -l site/site.el -l site/test/site-schemes-generate-test.el \
;;     -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'site)

(ert-deftest site-test-yaml-scheme-parse-keeps-quoted-numeric-looking-name-a-string ()
  "Regression: `yaml-parse-string' resolves a quoted, numeric-looking
scalar (\"0x96f\") to the number 2415 instead of leaving it a string.
`site--yaml-scheme-file-to-entry' must read :name/:author/:variant by
regex on the raw text, not trust that resolver, so the real
data/schemes/base16/0x96f.yaml scheme keeps its own name."
  (let* ((file (expand-file-name "data/schemes/base16/0x96f.yaml"
                                 (locate-dominating-file default-directory ".git")))
         (entry (site--yaml-scheme-file-to-entry file)))
    (should (equal (car entry) "0x96f"))
    (should (equal (plist-get (cdr entry) :name) "0x96f"))
    (should (stringp (plist-get (cdr entry) :name)))))

(ert-deftest site-test-yaml-scheme-parse-handles-bare-unquoted-fields ()
  "A handful of real scheme files leave author or variant unquoted
(e.g. linux-vt.yaml's \"variant: dark\", no quotes) -- must still parse."
  (let* ((file (expand-file-name "data/schemes/base16/linux-vt.yaml"
                                 (locate-dominating-file default-directory ".git")))
         (entry (site--yaml-scheme-file-to-entry file)))
    (should (equal (plist-get (cdr entry) :name) "Linux VT"))
    (should (equal (plist-get (cdr entry) :variant) "dark"))
    (should (= (length (plist-get (cdr entry) :palette)) 16))))

(provide 'site-schemes-generate-test)
;;; site-schemes-generate-test.el ends here
