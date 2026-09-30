/* ---- keyboard.js ---- */
/**
 * Command palette triggers + post-page mouse actions for Emacs Blog Theme.
 */

(function () {
  "use strict";

  let msgTimeout = null;

  // DOM
  const articleList = document.getElementById("article-list");
  const echoMessage = document.getElementById("echo-message");

  // Are we on a single post page (no article list)?
  const isPostPage = !articleList;

  // ── Echo area ──────────────────────────────────────────────────────────────

  function showMessage(msg) {
    if (!echoMessage) return;
    clearTimeout(msgTimeout);
    echoMessage.textContent = msg;
    echoMessage.classList.add("flash");
    msgTimeout = setTimeout(() => {
      echoMessage.classList.remove("flash");
      updateEchoHint();
    }, 2500);
  }

  function updateEchoHint() {
    if (!echoMessage) return;
    echoMessage.textContent = "? help";
  }

  // ── Command palette triggers ─────────────────────────────────────────────

  function handleKeydown(e) {
    // Ignore when typing
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;

    var ctrl = e.ctrlKey;
    var meta = e.metaKey;
    var code = e.code;

    if (
      ((ctrl || meta) && (code === "KeyK" || code === "KeyS")) ||
      (e.altKey && code === "KeyX")
    ) {
      window.emacsBlog?.palette?.open();
      e.preventDefault();
      return;
    }

    if (e.key === "x" && !localStorage.getItem("emacs-keys-off")) {
      window.emacsBlog?.palette?.open();
      e.preventDefault();
    }
  }

  // ── Code copy buttons ────────────────────────────────────────────────────
  // Chroma puts data-lang on <code>, not <pre> — the pre::before lang label
  // (theme.css) reads it from <pre>, so it silently never fired. Copy it up
  // while we're already walking every code block for the copy button.
  function addCodeCopyButtons() {
    document.querySelectorAll(".post-body pre").forEach(function (pre) {
      var code = pre.querySelector("code");
      if (!code) return;
      var lang = code.getAttribute("data-lang");
      if (lang) pre.setAttribute("data-lang", lang);

      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "code-copy-btn";
      btn.textContent = "Copy";
      btn.setAttribute("aria-label", "Copy code to clipboard");
      btn.addEventListener("click", function () {
        navigator.clipboard
          .writeText(code.textContent)
          .then(function () {
            btn.textContent = "Copied!";
            btn.classList.add("copied");
            clearTimeout(btn._copyReset);
            btn._copyReset = setTimeout(function () {
              btn.textContent = "Copy";
              btn.classList.remove("copied");
            }, 1500);
          })
          .catch(function () {});
      });
      pre.appendChild(btn);
    });
  }

  // ── Heading anchor links ─────────────────────────────────────────────────
  // go-org already assigns sequential ids (headline-N) to post headings; add
  // a visible, focusable link to each so sections are directly linkable.
  function addHeadingAnchors() {
    document
      .querySelectorAll(".post-body :is(h2, h3, h4, h5, h6)[id]")
      .forEach(function (h) {
        var a = document.createElement("a");
        a.className = "heading-anchor";
        a.href = "#" + h.id;
        a.setAttribute("aria-label", "Link to this section");
        a.textContent = "#";
        h.appendChild(a);
      });
  }

  // ── Image lightbox ───────────────────────────────────────────────────────
  // Click a post image to view it full-size in the shared <dialog> (baseof.html).
  // Esc and backdrop-click close it natively/via the same idiom as the palette.
  function initImageLightbox() {
    var imgs = document.querySelectorAll(".post-body img");
    if (!imgs.length) return;
    var dlg = document.getElementById("image-lightbox");
    var lbImg = document.getElementById("lightbox-img");
    if (!dlg || !lbImg) return;
    imgs.forEach(function (img) {
      img.addEventListener("click", function () {
        lbImg.src = img.currentSrc || img.src;
        lbImg.alt = img.alt || "";
        dlg.showModal();
      });
    });
    dlg.addEventListener("click", function (e) {
      if (e.target === dlg) dlg.close();
    });
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  function init() {
    document.addEventListener("keydown", handleKeydown);
    // Clicking the echo message opens shortcut help in palette
    echoMessage?.addEventListener("click", function () {
      window.emacsBlog?.palette?.open("? ");
    });

    if (isPostPage) {
      addCodeCopyButtons();
      addHeadingAnchors();
      initImageLightbox();
    }

    updateEchoHint();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  // WCAG 2.1.4: let users turn the "x" shortcut off (persisted).
  window.toggleKeys = function () {
    var off = localStorage.getItem("emacs-keys-off");
    if (off) {
      localStorage.removeItem("emacs-keys-off");
      showMessage("Keyboard shortcuts: on");
    } else {
      localStorage.setItem("emacs-keys-off", "1");
      showMessage("Keyboard shortcuts: off");
    }
  };

  window.emacsBlog = window.emacsBlog || {};
  window.emacsBlog.keyboard = { showMessage: showMessage };
})();

/* ---- menu.js ---- */
/**
 * Menu Bar Interactions for Emacs Blog Theme
 */

(function () {
  "use strict";

  // ── State ─────────────────────────────────────────────────────────────────
  let previewScheme = null; // scheme being hovered (for live preview)

  // ── DOM ───────────────────────────────────────────────────────────────────
  const menuBar = document.querySelector(".menu-bar");
  const menuItems = document.querySelectorAll(".menu-item");
  const hamburger = document.querySelector(".menu-hamburger");
  const backdrop = document.getElementById("menu-backdrop");
  const schemePopupBtn = document.getElementById("scheme-popup-btn");
  const schemePopup = document.getElementById("scheme-popup");
  const schemePopupContainer = document.getElementById(
    "scheme-popup-container",
  );

  // ── Theme ─────────────────────────────────────────────────────────────────

  function toggleTheme() {
    const root = document.documentElement;
    const cur = root.getAttribute("data-theme") === "light" ? "light" : "dark";
    const want = cur === "dark" ? "light" : "dark";
    // Flip only if the current scheme actually defines the wanted variant.
    // Tentatively switch and check whether the palette changed; if not — a
    // dark-only preset (e.g. Everforest, Monokai) or a single-variant custom
    // palette — revert and route to a search for schemes of the wanted mode,
    // rather than showing an unmapped/broken theme. Self-maintaining: any scheme
    // that later gains a real variant will just flip.
    const before = getComputedStyle(root).getPropertyValue("--base00").trim();
    root.setAttribute("data-theme", want);
    const after = getComputedStyle(root).getPropertyValue("--base00").trim();
    if (before === after) {
      root.setAttribute("data-theme", cur);
      showMsg("No " + want + " variant for this scheme — pick one");
      window.emacsBlog?.palette?.open("t " + want);
      return;
    }
    localStorage.setItem("emacs-theme", want);
    // Name the scheme it switched to, e.g. "Dracula · Light", not just the mode.
    var opt = document.querySelector(
      '.scheme-option[data-scheme="' +
        (root.getAttribute("data-scheme") || "") +
        '"] span:last-child',
    );
    var name = opt ? opt.textContent.trim() : "Modus";
    showMsg(name + " · " + (want === "dark" ? "Dark" : "Light"));
  }

  // ── Color Scheme ──────────────────────────────────────────────────────────

  function applyScheme(name) {
    // Clear any custom palette from palette.js "t " mode
    window.emacsBlog?.palette?.clearCustomPalette?.();
    const html = document.documentElement;
    if (name) html.setAttribute("data-scheme", name);
    else html.removeAttribute("data-scheme");
    updateSchemeMarkers(name || "");
  }

  function updateSchemeMarkers(current) {
    document.querySelectorAll(".scheme-option").forEach((opt) => {
      opt.classList.toggle("active", (opt.dataset.scheme || "") === current);
    });
  }

  // Scheme state sync. The scheme itself (pinned / custom / fresh random) is
  // applied BEFORE paint by head.html's inline script, so we must NOT re-apply
  // here — doing so caused a visible repaint on every page load. We only sync
  // the menu's active-marker + pin label to whatever is already showing.
  function initRandomScheme() {
    const custom = localStorage.getItem("emacs-custom-palette") !== null;
    const pinned = isPinned();
    updateSchemeMarkers(
      document.documentElement.getAttribute("data-scheme") || "",
    );
    updatePinLabel(pinned);

    // First-visit only: announce that the scheme is random and pinnable. The
    // pin control is otherwise invisible until the user opens the menu.
    if (!pinned && !custom && !localStorage.getItem("emacs-scheme-hint-seen")) {
      const active = document.querySelector(
        ".scheme-option.active span:last-child",
      );
      const label = (active?.textContent || "random").trim();
      showMsg("Scheme: " + label + " (random each reload, pin in menu)");
      localStorage.setItem("emacs-scheme-hint-seen", "1");
    }
  }

  // Pinned = either mechanism: emacs-scheme-fixed (menu presets, e.g. haki,
  // dracula) or emacs-custom-palette (the "t " picker / /themes gallery, any
  // of the 305+ base16 schemes). Both mean "persists across reloads".
  function isPinned() {
    return (
      localStorage.getItem("emacs-scheme-fixed") !== null ||
      localStorage.getItem("emacs-custom-palette") !== null
    );
  }

  function fixScheme() {
    if (isPinned()) {
      // Unpin — go back to random each session. Clear whichever mechanism
      // is actually active so the two never end up in a conflicting state.
      if (localStorage.getItem("emacs-custom-palette") !== null) {
        window.emacsBlog?.palette?.clearCustomPalette?.();
      } else {
        localStorage.removeItem("emacs-scheme-fixed");
      }
      updatePinLabel(false);
      showMsg("Scheme unpinned (random each session)");
    } else {
      // Pin current scheme
      const cur = document.documentElement.getAttribute("data-scheme") || "";
      localStorage.setItem("emacs-scheme-fixed", cur);
      updatePinLabel(true);
      showMsg("Scheme pinned: " + (cur || "Modus"));
    }
  }

  function updatePinLabel(pinned) {
    const text = pinned ? "Unpin" : "Pin";
    const label = document.getElementById("pin-scheme-label");
    if (label) label.textContent = text;
    const mlLabel = document.getElementById("ml-pin-label");
    if (mlLabel) mlLabel.textContent = text;
    const mlBtn = document.getElementById("ml-pin-btn");
    if (mlBtn) mlBtn.classList.toggle("pinned", pinned);
    // Announce toggle state, not just a changed label. Three controls carry
    // data-action="fix-scheme" (M-x dropdown, scheme popup, modeline) :: all must
    // stay in sync or two of them read stale. The dropdown one is a
    // menuitemcheckbox, which takes aria-checked instead of aria-pressed.
    document.querySelectorAll('[data-action="fix-scheme"]').forEach((btn) => {
      const attr =
        btn.getAttribute("role") === "menuitemcheckbox"
          ? "aria-checked"
          : "aria-pressed";
      btn.setAttribute(attr, pinned ? "true" : "false");
    });
  }

  // Live hover preview — temporarily apply hovered scheme (~15 LOC)
  function initSchemeHoverPreview() {
    document.querySelectorAll(".scheme-option").forEach((opt) => {
      opt.addEventListener("mouseenter", () => {
        previewScheme = document.documentElement.getAttribute("data-scheme");
        const hov = opt.dataset.scheme || "";
        hov
          ? document.documentElement.setAttribute("data-scheme", hov)
          : document.documentElement.removeAttribute("data-scheme");
      });
      opt.addEventListener("mouseleave", () => {
        if (previewScheme !== null) {
          previewScheme
            ? document.documentElement.setAttribute(
                "data-scheme",
                previewScheme,
              )
            : document.documentElement.removeAttribute("data-scheme");
          previewScheme = null;
        }
      });
    });
  }

  // ── Scheme Popup ──────────────────────────────────────────────────────────
  // A <details>; open/closed is native. toggleSchemePopup stays around only
  // because palette.js's "Color scheme picker" command calls it by name.

  function toggleSchemePopup() {
    if (schemePopupContainer) schemePopupContainer.open = !schemePopupContainer.open;
  }

  // Fires on every open/close of the popup, however it happened (click,
  // Escape via handleKeydown below, or the toggle above) — so a live preview
  // never survives closing it, the same class of fix as palette.js's own
  // dialog "close" listener.
  schemePopupContainer?.addEventListener("toggle", () => {
    schemePopupBtn?.setAttribute(
      "aria-expanded",
      String(schemePopupContainer.open),
    );
    if (!schemePopupContainer.open && previewScheme !== null) {
      previewScheme
        ? document.documentElement.setAttribute("data-scheme", previewScheme)
        : document.documentElement.removeAttribute("data-scheme");
      previewScheme = null;
    }
  });

  // ── Font Mode Cycling ─────────────────────────────────────────────────────
  // Mono → Sans → Serif → Mixed (prose serif, structure/meta sans, code mono)
  // Mixed is the default for first-time visitors (no saved preference).

  const FONT_STEPS = ["mono", "sans", "serif", "mixed"];
  const FONT_LABELS = {
    mono: "Mono",
    sans: "Sans",
    serif: "Serif",
    mixed: "Mixed",
  };
  const FONT_DEFAULT = "mixed";
  let fontIdx = FONT_STEPS.indexOf(FONT_DEFAULT);

  function cycleFontMode() {
    fontIdx = (fontIdx + 1) % FONT_STEPS.length;
    const f = FONT_STEPS[fontIdx];
    document.documentElement.setAttribute("data-font", f);
    localStorage.setItem("emacs-font-mode", f);
    showMsg("Font: " + FONT_LABELS[f]);
  }

  function restoreFontMode() {
    const saved = localStorage.getItem("emacs-font-mode");
    const mode = saved && FONT_STEPS.includes(saved) ? saved : FONT_DEFAULT;
    fontIdx = FONT_STEPS.indexOf(mode);
    document.documentElement.setAttribute("data-font", mode);
  }

  // ── Content Width Cycle ───────────────────────────────────────────────────
  // First click → 100%, then cycles 80ch → 60ch → 840px → back

  const WIDTH_STEPS = ["840px", "100%", "80%", "60%"];
  let widthIdx = 0; // default 840px; first click → idx 1 = 100%

  function cycleWidth() {
    widthIdx = (widthIdx + 1) % WIDTH_STEPS.length;
    const w = WIDTH_STEPS[widthIdx];
    document.documentElement.style.setProperty("--content-max-width", w);
    localStorage.setItem("emacs-width-idx", widthIdx);
    showMsg("Width: " + w);
  }

  function restoreWidth() {
    const saved = localStorage.getItem("emacs-width-idx");
    if (saved !== null) {
      const idx = parseInt(saved, 10);
      if (idx >= 0 && idx < WIDTH_STEPS.length) {
        widthIdx = idx;
        document.documentElement.style.setProperty(
          "--content-max-width",
          WIDTH_STEPS[idx],
        );
      }
    }
  }

  // ── Echo message helper ───────────────────────────────────────────────────

  function showMsg(msg) {
    window.emacsBlog?.keyboard?.showMessage?.(msg);
  }

  // ── Mobile hamburger menu ─────────────────────────────────────────────────
  // Unlike the dropdowns/scheme popup above, this toggles the same .menu-items
  // nav in and out of a mobile-only overlay layout rather than showing a
  // hidden-by-default element, so it stays a plain class toggle.

  function toggleMobileMenu() {
    const isOpen = menuBar?.classList.toggle("menu-open");
    hamburger?.setAttribute("aria-expanded", String(!!isOpen));
  }

  function closeMobileMenu() {
    menuBar?.classList.remove("menu-open");
    hamburger?.setAttribute("aria-expanded", "false");
  }

  function handleBackdropClick() {
    closeMobileMenu();
    backdrop?.classList.remove("visible");
  }

  function handleActionClick(e) {
    const el = e.target.closest("[data-action]");
    if (!el) return;
    const action = el.dataset.action;
    switch (action) {
      case "toggle-theme":
        toggleTheme();
        break;
      case "cycle-width":
        cycleWidth();
        break;
      case "cycle-font":
        cycleFontMode();
        break;
      case "toggle-keys":
        window.toggleKeys && window.toggleKeys();
        break;
      case "fix-scheme":
        fixScheme();
        break;
      case "open-palette":
        window.emacsBlog?.palette?.open();
        break;
      case "browse-schemes":
        window.emacsBlog?.palette?.open("t ");
        break;
      case "show-help":
        window.emacsBlog?.palette?.open("? ");
        break;
    }
    document.querySelectorAll(".menu-item[open]").forEach((d) => (d.open = false));
    if (
      action !== "cycle-width" &&
      action !== "cycle-font" &&
      action !== "fix-scheme" &&
      action !== "open-palette" &&
      action !== "browse-schemes" &&
      schemePopupContainer
    )
      schemePopupContainer.open = false;
  }

  function handleSchemeOptionClick(e) {
    const el = e.target.closest(".scheme-option");
    if (!el) return;
    applyScheme(el.dataset.scheme || "");
    // Random every load unless the user explicitly Pins. Picking here only
    // previews for this view; if already pinned, retarget the pin to this pick.
    if (localStorage.getItem("emacs-scheme-fixed") !== null) {
      localStorage.setItem("emacs-scheme-fixed", el.dataset.scheme || "");
    }
    previewScheme = null; // commit — nothing left to restore when it closes
    document.querySelectorAll(".menu-item[open]").forEach((d) => (d.open = false));
    if (schemePopupContainer) schemePopupContainer.open = false;
  }

  function handleOutsideClick(e) {
    if (!e.target.closest(".menu-item")) {
      document.querySelectorAll(".menu-item[open]").forEach((d) => (d.open = false));
    }
    if (
      schemePopupContainer?.open &&
      !e.target.closest("#scheme-popup-container")
    )
      schemePopupContainer.open = false;
  }

  function handleKeydown(e) {
    if (e.key === "Escape") {
      document.querySelectorAll(".menu-item[open]").forEach((d) => (d.open = false));
      if (schemePopupContainer) schemePopupContainer.open = false;
      closeMobileMenu();
    }
    const dropdown = document.querySelector(".menu-item[open] > .menu-dropdown");
    if (!dropdown) return;
    const items = dropdown.querySelectorAll(".menu-dropdown-item:not(.disabled)");
    if (!items.length) return;
    const focused = dropdown.querySelector(".menu-dropdown-item:focus");
    let idx = focused ? Array.from(items).indexOf(focused) : -1;
    if (e.key === "ArrowDown") {
      items[(idx + 1) % items.length].focus();
      e.preventDefault();
    }
    if (e.key === "ArrowUp") {
      items[idx <= 0 ? items.length - 1 : idx - 1].focus();
      e.preventDefault();
    }
    if (e.key === "Enter" && focused) {
      focused.click();
      e.preventDefault();
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  function init() {
    // Scheme options (both in View menu and popup)
    document.querySelectorAll(".scheme-option").forEach((opt) => {
      opt.addEventListener("click", handleSchemeOptionClick);
    });

    // Action buttons (toggle-theme, cycle-*, fix-scheme, etc.)
    document.addEventListener("click", (e) => {
      if (
        e.target.closest("[data-action]") &&
        !e.target.closest(".scheme-option")
      ) {
        handleActionClick(e);
      }
    });

    // Backdrop
    backdrop?.addEventListener("click", handleBackdropClick);

    // Hamburger
    hamburger?.addEventListener("click", toggleMobileMenu);

    // Outside click (dropdowns/scheme popup have native open-toggle, but not
    // native light-dismiss the way a popover would — this is that piece)
    document.addEventListener("click", handleOutsideClick);

    // Keyboard: Escape closes everything; arrow keys/Enter roam an open menu
    document.addEventListener("keydown", handleKeydown);

    // Hover to switch to an adjacent menu while one is already open (desktop
    // UX). name="menu" grouping means opening one natively closes the rest.
    menuItems.forEach((item) => {
      item.addEventListener("mouseenter", () => {
        if (document.querySelector(".menu-item[open]") && !item.open)
          item.open = true;
      });
    });

    // Restore saved state
    restoreWidth();
    restoreFontMode();

    // Random/pinned scheme
    initRandomScheme();

    // Hover preview for schemes
    initSchemeHoverPreview();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  // Expose globals for palette.js commands
  window.toggleTheme = toggleTheme;
  window.cycleWidth = cycleWidth;
  window.cycleFontMode = cycleFontMode;
  window.toggleSchemePopup = toggleSchemePopup;
  window.pinScheme = fixScheme;

  window.emacsBlog = window.emacsBlog || {};
  window.emacsBlog.menu = {
    refreshPinState: function () {
      updatePinLabel(isPinned());
    },
  };
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
 * Default: commands + posts. "t " prefix: all base16 schemes.
 * Trigger: x / Ctrl-K / Ctrl-S / Alt-X (keyboard.js) or window.emacsBlog.palette.open()
 */
(function () {
  "use strict";

  var dlg = document.getElementById("palette-dialog");
  var inp = document.getElementById("palette-input");
  var res = document.getElementById("palette-results");
  if (!dlg || !inp || !res) return;

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

  function applyCustomPalette(colors) {
    BASE_KEYS.forEach(function (k, i) {
      if (colors[i])
        document.documentElement.style.setProperty("--" + k, colors[i]);
    });
  }

  function clearCustomPalette() {
    BASE_KEYS.forEach(function (k) {
      document.documentElement.style.removeProperty("--" + k);
    });
    localStorage.removeItem("emacs-custom-palette");
  }

  // Per-type icons (config: params.paletteIcons), with built-in fallbacks.
  var ICONS = Object.assign(
    { nav: "", command: "", post: "", tag: "", scheme: "", help: "" },
    window.__paletteIcons || {},
  );

  // Section navigation from the site menu (window.__nav) so it stays in sync,
  // plus destinations the menu doesn't list.
  var NAV = (window.__nav || [])
    .map(function (n) {
      return {
        t: n.name,
        type: "nav",
        a: function () {
          goTo(n.url);
        },
      };
    })
    .concat([
      {
        t: "Wander Console",
        type: "nav",
        a: function () {
          goTo("/wander/console/");
        },
      },
    ]);

  // Commands (nav is dynamic above; these are the explicit action list).
  var CMDS = NAV.concat([
    {
      t: "Toggle dark / light theme",
      type: "command",
      a: function () {
        dlg.close();
        window.toggleTheme && window.toggleTheme();
      },
    },
    {
      t: "Cycle font mode",
      type: "command",
      a: function () {
        dlg.close();
        window.cycleFontMode && window.cycleFontMode();
      },
    },
    {
      t: "Cycle content width",
      type: "command",
      a: function () {
        dlg.close();
        window.cycleWidth && window.cycleWidth();
      },
    },
    {
      t: "Pin / unpin scheme",
      type: "command",
      a: function () {
        dlg.close();
        window.pinScheme && window.pinScheme();
      },
    },
    {
      t: "Color scheme picker",
      type: "command",
      a: function () {
        dlg.close();
        window.toggleSchemePopup && window.toggleSchemePopup();
      },
    },
    {
      t: "Browse all color schemes",
      type: "scheme",
      a: function () {
        inp.value = "t ";
        render("t ");
        inp.focus();
        inp.setSelectionRange(2, 2);
      },
    },
    {
      t: "Browse tags",
      type: "tag",
      a: function () {
        inp.value = "#";
        render("#");
        inp.focus();
        inp.setSelectionRange(1, 1);
      },
    },
    {
      t: "Keyboard shortcuts",
      type: "help",
      a: function () {
        inp.value = "? ";
        render("? ");
        inp.focus();
        inp.setSelectionRange(2, 2);
      },
    },
    {
      t: "Enable / disable keyboard shortcuts",
      type: "command",
      a: function () {
        dlg.close();
        window.toggleKeys && window.toggleKeys();
      },
    },
  ]);

  var HELP = [
    {
      t: "Ctrl/Cmd-K, Ctrl/Cmd-S, Alt-X (M-x), or x  —  Open command palette",
      a: null,
    },
  ];

  var idx = 0,
    items = [];
  var allSchemes = null,
    snap = null;
  var searchTimer = null;

  // Picking the page you're already on can't navigate anywhere -- the
  // browser does nothing, so the dialog just sits there looking unresponsive.
  // Close it ourselves in that case instead of leaving the user hanging.
  function goTo(url) {
    if (url === location.pathname) dlg.close();
    else location.href = url;
  }

  function snapRestore() {
    if (snap)
      BASE_KEYS.forEach(function (k, i) {
        snap[i]
          ? document.documentElement.style.setProperty("--" + k, snap[i])
          : document.documentElement.style.removeProperty("--" + k);
      });
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
                ? '<span class="palette-item-icon nf" aria-hidden="true">' +
                  ic +
                  "</span>"
                : "") +
              '<span class="palette-item-text">' +
              '<span class="palette-item-title">' +
              it.html +
              "</span>" +
              (it.snippet
                ? '<span class="palette-item-snippet">' + it.snippet + "</span>"
                : "") +
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
          allSchemes = data.sort(function (a, b) {
            return a.name.localeCompare(b.name);
          });
          renderSchemes(q);
        })
        .catch(function () {});
      return;
    }
    if (!snap)
      snap = BASE_KEYS.map(function (k) {
        return document.documentElement.style.getPropertyValue("--" + k);
      });
    items = [];
    allSchemes.forEach(function (s) {
      var h = match(s.name, q);
      if (h !== null) {
        var colors = s.colors,
          key = s.key,
          name = s.name;
        items.push({
          html: h,
          colors: colors,
          action: function () {
            applyCustomPalette(colors);
            localStorage.setItem(
              "emacs-custom-palette",
              JSON.stringify({ key: key, name: name, colors: colors }),
            );
            document.documentElement.removeAttribute("data-scheme");
            snap = null;
            dlg.close();
            window.emacsBlog?.menu?.refreshPinState?.();
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
    } else if (v.startsWith("? ")) {
      inp.placeholder = "Search shortcuts\u2026";
      var q = v.slice(2).trim();
      items = [];
      HELP.forEach(function (h) {
        var ht = match(h.t, q);
        if (ht !== null)
          items.push({
            html: ht,
            action:
              h.a ||
              function () {
                dlg.close();
              },
            type: "help",
          });
      });
      buildList();
    } else if (v.charAt(0) === "#") {
      inp.placeholder = "Jump to a tag\u2026";
      var tq = v.slice(1);
      items = [];
      (window.__tags || []).forEach(function (t) {
        var label = "#" + t.name + (t.count ? "  (" + t.count + ")" : "");
        var h = match(label, tq);
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
      items = items.slice(0, 40);
      buildList();
    } else {
      inp.placeholder =
        "Search posts, run commands, browse themes  (M-x \u00b7 Ctrl-K \u00b7 Ctrl-S)\u2026";
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
                // Text Fragments only scroll-and-highlight on a real
                // navigation, never on a same-document hash change -- so
                // searching for a term on the page you're already viewing
                // would otherwise just update the address bar and do
                // nothing visible. No reload needed though: we already
                // know the exact matched text (r.hit), so just find,
                // select and scroll to it directly on the current page.
                if (r.url === location.pathname) {
                  // #palette-dialog fades out over --dialog-transition
                  // (CSS allow-discrete + @starting-style) rather than
                  // closing instantly -- the background stays genuinely
                  // inert for that whole duration, and window.find (like
                  // real find-in-page) skips inert content, so calling it
                  // right after .close() returns finds nothing. Wait for
                  // the fade to actually finish (transitionend), with a
                  // timeout fallback in case a future style change ever
                  // removes the transition outright and it never fires.
                  var done = false;
                  var runFind = function () {
                    if (done) return;
                    done = true;
                    dlg.removeEventListener("transitionend", onEnd);
                    if (window.find) window.find(r.hit, false, false, true);
                  };
                  var onEnd = function (e) {
                    if (e.target === dlg && e.propertyName === "opacity") runFind();
                  };
                  dlg.addEventListener("transitionend", onEnd);
                  setTimeout(runFind, 600);
                  dlg.close();
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
    if (snap && items[idx] && items[idx].colors)
      applyCustomPalette(items[idx].colors);
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
    } else if (
      e.key === "Backspace" &&
      (inp.value === "t " || inp.value === "? ")
    ) {
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
    clearCustomPalette: clearCustomPalette,
    applyCustomPalette: applyCustomPalette,
  };
})();

/* ---- themes-gallery.js ---- */
/**
 * /themes gallery — hover preview + click-to-pin.
 * Reuses palette.js's applyCustomPalette (window.emacsBlog.palette) instead of
 * duplicating the --baseXX assignment logic. No-ops on any page without cards.
 */
(function () {
  "use strict";

  var cards = document.querySelectorAll(".scheme-card");
  if (!cards.length) return;

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
  var snap = null;

  function apply(colors) {
    window.emacsBlog &&
      window.emacsBlog.palette &&
      window.emacsBlog.palette.applyCustomPalette &&
      window.emacsBlog.palette.applyCustomPalette(colors);
  }

  function snapshot() {
    var root = document.documentElement;
    snap = BASE_KEYS.map(function (k) {
      return root.style.getPropertyValue("--" + k);
    });
  }

  function restore() {
    if (!snap) return;
    var root = document.documentElement;
    BASE_KEYS.forEach(function (k, i) {
      snap[i]
        ? root.style.setProperty("--" + k, snap[i])
        : root.style.removeProperty("--" + k);
    });
    snap = null;
  }

  cards.forEach(function (card) {
    var btn = card.querySelector(".scheme-card-btn");
    if (!btn) return;
    var colors = JSON.parse(btn.dataset.colors);
    var key = btn.dataset.key;
    var name = btn.dataset.name;

    // Hover preview covers the whole card (author link included) — mouse-only,
    // no a11y concern. Keyboard preview + the actual pin action stay scoped to
    // the button, the card's one real interactive/focusable control.
    card.addEventListener("mouseenter", function () {
      if (!snap) snapshot();
      apply(colors);
    });
    card.addEventListener("mouseleave", restore);
    btn.addEventListener("focus", function () {
      if (!snap) snapshot();
      apply(colors);
    });
    btn.addEventListener("blur", restore);

    btn.addEventListener("click", function () {
      apply(colors);
      localStorage.setItem(
        "emacs-custom-palette",
        JSON.stringify({ key: key, name: name, colors: colors }),
      );
      document.documentElement.removeAttribute("data-scheme");
      snap = null;
      window.emacsBlog &&
        window.emacsBlog.keyboard &&
        window.emacsBlog.keyboard.showMessage &&
        window.emacsBlog.keyboard.showMessage("Pinned: " + name);
      window.emacsBlog &&
        window.emacsBlog.menu &&
        window.emacsBlog.menu.refreshPinState &&
        window.emacsBlog.menu.refreshPinState();
    });
  });
})();

