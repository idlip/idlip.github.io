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
 5. Update version number in this file (2 places).
 6. Update version number in [index.html][] (2 places).
 7. Run the following commands:

    ```sh
    make chk
    git status
    git add -p
    ```

 8. Copy updated tool to website:

    ```sh
    make cp
    ```

 9. Write release page on personal website:

    ```sh
    VER=0.6.0
    cd ../susam.net/
    git checkout main
    em content/tree/code/news/wander/$VER.post.html
    ```

10. Commit and push personal website.

11. Confirm <https://susam.net/wander/> works successfully.

12. Run the following commands:

    ```sh
    make chk
    git status
    git add -p
    ```

    ```sh
    VER=0.6.0
    git commit -m "Set version to $VER"
    git tag "$VER" -m "Wander $VER"
    make push
    git push cb "$VER"
    git push gh "$VER"
    make dist
    ```

13. Share on Mastodon.

14. Share on newsletter.

15. Share on IRC.

[LICENCE.md]: ../LICENCE.md
[CHANGES.md]: ../CHANGES.md
[index.html]: ../index.html
