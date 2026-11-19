NAME = wander

# Linting
# -------

chk:
	sed 's/ method="dialog"//' index.html > /tmp/tmp.html
	grep -q 'TESTING = false' index.html
	tidy -q -e --warn-proprietary-attributes no /tmp/tmp.html
	npx standard --plugin html --global wander index.html
	npx standard dev/

dep:
	npm install --no-save standard eslint-plugin-html
	if command -v brew; then brew install tidy-html5; fi


# Nifty Targets
# -------------

ls:
	git ls-tree -rl main; echo
	git ls-tree -rl wander; echo


# Manual Testing
# --------------

serve:
	python3 -m http.server

localhost:
	open http://localhost:8000/

message-injection-console:
	cp index.html dev/examples/message-injection-console/w.html
	open http://localhost:8000/dev/examples/message-injection-console/w.html || :

message-injection-page:
	cp index.html dev/examples/message-injection-page/w.html
	open dev/examples/message-injection-page/w.html || :

code-injection-console:
	cp index.html dev/examples/code-injection-console/w.html
	open dev/examples/code-injection-console/w.html || :


# Susam's Personal Make Targets
# -----------------------------

cc:
	git remote remove cc || :
	git remote add cc git@codeberg.org:susam/$(NAME).git
	git remote set-url cc --add git@github.com:susam/$(NAME).git
	git remote remove origin || :
	git remote add origin "$$(git remote get-url cc)"
	git remote -v
	git push -u origin main
	git push cc main

dist:
	git checkout main || :
	git branch -df wander || :
	git checkout -b wander
	git rm -rf *.md Makefile .gitignore dev/
	VER=$$(grep VERSION index.html | head -n 1 | cut -d "'" -f2); \
	git commit -m "Create distributable bundle for Wander Console $$VER"
	git push -f cc wander
	git checkout main
	git ls-tree -rl wander

cp:
	cp index.html ../susam.net/content/tree/wander/

PNG = ../blob/img/wander/wander.png

ss:
	osascript -e 'tell app "Chrome" to set bounds of front window to {0, 0, 1200, 730}'
	osascript -e 'tell app "Chrome" to activate'
	screencapture -w $(PNG)
	/Applications/ImageOptim.app/Contents/MacOS/ImageOptim $(PNG)
	open $(PNG)
