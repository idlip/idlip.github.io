# Site tasks. Run `just` to list.

og_dir := "static/og"
favicon_size := "512"

# Dev server with drafts (refreshes OG images first).
serve: og
    hugo serve -D

# Build the minified site for deploy.
build:
    hugo --minify
    # og.svg is a build-time source only; never deployed.
    find public -name 'og.svg' -delete

# Rebuild OG images, then build for deploy.
release: og build

# Format everything treefmt knows about (.org excluded, no safe formatter for it).
fmt:
    treefmt

# Install git hooks (formatting on commit, a11y check on push).
setup:
    pre-commit install --hook-type pre-commit --hook-type pre-push

# a11y lint against the built output (Go templates aren't valid HTML pre-render).
a11y:
    hugo --minify
    htmlhint --config .htmlhintrc "public/**/*.html"

# Regenerate per-post OG PNGs from both public/ and public-denden/ (rsvg-convert).
og: _og-build _og-render

# Fresh build so stale og.svg from removed drafts don't linger.
_og-build:
    rm -rf public
    hugo

# Rasterize each og.svg to static/og/<slug>.png. Root page becomes home.
_og-render:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{og_dir}}
    slug() {
        local rel="$1"
        case "$rel" in
            public-denden/*) rel="${rel#public-denden/}" ;;
            public/*) rel="${rel#public/}" ;;
        esac
        local d; d="$(dirname "$rel")"
        [ "$d" = "." ] && echo home || basename "$d"
    }
    dirs=()
    [ -d public ] && dirs+=(public)
    [ -d public-denden ] && dirs+=(public-denden)
    n=0
    while IFS= read -r f; do
        rsvg-convert "$f" -o "{{og_dir}}/$(slug "$f").png"
        n=$((n + 1))
    done < <(find "${dirs[@]}" -name 'og.svg')
    echo "rasterized $n OG image(s) to {{og_dir}}"

# Regenerate the favicon set from any input
# Usage: just favicon ~/character.png zoro
favicon input name:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp --suffix=.png)"
    trap 'rm -f "$tmp"' EXIT
    magick "{{input}}" -resize {{favicon_size}}x{{favicon_size}} \
        -background none -gravity center -extent {{favicon_size}}x{{favicon_size}} "$tmp"
    cwebp -quiet -lossless "$tmp" -o "static/images/op-{{name}}.webp"
    magick "static/images/op-{{name}}.webp" -resize 32x32 static/images/favicon-32.png
    magick "static/images/op-{{name}}.webp" -resize 180x180 \
        -background none -gravity center -extent 180x180 static/images/apple-touch-icon.png
    magick "static/images/op-{{name}}.webp" -define icon:auto-resize=16,32,48 static/favicon.ico
    echo "generated static/images/op-{{name}}.webp + favicon-32.png + apple-touch-icon.png + favicon.ico"
    echo "set favicon: /images/op-{{name}}.webp under params in config.yaml to activate it"

# Denden (Emacs/Org migration)

denden_pub := "public-denden"
denden_elisp := "-Q -L denden -L site -L theme -l denden/denden.el -l site/site.el -l theme/theme.el"

# Real production build (public-denden/, idlip.in URLs) -- headless, for CI/deploy.
denden-build:
    emacs --batch {{denden_elisp}} \
        --eval '(setq denden-repository-directory "{{justfile_directory()}}")' \
        --eval '(site-build t)'

# Build, then serve public-denden/ locally: static-web-server, real or via `nix run`.
denden-serve: denden-build
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{denden_pub}}
    if command -v static-web-server >/dev/null 2>&1; then
        static-web-server --port 8000 --page404 404.html
    elif command -v nix >/dev/null 2>&1; then
        nix run nixpkgs#static-web-server -- --port 8000 --page404 404.html
    else
        python3 -m http.server 8000
    fi

# Run the denden/site/theme ERT suite.
denden-test:
    emacs --batch {{denden_elisp}} -l ert \
        $(find denden/test site/test theme/test -name '*.el' -printf '-l %p ') \
        -f ert-run-tests-batch-and-exit

# Byte-compile denden/site/theme, warnings visible, no .elc left behind.
denden-check:
    emacs --batch -L denden --eval '(setq byte-compile-warnings t)' -f batch-byte-compile denden/denden.el
    emacs --batch -L denden -L theme -l denden/denden.el \
        --eval '(setq byte-compile-warnings t)' -f batch-byte-compile theme/theme.el
    emacs --batch -L denden -L theme -L site -l denden/denden.el -l theme/theme.el \
        --eval '(setq byte-compile-warnings t)' -f batch-byte-compile site/site.el
    rm -f denden/*.elc site/*.elc theme/*.elc

gh_pages_branch := "gh-pages"
gh_pages_worktree := ".gh-pages-worktree"

# Make sure the gh-pages branch and its worktree (.gh-pages-worktree/,
# gitignored) exist. First call creates an empty gh-pages branch; every call
# is otherwise a no-op. The worktree is a real, independent checkout of
# gh-pages -- open it directly in magit (or any editor) to hand-edit,
# commit, and push, with no branch-switching in the main checkout at all.
denden-pages-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! git show-ref --verify --quiet "refs/heads/{{gh_pages_branch}}"; then
        empty_tree=$(git hash-object -t tree /dev/null)
        root_commit=$(git commit-tree "$empty_tree" -m "gh-pages root")
        git branch "{{gh_pages_branch}}" "$root_commit"
    fi
    if [ ! -d "{{gh_pages_worktree}}" ]; then
        git worktree add "{{gh_pages_worktree}}" "{{gh_pages_branch}}"
    fi

# Copy public-denden/ into the gh-pages worktree (deletes anything from a
# previous build/edit that the current build no longer writes). Does not
# commit or push -- inspect or hand-edit the worktree first if you want to,
# then run `just denden-pages-push` when you're ready.
denden-pages-sync: denden-pages-setup
    # NOTE: the exclude pattern must be `.git`, not `.git/` -- a worktree's
    # .git is a plain FILE (a pointer back into the main repo), and rsync's
    # trailing-slash exclude only matches directories. `.git/` here silently
    # deletes that file, which breaks every git command run in the worktree
    # afterwards (they fall through to the main repo's .git instead).
    rsync -a --delete --exclude .git {{denden_pub}}/ {{gh_pages_worktree}}/

# Commit and force-push whatever is currently in the gh-pages worktree,
# however it got there (denden-pages-sync, or your own hand edits via
# magit). Force-push is safe here: nothing else ever writes to gh-pages.
denden-pages-push:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{gh_pages_worktree}}
    git add -A
    if git diff --cached --quiet; then
        echo "denden-pages-push: nothing changed, not pushing"
        exit 0
    fi
    git commit -m "deploy $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin {{gh_pages_branch}} --force

# Build, sync, and push in one go -- the common case.
denden-deploy: denden-build denden-pages-sync denden-pages-push
