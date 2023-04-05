+++
title = "Vim Proficiency"
date = 2023-04-05
tags = ["minimal", "keybindings", "cheatsheet", "vim"]
draft = false
+++

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Marks](#marks)
- [Navigation](#navigation)
- [Jumping](#jumping)
- [Counters](#counters)
- [Tags](#tags)
- [Folds](#folds)
- [Command line](#command-line)
- [Spell checking](#spell-checking)

</div>
<!--endtoc-->

Although I don't use vim, it has good points for being easy **keyboard glue**. Why not learn both of the best worlds of Editors?

Apart from normal vim navigations and operators, These are some of the unique vim magics, which I haven't used at all.


## Marks {#marks}

This is the important one, I have not used this at all. Should try and make use of it. Although emacs `mark-ring` is alot better.

| Shortcut    | Description                                          |
|-------------|------------------------------------------------------|
| `` `^ ``    | Last position of cursor in insert mode               |
| `` `. ``    | Last change in current buffer                        |
| `` `" ``    | Last exited current buffer                           |
| `` `0 ``    | In last file edited                                  |
| `''`        | Back to line in current buffer where jumped from     |
| `` `` ``    | Back to position in current buffer where jumped from |
| `` `[ ``    | To beginning of previously changed or yanked text    |
| `` `] ``    | To end of previously changed or yanked text          |
| `` `< ``    | To beginning of last visual selection                |
| `` `> ``    | To end of last visual selection                      |
| `ma`        | Mark this cursor position as `a`                     |
| `` `a ``    | Jump to the cursor position `a`                      |
| `'a`        | Jump to the beginning of the line with position `a`  |
| `d'a`       | Delete from current line to line of mark `a`         |
| ``d`a``     | Delete from current position to position of mark `a` |
| `c'a`       | Change text from current line to line of `a`         |
| ``y`a``     | Yank text from current position to position of `a`   |
| `:marks`    | List all current marks                               |
| `:delm a`   | Delete mark `a`                                      |
| `:delm a-d` | Delete marks `a`, `b`, `c`, `d`                      |
| `:delm abc` | Delete marks `a`, `b`, `c`                           |

---


## Navigation {#navigation}

| Shortcut       | Description                |
|----------------|----------------------------|
| `%`            | Nearest/matching `{[()]}`  |
| `[(` `[{` `[<` | Previous `(` or `{` or `<` |
| `])`           | Next                       |
| `[m`           | Previous method start      |
| `[M`           | Previous method end        |

---


## Jumping {#jumping}

| Shortcut | Description                  |
|----------|------------------------------|
| `<C-O>`  | Go back to previous location |
| `<C-I>`  | Go forward                   |
| `gf`     | Go to file in cursor         |

---


## Counters {#counters}

| Shortcut | Description      |
|----------|------------------|
| `<C-A>`  | Increment number |
| `<C-X>`  | Decrement        |

---


## Tags {#tags}

| Shortcut             | Description                                     |
|----------------------|-------------------------------------------------|
| `:tag Classname`     | Jump to first definition of Classname           |
| `<C-]>`              | Jump to definition                              |
| `g]`                 | See all definitions                             |
| `<C-T>`              | Go back to last tag                             |
| `<C-O> <C-I>`        | Back/forward                                    |
| `:tselect Classname` | Find definitions of Classname                   |
| `:tjump Classname`   | Find definitions of Classname (auto-select 1st) |

---


## Folds {#folds}

| Shortcut      | Description                  |
|---------------|------------------------------|
| `zo` _/_ `zO` | Open                         |
| `zc` _/_ `zC` | Close                        |
| `za` _/_ `zA` | Toggle                       |
| `zv`          | Open folds for this line     |
| `zM`          | Close all                    |
| `zR`          | Open all                     |
| `zm`          | Fold more _(foldlevel += 1)_ |
| `zr`          | Fold less _(foldlevel -= 1)_ |
| `zx`          | Update folds                 |

---


## Command line {#command-line}

| Shortcut     | Description                               |
|--------------|-------------------------------------------|
| `<C-R><C-W>` | Insert current word into the command line |
| `<C-R>"`     | Paste from ” register                     |
| `<C-X><C-F>` | Auto-completion of path in insert mode    |

---


## Spell checking {#spell-checking}

| Shortcut                     | Description                                            |
|------------------------------|--------------------------------------------------------|
| `:set spell spelllang=en_us` | Turn on US English spell checking                      |
| `]s`                         | Move to next misspelled word after the cursor          |
| `[s`                         | Move to previous misspelled word before the cursor     |
| `z=`                         | Suggest spellings for the word under/after the cursor  |
| `zg`                         | Add word to spell list                                 |
| `zw`                         | Mark word as bad/mispelling                            |
| `zu` / `C-X (Insert Mode)`   | Suggest words for bad word under cursor from spellfile |

See `:help spell`

---

With that noted, I hope you turn out to be a proficient _**Vimmer**_ or an efficient _**Emacser**_

For emacs, I have my previous post for it.
