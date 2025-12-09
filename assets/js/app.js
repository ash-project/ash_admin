// SPDX-FileCopyrightText: 2020 Zach Daniel
// SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
//
// SPDX-License-Identifier: MIT

import topbar from "../vendor/topbar";

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let Hooks = {};
const editors = {};

Hooks.JsonEditor = {
  mounted() {
    const inputId = this.el.getAttribute("data-input-id");
    const target = document.getElementById(inputId);
    
    const textarea = document.createElement("textarea");
    textarea.value = target.value || "{}";
    this.el.appendChild(textarea);
    
    this.editor = CodeMirror.fromTextArea(textarea, {
      mode: "javascript",
      lineNumbers: true,
      theme: "default",
      lineWrapping: true,
      height: "400px"
    });
    
    try {
      const parsed = JSON.parse(target.value || "{}");
      this.editor.setValue(JSON.stringify(parsed, null, 2));
    } catch (e) {
      this.editor.setValue(target.value || "{}");
    }
    
    this.editor.on("change", () => {
      target.value = this.editor.getValue();
      target.dispatchEvent(new Event("change", { bubbles: true }));
    });

    editors[this.el.id] = this.editor;
  },
  destroyed() {
    if (this.editor) {
      this.editor.toTextArea();
    }
  }
};

Hooks.JsonEditorSource = {
  updated() {
    try {
      const editor = editors[this.el.getAttribute("data-editor-id")];
      if (editor && this.el.value) {
        const currentValue = editor.getValue();
        if (currentValue !== this.el.value) {
          try {
            const parsed = JSON.parse(this.el.value);
            editor.setValue(JSON.stringify(parsed, null, 2));
          } catch (_e) {
            editor.setValue(this.el.value);
          }
        }
      }
    } catch (_e) { }
  }
};

Hooks.JsonView = {
  mounted() {
    const jsonStr = this.el.getAttribute("data-json");
    const textarea = document.createElement("textarea");
    
    try {
      const json = JSON.parse(jsonStr);
      textarea.value = JSON.stringify(json, null, 2);
    } catch (e) {
      textarea.value = jsonStr;
    }
    
    this.el.appendChild(textarea);
    
    this.editor = CodeMirror.fromTextArea(textarea, {
      mode: "javascript",
      lineNumbers: true,
      readOnly: true,
      theme: "default",
      lineWrapping: true
    });
  },
  updated() {
    if (this.editor) {
      const jsonStr = this.el.getAttribute("data-json");
      try {
        const json = JSON.parse(jsonStr);
        this.editor.setValue(JSON.stringify(json, null, 2));
      } catch (e) {
        this.editor.setValue(jsonStr);
      }
    }
  },
  destroyed() {
    if (this.editor) {
      this.editor.toTextArea();
    }
  }
};

Hooks.MarkdownEditor = {
  mounted() {
    const id = this.el.getAttribute("data-target-id");
    const el = document.getElementById(id);
    
    this.editor = CodeMirror.fromTextArea(el, {
      mode: "markdown",
      lineNumbers: true,
      theme: "default",
      lineWrapping: true,
      height: "300px"
    });
    
    this.editor.on("change", () => {
      el.value = this.editor.getValue();
      el.dispatchEvent(new Event("change", { bubbles: true }));
    });
  },
  destroyed() {
    if (this.editor) {
      this.editor.toTextArea();
    }
  }
};

Hooks.Actor = {
  mounted() {
    this.handleEvent("set_actor", (payload) => {
      document.cookie = "actor_resource" + "=" + encodeURIComponent(payload.resource) + ";path=/";
      document.cookie =
        "actor_primary_key" + "=" + encodeURIComponent(payload.primary_key) + ";path=/";
      document.cookie = "actor_action" + "=" + encodeURIComponent(payload.action) + ";path=/";
      document.cookie = "actor_domain" + "=" + encodeURIComponent(payload.domain) + ";path=/";
      document.cookie = "actor_tenant" + "=" + encodeURIComponent(payload.tenant) + ";path=/";
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
      document.cookie = "tenant" + "=" + payload.tenant + ";path=/";
    });
    this.handleEvent("clear_tenant", () => {
      document.cookie = "tenant" + "=" + ";path=/";
    });
  },
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
  return value != null ? decodeURIComponent(value[1]) : null;
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
