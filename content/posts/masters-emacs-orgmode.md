+++
title = "My MSc journey with Emacs Orgmode"
author = ["Dilip"]
date = 2025-06-06T00:00:00+05:30
tags = ["bioinformatics", "emacs", "pkm"]
draft = false
+++

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Note taking](#note-taking)
- [Reports/Doc](#reports-doc)
- [Presentations](#presentations)
- [Thesis](#thesis)
- [Conclusion](#conclusion)

</div>
<!--endtoc-->

**I wrote and used emacs orgmode for all of my post-grad Masters classes, presentations, projects and thesis.**

Before post-grad itself I was introduced to Emacs world and enjoyed getting good with it. As I used it, I realized emacs is not just an text editor, its an Personal Development Environment itself and user has power to craft it as they need. This was a worthwhile investment.

My initial plan when I started Masters (Bioinformatics) was to fully stay organized and be productive. I was a freak at this, I was reading up many blogs and digesting discussion on being productive. I even read books such as,

1.  Getting things Done
2.  How to Smart notes by Sonke Ahrens
    Introduces on Zettelkasten note-taking system. Although hyped up, I believe system does not function as brain.
3.  Deep Work by Cal Newport
    Insights on focused working and being distraction-less.
4.  Second Brain by Tiago Forte
    Again, whole thing about Zettelkasten. Popularized the term "Second brain" itself.
5.  Atomic Habits by James Clear
    Mentions on starting habits in small steps.
6.  A system for Writing by Bob Doto
    Latest book, emphasis on above all books and zettelkasten.

I could have been an normie student like others and be at ease, but why did I choose to burden with Emacs and Orgmode..?

I valued investment and growth. I could see the development and learning of skills compared to working with traditional GUI applications.


## Note taking {#note-taking}

Note-taking is understandable, its just format of text to store and read. And org-mode was superior and helped me alot.
I later on embraced single big org file, and started using tags heavily with context based tagging.

-   t -&gt; task;         t@shop t@meeting t@work
-   p -&gt; project;   p@plan p@lncrna p@thesis
-   l -&gt; learn;        l@nix l@python

So on which really helps with narrowing using consult package and org-ql for querying. I eventually formed my own second brain with org mode like an zettelkasten system. This became my personal knowledge management (PKM) as well which empowered me to stay organized.


## Reports/Doc {#reports-doc}

Org mode can produce pdf via latex or ODT/docx format. That eventually guided me for submission of assignments and documents for sharing.
Although it was an hassle to get formatting correct as they instructed, where as others just did them in breeze via M$ word and AI crap generated.

Although there was not much work with reports, I had good workflow of storing notes and working with integration and stayed organized.


## Presentations {#presentations}

I thought to give presentations in Emacs editor itself, but that did not make the cut for required normie friendly slides. The magically I came across revealJS and observed many people in tech presentations and talks used them. There was active development of org-reveal package as well, in new form from OER gitlab repo.

This workflow was definitely more painful, to get as they expect. The default works, but tweaking were more. But revealjs and org package provided many options and it sufficed for completing the setup along with power of HTML and CSS.

I had local.scss file for color and designing slides, and org generated html files.


## Thesis {#thesis}

The final saga of the journey, since thesis takes time to write, I thought to not bother with complicating this task. My initial thought was to either use Latex, if it was too much headache then simply follow given docx format file and write.
Thankfully there was another player getting really popular, a new typesetting "Typst". It did the magic and wonders.

The syntax and process was very robust and simple. The documentation was standard and was simple enough to grasp and tweak everything. And here was well someone had made basic org export support for typst format. Although IMHO typst syntax is so easy to understand and I loved to write and learn the syntax. Workflow was bliss with it, I wonder why I did not discover it earlier. Maybe I'm not a mathematician to have it for demand, but it was a good skill to have it in my hands.


## Conclusion {#conclusion}

The main draw from this experience was that investing in tools that allow extending and allow programming to customize and tweak as I require was a major win and good rewards. These were added up skills that makes working with related tasks a breeze ahead.
