Developer Notes
===============

Release Checklist
-----------------

 1. Take screenshot if necessary:

    ```
    make ss
    ```

 3. Update copyright in [LICENCE.md][].
 4. Update [CHANGES.md][]
 5. Update version number in this file (1 place).
 6. Update version number in [index.html][] (2 places).
 7. Run the following commands:

    ```sh
    make checks
    git status
    git add -p
    ```

 8. Write release page on personal website:

    ```sh
    cd ~/git/susam.net/
    git checkout main
    em content/tree/code/news/wander/$VER.post.html
    ```

 9. Commit and push personal website.  Test.

10. Run the following commands:

    ```sh
    make checks
    git status
    git add -p
    ```

    ```sh
    VER=0.5.0
    git commit -m "Set version to $VER"
    git tag "$VER" -m "Wander $VER"
    make push
    git push cb "$VER"
    git push gh "$VER"
    make dist
    ```

11. Share on Mastodon.

12. Share on newsletter.

13. Share on IRC.

[LICENCE.md]: ../LICENCE.md
[CHANGES.md]: ../CHANGES.md
[index.html]: ../index.html
