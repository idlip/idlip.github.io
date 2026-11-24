# idlip.in tasks. Run `just` to list them.

public := "public-denden"
port := "7777"
site := "emacs --batch -Q -L denden -L site -L theme -l site/site.el"

# Build the site into public-denden/.
build:
    {{site}} --eval '(denden-build idlip-site)'

# Rebuild on every change, with drafts and local addresses. Serve it with `just web`.
dev:
    #!/usr/bin/env bash
    set -euo pipefail
    watch=(--watch content --watch site --watch theme --watch denden/denden.el
           --watch assets --watch static --debounce 500ms -- just _dev-build)
    if command -v watchexec >/dev/null; then
        watchexec "${watch[@]}"
    else
        nix run nixpkgs#watchexec -- "${watch[@]}"
    fi

_dev-build:
    DENDEN_PREVIEW_BASE_URL=http://localhost:{{port}}/ {{site}} \
        --eval '(setq denden-include-drafts t)' --eval '(denden-build idlip-site)'

# Serve public-denden/ at http://localhost:7777. Run it in its own terminal.
web:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v static-web-server >/dev/null; then
        static-web-server --root {{public}} --port {{port}}
    else
        nix run nixpkgs#static-web-server -- --root {{public}} --port {{port}}
    fi

# Build, then publish public-denden/ on the gh-pages branch.
deploy: build
    #!/usr/bin/env bash
    set -euo pipefail
    worktree=.gh-pages-worktree
    [ -d "$worktree" ] || git worktree add "$worktree" gh-pages
    # Exclude .git, not .git/: in a worktree, .git is a file.
    rsync -a --delete --exclude .git {{public}}/ "$worktree"/
    cp CNAME "$worktree"/CNAME
    cd "$worktree"
    git add -A
    if git diff --cached --quiet; then
        echo "deploy: nothing changed"
    else
        git commit -m "deploy $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        git push origin gh-pages --force
    fi

# Turn each og.svg of the last build into static/og/NAME.png.
og:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p static/og
    count=0
    while IFS= read -r card; do
        folder=$(dirname "${card#{{public}}/}")
        name=$([ "$folder" = . ] && echo home || basename "$folder")
        rsvg-convert "$card" -o "static/og/$name.png"
        count=$((count + 1))
    done < <(find {{public}} -name og.svg)
    echo "og: $count cards in static/og"

# Run every test.
test:
    emacs --batch -Q -L denden -L denden/example -L site -L theme -l ert \
        $(find denden/test site/test theme/test -name '*-test.el' -printf '-l %p ') \
        -f ert-run-tests-batch-and-exit

# Byte-compile with warnings as errors, lint the engine, then test.
check: && test
    #!/usr/bin/env bash
    set -euo pipefail
    trap 'rm -f denden/*.elc site/*.elc theme/*.elc' EXIT
    emacs --batch -Q -L denden -L site -L theme --eval '(setq byte-compile-error-on-warn t)' \
        -f batch-byte-compile denden/denden.el theme/theme.el site/site.el
    checkdoc=$(emacs --batch -Q --eval '(checkdoc-file "denden/denden.el")' 2>&1)
    [ -z "$checkdoc" ] || { echo "$checkdoc"; exit 1; }
    emacs --batch -Q -L denden -l tools/lint/package-lint.el \
        --eval '(setq package-lint-main-file "denden/denden.el")' \
        -f package-lint-batch-and-exit denden/denden.el
    emacs --batch -Q -L denden -l tools/lint/xr.el -l tools/lint/relint.el \
        -f relint-batch denden/denden.el

# Format CSS, JS, JSON and YAML with treefmt.
format:
    treefmt

# Make the favicons from an image. Usage: just favicon ~/zoro.png zoro
favicon image name:
    #!/usr/bin/env bash
    set -euo pipefail
    square=$(mktemp --suffix=.png)
    trap 'rm -f "$square"' EXIT
    magick "{{image}}" -resize 512x512 -background none -gravity center -extent 512x512 "$square"
    cwebp -quiet -lossless "$square" -o "static/images/op-{{name}}.webp"
    magick "static/images/op-{{name}}.webp" -resize 32x32 static/images/favicon-32.png
    magick "static/images/op-{{name}}.webp" -resize 180x180 -background none \
        -gravity center -extent 180x180 static/images/apple-touch-icon.png
    magick "static/images/op-{{name}}.webp" -define icon:auto-resize=16,32,48 static/favicon.ico
    echo "favicon: set site-favicon-relative-path in site/site.el to images/op-{{name}}.webp"

# Install the git hooks.
setup:
    pre-commit install --hook-type pre-commit --hook-type pre-push
