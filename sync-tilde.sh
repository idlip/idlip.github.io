#!/usr/bin/env bash

# To sync it with tildevarsh and make it clone of github deployment

hugo &&
rsync --delete -vae ssh public/* idlip@tildevarsh.in:~/public_html &&
rm -rf public &&
git push

exit 0
