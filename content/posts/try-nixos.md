+++
title = "NixOS : Reproducible - Immutable"
date = 2023-03-23T00:00:00+05:30
tags = ["emacs", "distro", "linux", "nixos"]
draft = false
+++

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- ["Should you try NixOS?" ❄️](#should-you-try-nixos-️)
- [How I manage my system 🌲](#how-i-manage-my-system)
    - [Credits 🎖️](#credits-️)

</div>
<!--endtoc-->

---

Introduction part, you would better have read it on official nixos site (<https://nixos.org>)


## "Should you try NixOS?" ❄️ {#should-you-try-nixos-️}

Here's an answer from a non-programmer, who just browses and watches media.
Just don't, if you are looking for small benefit. **Don't!**
 regret having hard time to figure out petty things, again forget about error, you cannot even search in web.

But, if you have decided, go with it. According to me (non-programmer), these points are good to consider NixOS

-   You use Emacs (lol), **Emacs** ❤️  **Nix** is Match made in Heaven.
-   You want to declare stuffs and get same output, and forget what all you setup, cause its all declared in config.
-   You want an isolated environments (shell) to do some stuffs without involving whole system.
-   You want to stop troubleshooting and breaking update and are lazy to backup, and want to rollback with ease like with just a reboot.
-   You want to say I use **Nixos Btw**.
-   You don't want to worry about breaking your system nor fix something when you are updating system.
-   You are willing to learn (advanced) things and fine with steep learning curve.

---


## How I manage my system 🌲 {#how-i-manage-my-system}

I manage my whole system with single org file. Its easy and pretty handy. You can read that file here **↬** [d-setup.org](https://github.com/idlip/d-nix/blob/onepiece/d-setup.org) , its both self documenting and has all source code blocks.

Another key feature in my setup is, every file i tangle is at **read-only mode**. So generally we can avoid editing/touching them. Thus, every action has to be made in **d-setup.org** only.

Also, I have made files to be **symlink**, so i can edit them without requiring to rebuild whole thing!

---


### Credits 🎖️ {#credits-️}

These configs were the inspiration and helped to build this way.

I thank them sincerely.

[Iron Shark](https://github.com/Iron-Shark/Technonomicon) **⟹** Made migrating to Single org-file config very easy.

[Sioodmy](https://github.com/sioodmy/dotfiles) **⟹** First config which I understand thoroughly and modified based on this.

---
