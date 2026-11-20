/* ---- site.js ---- */
/**
 * Small progressive enhancements. The page reads fine without any of this:
 * controls that need JS render with the hidden attribute and data-requires-js,
 * and are revealed here.
 */
(function () {
  "use strict";

  var root = document.documentElement;

  var BASE_KEYS = [
    "base00",
    "base01",
    "base02",
    "base03",
    "base04",
    "base05",
    "base06",
    "base07",
    "base08",
    "base09",
    "base0A",
    "base0B",
    "base0C",
    "base0D",
    "base0E",
    "base0F",
  ];

  var FONT_MODES = [
    { value: "mixed", label: "Mixed" },
    { value: "serif", label: "Serif" },
    { value: "sans", label: "Sans" },
    { value: "mono", label: "Mono" },
    { value: "default", label: "Browser default" },
  ];

  var WIDTHS = [
    { value: "52rem", label: "Normal" },
    { value: "72rem", label: "Wide" },
    { value: "100%", label: "Full" },
    { value: "40rem", label: "Narrow" },
  ];

  // ── Scheme, font, width, dark/light (the pre-paint script in <head> already applied the stored choices) ──

  // Show MESSAGE in the popover toast for a moment; it has role=status, so screen readers hear it too.
  var toastTimer = null;
  function announce(message) {
    var toast = document.querySelector(".toast");
    if (!toast) return;
    if (toast.showPopover && !toast.matches(":popover-open")) toast.showPopover();
    toast.textContent = message;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      if (toast.hidePopover && toast.matches(":popover-open")) toast.hidePopover();
    }, 2500);
  }

  // Set the 16 base colours inline (a missing colour clears its slot); readPalette snapshots them.
  function setPalette(colors) {
    BASE_KEYS.forEach(function (key, index) {
      if (colors[index]) root.style.setProperty("--" + key, colors[index]);
      else root.style.removeProperty("--" + key);
    });
  }

  function readPalette() {
    return BASE_KEYS.map(function (key) { return root.style.getPropertyValue("--" + key); });
  }

  function applyScheme(name, label) {
    setPalette([]);
    localStorage.removeItem("emacs-custom-palette");
    if (name) root.setAttribute("data-scheme", name);
    else root.removeAttribute("data-scheme");
    localStorage.setItem("emacs-scheme-fixed", name);
    applyVariant();
    if (label) announce("Scheme: " + label);
  }

  // The pre-paint script defines the variant rule: stored choice, else the system, limited to what the scheme has.
  function applyVariant() {
    if (window.__applyVariant) window.__applyVariant();
    saveWanderColors();
  }

  function next(list, current) {
    var index = list.findIndex(function (item) {
      return item.value === current;
    });
    return list[(index + 1) % list.length];
  }

  function applyFont(mode) {
    root.setAttribute("data-font", mode);
    localStorage.setItem("emacs-font-mode", mode);
    var entry = FONT_MODES.find(function (item) {
      return item.value === mode;
    });
    labelButton("cycle-font", "Font mode: " + (entry ? entry.label : mode));
  }

  function cycleFont() {
    applyFont(next(FONT_MODES, root.getAttribute("data-font") || "mixed").value);
  }

  function cycleWidth() {
    var current = root.style.getPropertyValue("--measure") || WIDTHS[0].value;
    var width = next(WIDTHS, current);
    root.style.setProperty("--measure", width.value);
    localStorage.setItem("emacs-width", width.value);
    labelButton("cycle-width", "Content width: " + width.label);
  }

  // A scheme without the wanted variant would not change; then put the old choice back and offer the scheme list.
  function toggleTheme() {
    var wanted = root.getAttribute("data-theme") === "light" ? "dark" : "light";
    var before = getComputedStyle(root).getPropertyValue("--base00");
    var stored = localStorage.getItem("emacs-theme");
    localStorage.setItem("emacs-theme", wanted);
    applyVariant();
    if (
      root.getAttribute("data-theme") !== wanted ||
      getComputedStyle(root).getPropertyValue("--base00") === before
    ) {
      if (stored) localStorage.setItem("emacs-theme", stored);
      else localStorage.removeItem("emacs-theme");
      applyVariant();
      announce("This scheme has no " + wanted + " variant. Pick another scheme.");
      if (window.emacsBlog.palette) window.emacsBlog.palette.open("t ");
      return;
    }
    labelButton("toggle-theme", "Dark or light: " + wanted);
  }

  // ── Site title: a new random quote in its tooltip on every hover or focus ──

  // Wraps a quote in its toast; any glyph or emoji works here.
  var QUOTE_MARK = "\u{F075A}";

  function initTitleQuotes() {
    var title = document.querySelector(".site-title[data-quotes]");
    if (!title) return;
    var quotes = JSON.parse(title.dataset.quotes);
    function pick() {
      title.title = quotes[Math.floor(Math.random() * quotes.length)];
    }
    title.addEventListener("pointerenter", pick);
    title.addEventListener("focus", pick);
    // A click leaves the page, so the quote rides along and greets the reader on the next one.
    title.addEventListener("click", function () {
      if (!title.title) pick();
      sessionStorage.setItem("emacs-title-quote", title.title);
    });
    var carried = sessionStorage.getItem("emacs-title-quote");
    if (carried) {
      sessionStorage.removeItem("emacs-title-quote");
      announce(QUOTE_MARK + " " + carried + " " + QUOTE_MARK);
    }
  }

  function labelButton(action, label) {
    var button = document.querySelector('.toolbar [data-action="' + action + '"]');
    if (button) {
      button.setAttribute("aria-label", label);
      button.title = label;
    }
    announce(label);
  }

  var ACTIONS = {
    "open-palette": function () {
      window.emacsBlog.palette && window.emacsBlog.palette.open();
    },
    "open-schemes": function () {
      window.emacsBlog.palette && window.emacsBlog.palette.open("t ");
    },
    "cycle-font": cycleFont,
    "cycle-width": cycleWidth,
    "toggle-theme": toggleTheme,
    "random-page": randomPage,
    "toggle-keys": toggleKeys,
    // Older names still used by buttons inside content pages.
    "browse-schemes": function () {
      ACTIONS["open-schemes"]();
    },
  };

  // ── Keyboard: x, Ctrl/Cmd-K, Ctrl/Cmd-S, Alt-X open the palette (WCAG 2.1.4: x can be turned off) ──

  function toggleKeys() {
    if (localStorage.getItem("emacs-keys-off")) localStorage.removeItem("emacs-keys-off");
    else localStorage.setItem("emacs-keys-off", "1");
    announce(
      localStorage.getItem("emacs-keys-off") ? "The x shortcut is off" : "The x shortcut is on",
    );
  }

  function typing(target) {
    return target.closest("input, textarea, select, [contenteditable]");
  }

  function handleKeydown(e) {
    if (typing(e.target)) return;
    var palette = window.emacsBlog.palette;
    if (!palette) return;
    if (
      ((e.ctrlKey || e.metaKey) && (e.code === "KeyK" || e.code === "KeyS")) ||
      (e.altKey && e.code === "KeyX")
    ) {
      palette.open();
      e.preventDefault();
    } else if (
      e.key === "x" &&
      !e.ctrlKey &&
      !e.metaKey &&
      !e.altKey &&
      !localStorage.getItem("emacs-keys-off")
    ) {
      palette.open();
      e.preventDefault();
    }
  }

  // ── The one list filter: an input[data-filter] hides rows ([data-filter-text]) inside its target ──
  // Every query word must appear, in any order. A <section> with no visible rows hides too.

  function initFilter(input) {
    var box = document.getElementById(input.dataset.filter);
    if (!box) return;
    var rows = box.querySelectorAll("[data-filter-text]");
    var status = input.parentElement.querySelector("output");

    function run() {
      var words = input.value.toLowerCase().split(/\s+/).filter(Boolean);
      var shown = 0;
      rows.forEach(function (row) {
        var text = row.dataset.filterText;
        row.hidden = !words.every(function (word) {
          return text.indexOf(word) !== -1;
        });
        if (!row.hidden) shown++;
      });
      box.querySelectorAll("section").forEach(function (section) {
        section.hidden = !section.querySelector("[data-filter-text]:not([hidden])");
      });
      if (status) status.textContent = words.length ? shown + " of " + rows.length : "";
    }

    input.addEventListener("input", run);
    input.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        input.value = "";
        run();
        input.blur();
      }
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "/" && !typing(e.target) && !document.querySelector("dialog[open]")) {
        e.preventDefault();
        input.focus();
        input.select();
      }
    });
  }

  // ── List views: the radios work through CSS :has(); this only remembers the choice ──

  function initViews() {
    var saved = localStorage.getItem("emacs-list-view");
    document.querySelectorAll('input[name="list-view"]').forEach(function (radio) {
      if (radio.value === saved) radio.checked = true;
      radio.addEventListener("change", function () {
        localStorage.setItem("emacs-list-view", radio.value);
        announce("View: " + radio.getAttribute("aria-label"));
      });
    });
  }

  // ── Comment box: mail the text with the subject already filled in ──

  function initComment(form) {
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var body = form.elements.body.value;
      location.href =
        "mailto:" +
        form.dataset.email +
        "?subject=" +
        encodeURIComponent(form.dataset.subject) +
        (body ? "&body=" + encodeURIComponent(body) : "");
    });
  }

  // ── Wander console: same origin, so it reads these saved colours (see site--wander-colors-script) ──

  var WANDER_COLORS = {
    "--wt-bg": "--background",
    "--wt-bg-dim": "--surface",
    "--wt-bg-alt": "--base02",
    "--wt-fg": "--text",
    "--wt-fg-dim": "--text-faint",
    "--wt-border": "--border",
    "--wt-error": "--red",
  };

  function saveWanderColors() {
    var style = getComputedStyle(root);
    var colors = {};
    Object.keys(WANDER_COLORS).forEach(function (name) {
      colors[name] = style.getPropertyValue(WANDER_COLORS[name]).trim();
    });
    localStorage.setItem("emacs-wander-colors", JSON.stringify(colors));
    return colors;
  }

  function shareColors(iframe) {
    try {
      var colors = saveWanderColors();
      var target = iframe.contentDocument.documentElement;
      Object.keys(colors).forEach(function (name) {
        target.style.setProperty(name, colors[name]);
      });
    } catch (e) {}
  }

  // ── Random: jump to any page or post from the palette data ──

  function randomPage() {
    var pages = (window.__posts || []).filter(function (page) {
      return page.url !== location.pathname;
    });
    if (pages.length) location.href = pages[Math.floor(Math.random() * pages.length)].url;
  }

  // ── Dialog links: a[data-dialog] opens that dialog; its iframe loads on first open ──

  function initDialogLink(link) {
    var dialog = document.getElementById(link.dataset.dialog);
    if (!dialog) return;
    var iframe = dialog.querySelector("iframe[data-src]");
    link.addEventListener("click", function (e) {
      e.preventDefault();
      if (iframe && !iframe.getAttribute("src")) iframe.src = iframe.dataset.src;
      else if (iframe) shareColors(iframe);
      dialog.showModal();
    });
    dialog.addEventListener("click", function (e) {
      if (e.target === dialog) dialog.close();
    });
  }

  // ── Pose: following a link to an entry opens its folded details ──

  function openTargetDetails() {
    var target =
      location.hash && document.getElementById(decodeURIComponent(location.hash.slice(1)));
    var details = target && target.closest("details");
    if (details) details.open = true;
  }

  function init() {
    document.querySelectorAll("[data-requires-js]").forEach(function (el) {
      el.hidden = false;
    });
    document.querySelectorAll("[data-action]").forEach(function (button) {
      var action = ACTIONS[button.dataset.action];
      if (action) button.addEventListener("click", action);
    });
    document.addEventListener("keydown", handleKeydown);
    document.querySelectorAll("input[data-filter]").forEach(initFilter);
    document.querySelectorAll("form.comment").forEach(initComment);
    document.querySelectorAll("a[data-dialog]").forEach(initDialogLink);
    window.addEventListener("hashchange", openTargetDetails);
    openTargetDetails();
    initTitleQuotes();
    initViews();
    saveWanderColors();
  }

  window.emacsBlog = window.emacsBlog || {};
  window.emacsBlog.site = {
    applyScheme: applyScheme,
    setPalette: setPalette,
    readPalette: readPalette,
    applyVariant: applyVariant,
    announce: announce,
    applyFont: applyFont,
    cycleWidth: cycleWidth,
    randomPage: randomPage,
    toggleTheme: toggleTheme,
    toggleKeys: toggleKeys,
    FONT_MODES: FONT_MODES,
  };

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();

/* ---- search.js ---- */
/**
 * Full-text search over /search-index.json, one entry per sentence.
 * Orderless: every query word must appear in some token.
 */
(function () {
  "use strict";

  var index = null,
    loading = false;

  function load(onReady) {
    if (index || loading) return;
    loading = true;
    fetch("/search-index.json")
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        index = data;
        loading = false;
        onReady();
      })
      .catch(function () {
        index = [];
        loading = false;
      });
  }

  function find(q) {
    if (!index) return [];
    var words = q.toLowerCase().split(/\s+/).filter(Boolean);
    if (!words.length) return [];
    return index
      .filter(function (item) {
        var lo = item.text.toLowerCase();
        return words.every(function (w) {
          return lo.indexOf(w) !== -1;
        });
      })
      .map(function (item) {
        return {
          title: item.title,
          url: item.url,
          snippet: item.text,
          hit: item.text,
        };
      });
  }

  window.emacsBlog = window.emacsBlog || {};
  window.emacsBlog.search = { load: load, find: find };
})();

/* ---- palette.js ---- */
/**
 * Command Palette — native <dialog>.
 * Default: commands, pages, tags and full-text results. "t " prefix: colour schemes.
 * Trigger: x / Ctrl-K / Ctrl-S / Alt-X (site.js) or window.emacsBlog.palette.open()
 */
(function () {
  "use strict";

  var dlg = document.getElementById("palette-dialog");
  var inp = document.getElementById("palette-input");
  var res = document.getElementById("palette-results");
  if (!dlg || !inp || !res) return;

  var ICONS = window.__paletteIcons || {};

  // Section navigation from the site menu (window.__nav), so it stays in sync.
  var NAV = (window.__nav || []).map(function (n) {
    return {
      t: n.name,
      type: "nav",
      a: function () {
        goTo(n.url);
      },
    };
  });

  function command(title, action) {
    return {
      t: title,
      type: "command",
      a: function () {
        dlg.close();
        action();
      },
    };
  }

  function prefixMode(title, type, prefix) {
    return {
      t: title,
      type: type,
      a: function () {
        inp.value = prefix;
        render(prefix);
        inp.focus();
        inp.setSelectionRange(prefix.length, prefix.length);
      },
    };
  }

  var site = window.emacsBlog.site;
  var CMDS = NAV.concat(
    [
      prefixMode("Browse all color schemes", "scheme", "t "),
      command("Default color scheme (Haki)", function () {
        site.applyScheme("haki", "Haki");
      }),
    ],
    site.FONT_MODES.map(function (mode) {
      return command("Font: " + mode.label, function () {
        site.applyFont(mode.value);
      });
    }),
    [
      command("Random page", function () {
        site.randomPage();
      }),
      command("Toggle dark / light", function () {
        site.toggleTheme();
      }),
      command("Cycle content width", function () {
        site.cycleWidth();
      }),
      command("Enable / disable the x shortcut", function () {
        site.toggleKeys();
      }),
    ],
  );

  var idx = 0,
    items = [];
  var allSchemes = null,
    snap = null;
  var searchTimer = null;

  // Picking the page you're already on can't navigate anywhere, so close the dialog instead.
  function goTo(url) {
    if (url === location.pathname) dlg.close();
    else location.href = url;
  }

  function snapRestore() {
    if (snap) site.setPalette(snap);
    snap = null;
  }

  function esc(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
  }

  // Marks whichever of `words` occur in `str`, best-effort (no all-present check).
  function highlightWords(str, words) {
    var lo = str.toLowerCase(),
      m = new Uint8Array(str.length),
      r = "",
      in_ = false;
    words.forEach(function (w) {
      var i = lo.indexOf(w);
      while (i >= 0) {
        m.fill(1, i, i + w.length);
        i = lo.indexOf(w, i + 1);
      }
    });
    for (var i = 0; i < str.length; i++) {
      if (m[i] && !in_) {
        r += "<mark>";
        in_ = true;
      } else if (!m[i] && in_) {
        r += "</mark>";
        in_ = false;
      }
      r += esc(str[i]);
    }
    return in_ ? r + "</mark>" : r;
  }

  function match(str, q) {
    if (!q) return esc(str);
    var lo = str.toLowerCase(),
      tokens = q.toLowerCase().split(/\s+/).filter(Boolean);
    if (
      !tokens.every(function (t) {
        return lo.includes(t);
      })
    )
      return null;
    return highlightWords(str, tokens);
  }

  function buildList() {
    res.innerHTML = items.length
      ? items
          .map(function (it, i) {
            var ic = it.type && ICONS[it.type];
            return (
              '<div class="palette-item' +
              (i ? "" : " selected") +
              '" data-i="' +
              i +
              '">' +
              (ic
                ? '<span class="palette-item-icon nf" aria-hidden="true">' + ic + "</span>"
                : "") +
              '<span class="palette-item-text">' +
              '<span class="palette-item-title">' +
              it.html +
              "</span>" +
              (it.snippet ? '<span class="palette-item-snippet">' + it.snippet + "</span>" : "") +
              "</span></div>"
            );
          })
          .join("")
      : '<div class="palette-empty">No results</div>';
    idx = 0;
    res.querySelectorAll("[data-i]").forEach(function (el) {
      el.addEventListener("click", function () {
        items[+el.dataset.i].action();
      });
    });
  }

  function renderSchemes(q) {
    if (!allSchemes) {
      res.innerHTML = '<div class="palette-empty">Loading schemes\u2026</div>';
      if (!window.__schemesUrl) return;
      fetch(window.__schemesUrl)
        .then(function (r) {
          return r.json();
        })
        .then(function (data) {
          // Curated families (light and dark pairs) first, then the rest by name.
          allSchemes = data.sort(function (a, b) {
            return (
              (b.family !== undefined) - (a.family !== undefined) || a.name.localeCompare(b.name)
            );
          });
          renderSchemes(q);
        })
        .catch(function () {});
      return;
    }
    if (!snap) snap = site.readPalette();
    items = [];
    allSchemes.forEach(function (s) {
      var h = match(s.name, q);
      if (h !== null) {
        var scheme = s;
        items.push({
          html: scheme.family !== undefined ? h + " \u00b7 light and dark" : h,
          colors: scheme.colors,
          action: function () {
            snap = null;
            if (scheme.family !== undefined) {
              site.applyScheme(scheme.family, scheme.name);
            } else {
              site.setPalette(scheme.colors);
              localStorage.setItem(
                "emacs-custom-palette",
                JSON.stringify({
                  key: scheme.key,
                  name: scheme.name,
                  variant: scheme.variant,
                  colors: scheme.colors,
                }),
              );
              document.documentElement.removeAttribute("data-scheme");
              site.applyVariant();
              site.announce("Scheme: " + scheme.name);
            }
            dlg.close();
          },
        });
      }
    });
    buildList();
  }

  function render(v) {
    if (v.startsWith("t ")) {
      inp.placeholder = "Color scheme\u2026";
      renderSchemes(v.slice(2).trim());
    } else {
      inp.placeholder = "Search posts, pages and commands (x \u00b7 Ctrl-K)\u2026";
      var q = v.trim();
      items = [];
      var seenUrls = {};
      CMDS.forEach(function (c) {
        var h = match(c.t, q);
        if (h !== null) items.push({ html: h, action: c.a, type: c.type });
      });
      (window.__posts || []).forEach(function (p) {
        var url = p.url,
          h = match(p.title, q);
        if (h !== null) {
          seenUrls[url] = true;
          items.push({
            html: h,
            action: function () {
              goTo(url);
            },
            type: "post",
          });
        }
      });
      // Matching tags after posts (only when searching), so "emacs" lists posts
      // first, then "#Emacs" as a jump to the tag page.
      if (q)
        (window.__tags || []).forEach(function (t) {
          var h = match("#" + t.name, q);
          if (h !== null) {
            var url = t.url;
            items.push({
              html: h,
              action: function () {
                goTo(url);
              },
              type: "tag",
            });
          }
        });
      items = items.slice(0, 30);
      buildList();

      // debounce index search. A short query still triggers it once a space
      // shows up (typed a whole word, or moved on to a second one) rather
      // than waiting for 5+ characters — "nix " should search as well as
      // "nixos" does.
      clearTimeout(searchTimer);
      if (q && (q.length > 5 || v.indexOf(" ") !== -1) && window.emacsBlog.search) {
        searchTimer = setTimeout(function () {
          if (inp.value.trim() !== q) return; // query changed since scheduling
          window.emacsBlog.search.load(function () {
            render(inp.value);
          });
          var words = q.toLowerCase().split(/\s+/).filter(Boolean);
          window.emacsBlog.search.find(q).forEach(function (r) {
            if (seenUrls[r.url]) return;
            items.push({
              html: esc(r.title),
              snippet: highlightWords(r.snippet, words),
              action: function () {
                // Text Fragments only work on a real navigation, so on the
                // current page select the matched text directly, once the
                // closed dialog no longer makes the page inert.
                if (r.url === location.pathname) {
                  dlg.close();
                  setTimeout(function () {
                    if (window.find) window.find(r.hit, false, false, true);
                  }, 0);
                } else {
                  location.href = r.url + "#:~:text=" + encodeURIComponent(r.hit);
                }
              },
              type: "post",
            });
          });
          items = items.slice(0, 30);
          buildList();
        }, 120);
      }
    }
  }

  function sel(n) {
    var els = res.querySelectorAll("[data-i]");
    if (!els.length) return;
    idx = Math.max(0, Math.min(n, els.length - 1));
    els.forEach(function (el, i) {
      el.classList.toggle("selected", i === idx);
    });
    els[idx].scrollIntoView({ block: "nearest" });
    if (snap && items[idx] && items[idx].colors) site.setPalette(items[idx].colors);
  }

  inp.addEventListener("input", function () {
    render(inp.value);
  });
  inp.addEventListener("keydown", function (e) {
    if (e.key === "ArrowDown" || (e.ctrlKey && e.key === "n")) {
      sel(idx + 1);
      e.preventDefault();
    } else if (e.key === "ArrowUp" || (e.ctrlKey && e.key === "p")) {
      sel(idx - 1);
      e.preventDefault();
    } else if (e.key === "Enter" && items[idx]) {
      items[idx].action();
      e.preventDefault();
    } else if (e.key === "Backspace" && inp.value === "t ") {
      snapRestore();
      inp.value = "";
      render("");
      e.preventDefault();
    }
  });
  dlg.addEventListener("click", function (e) {
    if (e.target === dlg) dlg.close();
  });

  // Fires on every close path — explicit .close(), backdrop click, and
  // native Escape alike — so a live scheme preview never survives closing
  // the dialog no matter how it was dismissed.
  dlg.addEventListener("close", snapRestore);

  function open(prefix) {
    dlg.showModal();
    inp.value = prefix || "";
    render(inp.value);
    inp.focus();
    if (prefix) inp.setSelectionRange(prefix.length, prefix.length);
  }

  window.emacsBlog = window.emacsBlog || {};
  window.emacsBlog.palette = {
    open: open,
    close: function () {
      dlg.close();
    },
  };
})();
