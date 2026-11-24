;;; site-schemes-test.el --- tests for site-schemes -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch -L denden -L theme -L site -l ert \
;;     -l denden/denden.el -l theme/theme.el -l site/site-schemes-base16.el \
;;     -l site/site.el -l site/test/site-schemes-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'site)

(ert-deftest site-test-scheme-css-emits-dark-and-light-blocks ()
  "Readable :dark and :light yaml keys emit both blocks; an unreadable
variant (One Dark's body text is under 7:1) and a haki-shaped entry emit nothing."
  (let* ((schemes (list (list :name "gruvbox" :dark "gruvbox-dark-hard" :light "gruvbox-light-medium")
                        (list :name "one-dark" :dark "onedark")
                        (list :name "haki" :bg "#000000" :fg "#ffffff" :accent "#5fd7af")))
         (css (site-scheme-css schemes)))
    (should (string-match-p "\\[data-scheme=\"gruvbox\"\\]{[^}]*--base00:#1d2021;" css))
    (should (string-match-p "\\[data-scheme=\"gruvbox\"\\]\\[data-theme=\"light\"\\]{" css))
    (should-not (string-match-p "\"one-dark\"" css))
    (should-not (string-match-p "\"haki\"" css))))

(ert-deftest site-test-contrast-ratio-matches-wcag ()
  "Black on white is 21:1, and a colour against itself is 1:1."
  (should (< (abs (- (site-contrast-ratio "#000000" "#ffffff") 21)) 0.01))
  (should (= (site-contrast-ratio "#777777" "#777777") 1)))

(ert-deftest site-test-parse-author-splits-name-and-url ()
  (should (equal (site-parse-author "Dawid Kurek (https://example.com)")
                 (list :name "Dawid Kurek" :url "https://example.com")))
  (should (equal (site-parse-author "Just A Name") (list :name "Just A Name" :url ""))))

(ert-deftest site-test-parse-custom-css-schemes-reads-scheme-comment-convention ()
  "The @scheme comment convention (custom.css's own haki/haki-light blocks)
parses into all-schemes shape, dark and light kept as distinct entries."
  (let* ((css "/* @scheme: Haki | Dilip (https://example.com) | dark */
[data-scheme=\"haki\"] {
  --base00: #000000;
  --base01: #0a0f0a;
  --base02: #111c17;
  --base03: #b4aeae;
  --base04: #888888;
  --base05: #ffffff;
  --base06: #ffffff;
  --base07: #ffffff;
  --base08: #ffa9bf;
  --base09: #fab387;
  --base0A: #d0bc00;
  --base0B: #6ae4b9;
  --base0C: #5fd7af;
  --base0D: #2fafff;
  --base0E: #c9a0dc;
  --base0F: #a06060;
}
")
         (schemes (site-parse-custom-css-schemes css)))
    (should (= (length schemes) 1))
    (should (equal (plist-get (car schemes) :name) "Haki"))
    (should (equal (plist-get (car schemes) :author-name) "Dilip"))
    (should (equal (plist-get (car schemes) :author-url) "https://example.com"))
    (should (= (length (plist-get (car schemes) :colors)) 16))))

(ert-deftest site-test-parse-custom-css-schemes-terminates-on-multiple-blocks ()
  "Regression: with two or more @scheme blocks, `split-string'/`string-trim'
inside the loop body silently clobber the global match data the outer
`while' reads `match-end' from, which once left `start' stuck and made
this loop forever. Two real @scheme blocks (dark + light) must both come
back, not hang."
  (let* ((one "/* @scheme: One | Author One (https://one.example) | dark */
[data-scheme=\"one\"] {
  --base00: #000000; --base01: #000000; --base02: #000000; --base03: #000000;
  --base04: #000000; --base05: #000000; --base06: #000000; --base07: #000000;
  --base08: #000000; --base09: #000000; --base0A: #000000; --base0B: #000000;
  --base0C: #000000; --base0D: #000000; --base0E: #000000; --base0F: #000000;
}
")
         (two (replace-regexp-in-string "One" "Two" (replace-regexp-in-string "one" "two" one)))
         (schemes (with-timeout (5 (ert-fail "site-parse-custom-css-schemes did not terminate"))
                    (site-parse-custom-css-schemes (concat one two)))))
    (should (equal (mapcar (lambda (s) (plist-get s :key)) schemes) '("one" "two")))))

(ert-deftest site-test-all-schemes-merges-base16-and-custom ()
  "site-all-schemes appends custom (parsed) entries after every base16 one."
  (let ((all (site-all-schemes nil)))
    (should (= (length all) (length site-schemes-base16)))
    (should (cl-some (lambda (s) (equal (plist-get s :key) "gruvbox-dark-hard")) all))))

(ert-deftest site-test-schemes-json-is-valid-json-with-expected-shape ()
  "Curated families come first; every other entry is readable with 16 colours."
  (let* ((parsed (json-parse-string (site-schemes-json nil)))
         (other (seq-find (lambda (s) (not (gethash "family" s))) parsed)))
    (should (gethash "family" (aref parsed 0)))
    (should (stringp (gethash "name" other)))
    (should (= (length (gethash "colors" other)) 16))
    (should (site-scheme-readable-p (append (gethash "colors" other) nil)))))

(provide 'site-schemes-test)
;;; site-schemes-test.el ends here
