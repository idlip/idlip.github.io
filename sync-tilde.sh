#!/usr/bin/env bash

# To sync it with tildevarsh and made it clone of github deployment

hugo &&
    rsync --delete -vae ssh public/* idlip@tildevarsh.in:~/public_html &&
    rm -rf public

exit 0
