+++
title = "Nix: Home for Acer"
date = 2023-10-21
tags = ["linux", "nixos"]
draft = false
+++

In this post am sharing some of the experience of using my new laptop, **Acer swift Go Oled**. Compact, Premium ultra-book with Oled, Yes, a good hand made mobile laptop.

As expected and as usual, it got windows 11 and first major encounter was heating and battery issue. It got me scared as it felt wrong decision. Since many claimed windows gives better battery life than Linux. It gave me nightmare of installing Linux too, really, new laptop with 4-5 hours of battery, for oled with black screens?

Anyways, windows made me really tinker to my needs, went on with `winutils` and de-bloated few stuffs and made it somewhat tacit for me, then too I demanded more of it. To which windows felt weird and too much to handle. Thus did finally decide to dual boot or straightaway to erase disk for Linux. My first thought of choice was to use Arch with gnome, but since I had well maintained [nixos config](https://github.com/idlip/d-nix), I went with same config without much a-due.

Viola it gave me the exact setup I was looking for, enabling my hand to feel back in pace. Yet I was worried about battery and heating point of view, although many say, `laptops arent made to run on battery`, yet the heat? the air exhaust hitting my oled display directly?.

I gave a shot to `auto-cpufreq`, it did a well decent job, yet I felt too little gain, I did change `intel_pstate` to `acpu` one. All i noticed is it lowered the max frequency rate from 4.3GHz to 3.2GHz.

Later on after many rebuilds, I saw Nixos [wiki on laptop](https://nixos.wiki/wiki/Laptop), may seem outdated, but it was legit, and I did enable service such as `thermald`, `tlp` and viola later on I noticed it works well. Seriously I don't know how, it gave me better battery life, less heating in Linux (nixos) than windows. Maybe magical to me as others claim vice-versa.

Nonetheless, nixos handled the magics of services and making it a better experience by just writing one line of configs to `true;`. My desktop runs Hyprland (wayland) and it works flawlessly.

Okay, let me tell you about Finger Print, it gave me little trouble, and funny enough, it was again just to say `true;` on a line.

I have FP, so obviously I wanted to be cool looking by using it, I initially did not expect FP to work, again online poeple said so. I was following some debian/ubuntu help on FP and enabling some drivers and all, it did not work. Later I gotta know that `fprintd` latest one already has the support for my FP id, so just did enable `fprintd` and viola! viola!, now I login in TTY with FingerPrint.

Although I wasted some time one tinkering and making it to work on my needs, I was not doing work I wanted, thus decided to settle and do productive tasks from then on. Anyway, whatever you customize it will be little to no gain. That's why I decided to make and get my blog going, it is better to make one day each month or on boring holiday to do cleaning and customizing on OS.

Finally, It has become a pleasant experience to get nix and make it work as I expected on **Acer**.

Yet one thing remains unexplored, fan controlling. I see no mention of fan or <span class="underline">RPM</span> via `sensors` command, so one way is to check another tool. I skipped that part, since I don't face heating issue or high fan noise even when I'm plugged in.

Ultimately one more thing making all experience better is the **GOAT Emacs**. Bringing back my config and using it with more speed is another level of bliss.

This has become another embark of a journey, where the todo's are just piling even more, and it looks fun to explore more and utilize efficiently for learning.
