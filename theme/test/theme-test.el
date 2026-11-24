;;; theme-test.el --- Tests for the templates of theme.el -*- lexical-binding: t; -*-

;;; Commentary:

;; Render single templates and check the HTML they make.

;;; Code:

(require 'ert)
(require 'denden)
(require 'theme)

(ert-deftest theme-test-post-header ()
  "The post header shows the date, the update date when it differs, and tags."
  (let ((html (denden-serialize-node
               (theme-post-header :title "T" :date (date-to-time "2026-01-05")
                                  :lastmod (date-to-time "2026-02-01")
                                  :word-count 400 :reading-time 2 :tags '("emacs")))))
    (should (string-search "<h1>T</h1>" html))
    (should (string-search " · updated <time datetime=\"2026-02-01\">" html))
    (should (string-search "2 min read (400 words)" html))
    (should (string-search "<a href=\"/tags/emacs/\">#emacs</a>" html))))

(ert-deftest theme-test-terms-list ()
  "Terms are listed alphabetically with their counts."
  (let ((html (denden-serialize-node
               (theme-terms-list :title "Tags" :term-counts '(("org" . 1) ("emacs" . 2))))))
    (should (< (string-search "#emacs" html) (string-search "#org" html)))
    (should (string-search "2 posts" html))
    (should (string-search "1 post<" html))))

(ert-deftest theme-test-social-links ()
  "A mail link opens in place; other links open in a new tab."
  (let ((html (denden-serialize-node
               (theme-social-links-grid '((:label "mail" :url "mailto:a@b.c" :icon "x")
                                          (:label "site" :url "https://b.c" :icon "y" :rel "me"))))))
    (should (string-search "<a href=\"mailto:a@b.c\">" html))
    (should (string-search "target=\"_blank\" rel=\"noopener noreferrer me\"" html))))

(ert-deftest theme-test-topic-part-chip ()
  "A chip with no value is dropped; an unused ref is plain text."
  (should-not (theme--topic-part-chip '(:key "author" :value "") nil))
  (should (equal (theme--topic-part-chip '(:key "refs" :value "book") nil)
                 '(span nil "@book"))))

(ert-deftest theme-test-baseof ()
  "The page shell writes the title, the head nodes and the main part."
  (let ((html (denden-serialize-node
               (theme-baseof :language "en" :body '(p nil "hi") :page-title "Hello"
                             :head-nodes '((meta (:name "x" :content "y")))))))
    (should (string-search "<title>Hello</title>" html))
    (should (string-search "<meta name=\"x\" content=\"y\" />" html))
    (should (string-search "<main id=\"main\"><p>hi</p></main>" html))))

(provide 'theme-test)
;;; theme-test.el ends here
