import css from "../css/app.scss"
import "phoenix_html"
import { Socket } from "phoenix"
import NProgress from "nprogress"
import { LiveSocket, Browser } from "phoenix_live_view"
import 'alpinejs'

function cookieValue(name) {
  if (document.cookie) {
    let cookie =
      document.cookie
        .split('; ')
        .find(row => row.startsWith(name + '='))
    if (cookie) {
      let value = cookie.split('=')[1];

      if (value) {
        return value.split(';')[0]
      } else {
        return null;
      }
    } else {
      return null;
    }
  } else {
    return null;
  };
}

let socketPath = document.querySelector("html").getAttribute("phx-socket") || "/live"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let Hooks = {}
Hooks.Actor = {
  mounted() {
    this.handleEvent("set_actor", (payload) => {
      document.cookie = 'actor_resource' + '=' + payload.resource + ';path=/';
      document.cookie = 'actor_primary_key' + '=' + payload.primary_key + ';path=/';
      document.cookie = 'actor_action' + '=' + payload.action + ';path=/';
      document.cookie = 'actor_api' + '=' + payload.api + ';path=/';
    });
    this.handleEvent("clear_actor", () => {
      document.cookie = 'actor_resource' + '=' + ';path=/';
      document.cookie = 'actor_primary_key' + '=' + ';path=/';
      document.cookie = 'actor_action' + ';path=/';
      document.cookie = 'actor_api' + '=' + ';path=/';
      document.cookie = 'actor_authorizing=false;path=/';
      document.cookie = 'actor_paused=true;path=/';
    });
    this.handleEvent("toggle_authorizing", (payload) => {
      document.cookie = 'actor_authorizing' + '=' + payload.authorizing + ';path=/';
    });
    this.handleEvent("toggle_actor_paused", (payload) => {
      document.cookie = 'actor_paused' + '=' + payload.actor_paused + ';path=/';
    });
  }
}

Hooks.Tenant = {
  mounted() {
    this.handleEvent('set_tenant', (payload) => {
      document.cookie = 'tenant' + '=' + payload.tenant + ';path=/';
    })
    this.handleEvent('clear_tenant', () => {
      document.cookie = 'tenant' + '=' + ';path=/'
    })
  }
}

Hooks.FormChange = {
  mounted() {
    this.handleEvent('form_change', () => {
      this.el.dispatchEvent(new Event('change', { 'bubbles': true }))
    })
  }
}

Hooks.MaintainAttrs = {
  attrs() { return this.el.getAttribute("data-attrs").split(", ") },
  beforeUpdate() { this.prevAttrs = this.attrs().map(name => [name, this.el.getAttribute(name)]) },
  updated() { this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val)) }
}

let liveSocket = new LiveSocket(socketPath, Socket, {
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to)
      }
    }
  },
  params: { _csrf_token: csrfToken }
})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
