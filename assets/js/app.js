// SPDX-FileCopyrightText: 2020 Zach Daniel
// SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
//
// SPDX-License-Identifier: MIT

import topbar from "../vendor/topbar";
import {
  EditorView, keymap, lineNumbers, highlightActiveLineGutter,
  highlightSpecialChars, drawSelection, dropCursor, rectangularSelection,
  crosshairCursor, highlightActiveLine
} from "@codemirror/view";
import { EditorState } from "@codemirror/state";
import {
  syntaxHighlighting, defaultHighlightStyle, indentOnInput,
  bracketMatching, foldGutter, foldKeymap
} from "@codemirror/language";
import { history, defaultKeymap, historyKeymap } from "@codemirror/commands";
import { searchKeymap, highlightSelectionMatches } from "@codemirror/search";
import { autocompletion, completionKeymap } from "@codemirror/autocomplete";
import { json, jsonParseLinter } from "@codemirror/lang-json";
import { markdown } from "@codemirror/lang-markdown";
import { linter, lintKeymap } from "@codemirror/lint";
import { oneDark } from "@codemirror/theme-one-dark";
import { marked } from "marked";

// basicSetup minus closeBrackets (which causes cursor jumps in JSON editing)
const editorSetup = [
  lineNumbers(),
  highlightActiveLineGutter(),
  highlightSpecialChars(),
  history(),
  foldGutter(),
  drawSelection(),
  dropCursor(),
  EditorState.allowMultipleSelections.of(true),
  indentOnInput(),
  syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
  bracketMatching(),
  autocompletion(),
  rectangularSelection(),
  crosshairCursor(),
  highlightActiveLine(),
  highlightSelectionMatches(),
  keymap.of([
    ...defaultKeymap,
    ...searchKeymap,
    ...historyKeymap,
    ...foldKeymap,
    ...completionKeymap,
    ...lintKeymap,
  ]),
];

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let Hooks = {};
const editors = {};

function isDarkMode() {
  return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
}

function darkThemeExtension() {
  return isDarkMode() ? oneDark : [];
}

function getCspNonce() {
  const meta = document.querySelector('meta[name="csp-nonce-style"]');
  return meta ? meta.getAttribute("content") : undefined;
}

function cspNonceExtension() {
  const nonce = getCspNonce();
  return nonce ? EditorView.cspNonce.of(nonce) : [];
}

Hooks.JsonEditor = {
  mounted() {
    const inputId = this.el.getAttribute("data-input-id");
    const target = document.getElementById(inputId);
    const initialValue = target.value || "{}";

    this.view = new EditorView({
      doc: initialValue,
      extensions: [
        editorSetup,
        json(),
        linter(jsonParseLinter()),
        darkThemeExtension(),
        cspNonceExtension(),
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            const text = update.state.doc.toString();
            try {
              JSON.parse(text);
              // Mark that this change came from the user, so JsonEditorSource
              // skips the server echo and avoids a double-encoding feedback loop.
              editors[this.el.id].skipNextUpdate = true;
              target.value = text;
              target.dispatchEvent(new Event("change", { bubbles: true }));
            } catch (_e) { }
          }
        }),
      ],
      parent: this.el,
    });

    editors[this.el.id] = { view: this.view, skipNextUpdate: false };
  },
  destroyed() {
    if (this.view) {
      this.view.destroy();
      delete editors[this.el.id];
    }
  },
};

Hooks.JsonEditorSource = {
  updated() {
    try {
      const entry = editors[this.el.getAttribute("data-editor-id")];
      if (!entry) return;
      // If the update was triggered by the user editing in CM6, skip pushing
      // the server's re-encoded value back (it may be double-encoded).
      if (entry.skipNextUpdate) {
        entry.skipNextUpdate = false;
        return;
      }
      const newValue = this.el.value;
      const currentValue = entry.view.state.doc.toString();
      if (currentValue !== newValue) {
        entry.view.dispatch({
          changes: { from: 0, to: entry.view.state.doc.length, insert: newValue },
        });
      }
    } catch (_e) { }
  },
};

Hooks.JsonView = {
  mounted() {
    this._createView();
  },
  updated() {
    if (this.view) {
      this.view.destroy();
    }
    this._createView();
  },
  _createView() {
    const jsonStr = this.el.getAttribute("data-json");
    let formatted;
    try {
      formatted = JSON.stringify(JSON.parse(jsonStr), null, 2);
    } catch (_e) {
      formatted = jsonStr;
    }

    this.view = new EditorView({
      doc: formatted,
      extensions: [
        editorSetup,
        json(),
        EditorView.editable.of(false),
        EditorState.readOnly.of(true),
        darkThemeExtension(),
        cspNonceExtension(),
      ],
      parent: this.el,
    });
  },
  destroyed() {
    if (this.view) {
      this.view.destroy();
    }
  },
};

Hooks.MarkdownEditor = {
  mounted() {
    const id = this.el.getAttribute("data-target-id");
    const el = document.getElementById(id);
    const initialValue = el.value || el.textContent || "";

    // Hide the textarea — CM6 replaces it visually, textarea stays as hidden form field
    el.style.display = "none";

    // Build side-by-side layout: toolbar + editor | preview
    const container = document.createElement("div");
    container.className = "md-editor-container";

    const toolbar = document.createElement("div");
    toolbar.className = "md-editor-toolbar";

    const maximizeBtn = document.createElement("button");
    maximizeBtn.type = "button";
    maximizeBtn.className = "md-editor-maximize-btn";
    maximizeBtn.title = "Fullscreen";
    maximizeBtn.innerHTML = "&#x26F6;";
    toolbar.appendChild(maximizeBtn);

    const wrapper = document.createElement("div");
    wrapper.className = "md-editor-wrapper";

    const editorPane = document.createElement("div");
    editorPane.className = "md-editor-pane";

    const preview = document.createElement("div");
    preview.className = "md-preview-pane prose dark:prose-invert max-w-none";
    preview.innerHTML = marked.parse(initialValue);

    wrapper.appendChild(editorPane);
    wrapper.appendChild(preview);
    container.appendChild(toolbar);
    container.appendChild(wrapper);
    this.el.appendChild(container);

    // Fullscreen toggle
    const closeFullscreen = () => {
      container.classList.remove("md-fullscreen");
      document.body.style.overflow = "";
    };

    maximizeBtn.addEventListener("click", (e) => {
      e.preventDefault();
      if (container.classList.contains("md-fullscreen")) {
        closeFullscreen();
      } else {
        container.classList.add("md-fullscreen");
        document.body.style.overflow = "hidden";
        this.view.focus();
      }
    });

    // Close on Escape
    container.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && container.classList.contains("md-fullscreen")) {
        e.preventDefault();
        closeFullscreen();
      }
    });

    this._container = container;
    this._closeFullscreen = closeFullscreen;

    this.view = new EditorView({
      doc: initialValue,
      extensions: [
        editorSetup,
        markdown(),
        darkThemeExtension(),
        cspNonceExtension(),
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            const text = update.state.doc.toString();
            el.value = text;
            el.dispatchEvent(new Event("change", { bubbles: true }));
            preview.innerHTML = marked.parse(text);
          }
        }),
      ],
      parent: editorPane,
    });
  },
  destroyed() {
    if (this._closeFullscreen) this._closeFullscreen();
    if (this.view) {
      this.view.destroy();
    }
  },
};

function setCookie(name, value) {
  // Avoid storing the string "null"/"undefined" from encodeURIComponent(null)
  document.cookie = name + "=" + (value != null ? encodeURIComponent(value) : "") + ";path=/";
}

Hooks.Actor = {
  mounted() {
    this.handleEvent("set_actor", (payload) => {
      setCookie("actor_resource", payload.resource);
      setCookie("actor_primary_key", payload.primary_key);
      setCookie("actor_action", payload.action);
      setCookie("actor_domain", payload.domain);
      setCookie("actor_tenant", payload.tenant);
    });
    this.handleEvent("clear_actor", () => {
      document.cookie = "actor_resource" + "=" + ";path=/";
      document.cookie = "actor_primary_key" + "=" + ";path=/";
      document.cookie = "actor_action" + "=" + ";path=/";
      document.cookie = "actor_tenant" + "=" + ";path=/";
      document.cookie = "actor_domain" + "=" + ";path=/";
      document.cookie = "actor_authorizing=false;path=/";
      document.cookie = "actor_paused=true;path=/";
    });
    this.handleEvent("toggle_authorizing", (payload) => {
      document.cookie =
        "actor_authorizing" + "=" + payload.authorizing + ";path=/";
    });
    this.handleEvent("toggle_actor_paused", (payload) => {
      document.cookie = "actor_paused" + "=" + payload.actor_paused + ";path=/";
    });
  },
};

Hooks.Tenant = {
  mounted() {
    this.handleEvent("set_tenant", (payload) => {
      setCookie("tenant", payload.tenant);
    });
    this.handleEvent("clear_tenant", () => {
      setCookie("tenant", null);
    });
  },
};

Hooks.PositionAbove = {
  mounted() { this.position(); },
  updated() { this.position(); },
  position() {
    const input = this.el.nextElementSibling?.querySelector("input");
    if (!input) return;
    const rect = input.getBoundingClientRect();
    this.el.style.bottom = (window.innerHeight - rect.top + 4) + "px";
    this.el.style.left = rect.left + "px";
    this.el.style.width = rect.width + "px";
  }
};

Hooks.MaintainAttrs = {
  attrs() {
    return this.el.getAttribute("data-attrs").split(", ");
  },
  beforeUpdate() {
    this.prevAttrs = this.attrs().map((name) => [
      name,
      this.el.getAttribute(name),
    ]);
  },
  updated() {
    this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val));
  },
};

Hooks.Typeahead = {
  mounted() {
    this.aborter = new AbortController();
    const signal = this.aborter.signal;

    const target_id = this.el.getAttribute("data-target-id");
    const target_el = document.getElementById(target_id);

    switch (this.el.tagName) {
      case "INPUT":
        this.el.addEventListener("keydown", e => {
          if (e.key === "Enter") {
            e.preventDefault();
          }
        }, { signal });
        this.el.addEventListener("keyup", e => {
          switch (e.key) {
            case "Enter":
            case "Escape":
              this.el.blur();
              window.setTimeout(function () { target_el.dispatchEvent(new Event("input", { bubbles: true })) }, 750);
              break;
          }
        }, { signal });
        break;

      case "LI":
        this.el.addEventListener("click", e => {
          window.setTimeout(function () { target_el.dispatchEvent(new Event("input", { bubbles: true })) }, 750);
        }, { signal });
        break;
    }
  },
  updated() {
    if (this.el.tagName === "INPUT" && this.el.name.match(/suggest$/) && this.el.value.length === 0) {
      this.el.focus();
    }
  },
  beforeDestroy() {
    if (this.aborter) {
      this.aborter.abort();
    }
  }
};

function getCookie(name) {
  var re = new RegExp(name + "=([^;]+)");
  var value = re.exec(document.cookie);
  if (value == null) return null;
  var decoded = decodeURIComponent(value[1]);
  // encodeURIComponent(null) produces the string "null", normalize it back
  return decoded === "null" || decoded === "undefined" ? null : decoded;
}

let params = () => {
  return {
    _csrf_token: csrfToken,
    tenant: getCookie("tenant"),
    actor_resource: getCookie("actor_resource"),
    actor_primary_key: getCookie("actor_primary_key"),
    actor_tenant: getCookie("actor_tenant"),
    actor_action: getCookie("actor_action"),
    actor_domain: getCookie("actor_domain"),
    actor_authorizing: getCookie("actor_authorizing"),
    actor_paused: getCookie("actor_paused"),
  };
};

let liveSocket = new LiveView.LiveSocket(socketPath, Phoenix.Socket, {
  params: params,
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();
// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug();
//  liveSocket.enableLatencySim(1000)

window.liveSocket = liveSocket;
