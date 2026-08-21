# Site tasks. Run `just` to list.

og_dir := "static/og"

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

# Regenerate per-post OG PNGs (run inside nix-shell for rsvg-convert).
og: _og-build _og-render

# Fresh build so stale og.svg from removed drafts don't linger.
_og-build:
    rm -rf public
    hugo

# Rasterize each og.svg to static/og/<slug>.png; root page becomes home.
_og-render:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{og_dir}}
    slug() { local d; d="$(dirname "${1#public/}")"; [ "$d" = "." ] && echo home || basename "$d"; }
    n=0
    while IFS= read -r f; do
        rsvg-convert "$f" -o "{{og_dir}}/$(slug "$f").png"
        n=$((n + 1))
    done < <(find public -name 'og.svg')
    echo "rasterized $n OG image(s) to {{og_dir}}"
