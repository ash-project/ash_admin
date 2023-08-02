import "phoenix_html";
import { Socket } from "phoenix";
import topbar from "../vendor/topbar";
import { LiveSocket } from "phoenix_live_view";

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
    const hook = this;
    this.editor = new JSONEditor(
      this.el,
      {
        onChangeText: (json) => {
          const target = document.getElementById(inputId);
          try {
            JSON.parse(json);
            target.value = json;
            target.dispatchEvent(new Event("change", { bubbles: true }));
          } catch (_e) {}
        },
        onChange: () => {
          try {
            const target = document.getElementById(inputId);
            json = hook.editor.get();

            target.value = JSON.stringify(json);
            target.dispatchEvent(new Event("change", { bubbles: true }));
          } catch (_e) {}
        },
        onModeChange: (newMode) => {
          hook.mode = newMode;
        },
        modes: ["text", "tree"],
      },
      JSON.parse(document.getElementById(inputId).value)
    );

    editors[this.el.id] = this.editor;
  },
};

Hooks.JsonEditorSource = {
  updated() {
    try {
      let editor = editors[this.el.getAttribute("data-editor-id")];
      if (editor.getMode() === "tree") {
        editor.update(JSON.parse(this.el.value));
      } else {
        if (editor.get() !== JSON.parse(this.el.value)) {
          editor.setText(this.el.value);
        } else {
        }
      }
    } catch (_e) {}
  },
};

Hooks.JsonView = {
  updated() {
    const json = JSON.parse(this.el.getAttribute("data-json"));
    this.editor = new JSONEditor(
      this.el,
      {
        mode: "preview",
      },
      json
    );
  },
  mounted() {
    const json = JSON.parse(this.el.getAttribute("data-json"));
    this.editor = new JSONEditor(
      this.el,
      {
        mode: "preview",
      },
      json
    );
  },
};

const init = (element) =>
  new EasyMDE({
    element: element,
    initialValue: element.getAttribute("value"),
  });

Hooks.MarkdownEditor = {
  mounted() {
    const id = this.el.getAttribute("data-target-id");
    const el = document.getElementById(id);
    const easyMDE = init(el);
    easyMDE.codemirror.on("change", () => {
      el.value = easyMDE.value();
      el.dispatchEvent(new Event("change", { bubbles: true }));
    });
  },
};

Hooks.Actor = {
  mounted() {
    this.handleEvent("set_actor", (payload) => {
      document.cookie = "actor_resource" + "=" + payload.resource + ";path=/";
      document.cookie =
        "actor_primary_key" + "=" + payload.primary_key + ";path=/";
      document.cookie = "actor_action" + "=" + payload.action + ";path=/";
      document.cookie = "actor_api" + "=" + payload.api + ";path=/";
    });
    this.handleEvent("clear_actor", () => {
      document.cookie = "actor_resource" + "=" + ";path=/";
      document.cookie = "actor_primary_key" + "=" + ";path=/";
      document.cookie = "actor_action" + ";path=/";
      document.cookie = "actor_api" + "=" + ";path=/";
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

    this.pushEvent("set_actor_from_session", {
      actor_resource: document.cookie.actor_resource,
      actor_primary_key: document.cookie.actor_primary_key,
      actor_action: document.cookie.actor_action,
      actor_api: document.cookie.actor_api,
      actor_authorizing: document.cookie.actor_authorizing,
      actor_paused: document.cookie.actor_paused
    })
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

let liveSocket = new LiveSocket(socketPath, Socket, {
  params: { _csrf_token: csrfToken },
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
liveSocket.connect() >>
  // expose liveSocket on window for web console debug logs and latency simulation:
  liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)

window.liveSocket = liveSocket;
