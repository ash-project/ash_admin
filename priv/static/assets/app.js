(() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));

  // vendor/topbar.js
  var require_topbar = __commonJS({
    "vendor/topbar.js"(exports, module) {
      (function(window2, document2) {
        "use strict";
        (function() {
          var lastTime = 0;
          var vendors = ["ms", "moz", "webkit", "o"];
          for (var x = 0; x < vendors.length && !window2.requestAnimationFrame; ++x) {
            window2.requestAnimationFrame = window2[vendors[x] + "RequestAnimationFrame"];
            window2.cancelAnimationFrame = window2[vendors[x] + "CancelAnimationFrame"] || window2[vendors[x] + "CancelRequestAnimationFrame"];
          }
          if (!window2.requestAnimationFrame)
            window2.requestAnimationFrame = function(callback, element) {
              var currTime = (/* @__PURE__ */ new Date()).getTime();
              var timeToCall = Math.max(0, 16 - (currTime - lastTime));
              var id = window2.setTimeout(function() {
                callback(currTime + timeToCall);
              }, timeToCall);
              lastTime = currTime + timeToCall;
              return id;
            };
          if (!window2.cancelAnimationFrame)
            window2.cancelAnimationFrame = function(id) {
              clearTimeout(id);
            };
        })();
        var canvas, currentProgress, showing, progressTimerId = null, fadeTimerId = null, delayTimerId = null, addEvent = function(elem, type, handler) {
          if (elem.addEventListener)
            elem.addEventListener(type, handler, false);
          else if (elem.attachEvent)
            elem.attachEvent("on" + type, handler);
          else
            elem["on" + type] = handler;
        }, options = {
          autoRun: true,
          barThickness: 3,
          barColors: {
            0: "rgba(26,  188, 156, .9)",
            ".25": "rgba(52,  152, 219, .9)",
            ".50": "rgba(241, 196, 15,  .9)",
            ".75": "rgba(230, 126, 34,  .9)",
            "1.0": "rgba(211, 84,  0,   .9)"
          },
          shadowBlur: 10,
          shadowColor: "rgba(0,   0,   0,   .6)",
          className: null
        }, repaint = function() {
          canvas.width = window2.innerWidth;
          canvas.height = options.barThickness * 5;
          var ctx = canvas.getContext("2d");
          ctx.shadowBlur = options.shadowBlur;
          ctx.shadowColor = options.shadowColor;
          var lineGradient = ctx.createLinearGradient(0, 0, canvas.width, 0);
          for (var stop in options.barColors)
            lineGradient.addColorStop(stop, options.barColors[stop]);
          ctx.lineWidth = options.barThickness;
          ctx.beginPath();
          ctx.moveTo(0, options.barThickness / 2);
          ctx.lineTo(
            Math.ceil(currentProgress * canvas.width),
            options.barThickness / 2
          );
          ctx.strokeStyle = lineGradient;
          ctx.stroke();
        }, createCanvas = function() {
          canvas = document2.createElement("canvas");
          var style = canvas.style;
          style.position = "fixed";
          style.top = style.left = style.right = style.margin = style.padding = 0;
          style.zIndex = 100001;
          style.display = "none";
          if (options.className)
            canvas.classList.add(options.className);
          document2.body.appendChild(canvas);
          addEvent(window2, "resize", repaint);
        }, topbar2 = {
          config: function(opts) {
            for (var key in opts)
              if (options.hasOwnProperty(key))
                options[key] = opts[key];
          },
          show: function(delay) {
            if (showing)
              return;
            if (delay) {
              if (delayTimerId)
                return;
              delayTimerId = setTimeout(() => topbar2.show(), delay);
            } else {
              showing = true;
              if (fadeTimerId !== null)
                window2.cancelAnimationFrame(fadeTimerId);
              if (!canvas)
                createCanvas();
              canvas.style.opacity = 1;
              canvas.style.display = "block";
              topbar2.progress(0);
              if (options.autoRun) {
                (function loop() {
                  progressTimerId = window2.requestAnimationFrame(loop);
                  topbar2.progress(
                    "+" + 0.05 * Math.pow(1 - Math.sqrt(currentProgress), 2)
                  );
                })();
              }
            }
          },
          progress: function(to) {
            if (typeof to === "undefined")
              return currentProgress;
            if (typeof to === "string") {
              to = (to.indexOf("+") >= 0 || to.indexOf("-") >= 0 ? currentProgress : 0) + parseFloat(to);
            }
            currentProgress = to > 1 ? 1 : to;
            repaint();
            return currentProgress;
          },
          hide: function() {
            clearTimeout(delayTimerId);
            delayTimerId = null;
            if (!showing)
              return;
            showing = false;
            if (progressTimerId != null) {
              window2.cancelAnimationFrame(progressTimerId);
              progressTimerId = null;
            }
            (function loop() {
              if (topbar2.progress("+.1") >= 1) {
                canvas.style.opacity -= 0.05;
                if (canvas.style.opacity <= 0.05) {
                  canvas.style.display = "none";
                  fadeTimerId = null;
                  return;
                }
              }
              fadeTimerId = window2.requestAnimationFrame(loop);
            })();
          }
        };
        if (typeof module === "object" && typeof module.exports === "object") {
          module.exports = topbar2;
        } else if (typeof define === "function" && define.amd) {
          define(function() {
            return topbar2;
          });
        } else {
          this.topbar = topbar2;
        }
      }).call(exports, window, document);
    }
  });

  // js/app.js
  var import_topbar = __toESM(require_topbar());
  var socketPath = document.querySelector("html").getAttribute("phx-socket") || "/live";
  var csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  var Hooks = {};
  var editors = {};
  Hooks.JsonEditor = {
    mounted() {
      const inputId = this.el.getAttribute("data-input-id");
      const hook = this;
      this.editor = new JSONEditor(
        this.el,
        {
          onChangeText: (json2) => {
            const target = document.getElementById(inputId);
            try {
              JSON.parse(json2);
              target.value = json2;
              target.dispatchEvent(
                new Event("change", { bubbles: true, target: this.el.name })
              );
            } catch (_e) {
            }
          },
          onChange: () => {
            try {
              const target = document.getElementById(inputId);
              json = hook.editor.get();
              target.value = JSON.stringify(json);
              target.dispatchEvent(
                new Event("change", { bubbles: true, target: this.el.name })
              );
            } catch (_e) {
            }
          },
          onModeChange: (newMode) => {
            hook.mode = newMode;
          },
          modes: ["text", "tree"]
        },
        JSON.parse(document.getElementById(inputId).value)
      );
      editors[this.el.id] = this.editor;
    }
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
      } catch (_e) {
      }
    }
  };
  Hooks.JsonView = {
    updated() {
      const json2 = JSON.parse(this.el.getAttribute("data-json"));
      this.editor = new JSONEditor(
        this.el,
        {
          mode: "preview"
        },
        json2
      );
    },
    mounted() {
      const json2 = JSON.parse(this.el.getAttribute("data-json"));
      this.editor = new JSONEditor(
        this.el,
        {
          mode: "preview"
        },
        json2
      );
    }
  };
  var init = (element) => new EasyMDE({
    element,
    initialValue: element.getAttribute("value")
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
    }
  };
  Hooks.Actor = {
    mounted() {
      this.handleEvent("set_actor", (payload) => {
        document.cookie = "actor_resource=" + encodeURIComponent(payload.resource) + ";path=/";
        document.cookie = "actor_primary_key=" + encodeURIComponent(payload.primary_key) + ";path=/";
        document.cookie = "actor_action=" + encodeURIComponent(payload.action) + ";path=/";
        document.cookie = "actor_domain=" + encodeURIComponent(payload.domain) + ";path=/";
        document.cookie = "actor_tenant=" + encodeURIComponent(payload.tenant) + ";path=/";
      });
      this.handleEvent("clear_actor", () => {
        document.cookie = "actor_resource=;path=/";
        document.cookie = "actor_primary_key=;path=/";
        document.cookie = "actor_action=;path=/";
        document.cookie = "actor_tenant=;path=/";
        document.cookie = "actor_domain=;path=/";
        document.cookie = "actor_authorizing=false;path=/";
        document.cookie = "actor_paused=true;path=/";
      });
      this.handleEvent("toggle_authorizing", (payload) => {
        document.cookie = "actor_authorizing=" + payload.authorizing + ";path=/";
      });
      this.handleEvent("toggle_actor_paused", (payload) => {
        document.cookie = "actor_paused=" + payload.actor_paused + ";path=/";
      });
    }
  };
  Hooks.Tenant = {
    mounted() {
      this.handleEvent("set_tenant", (payload) => {
        document.cookie = "tenant=" + payload.tenant + ";path=/";
      });
      this.handleEvent("clear_tenant", () => {
        document.cookie = "tenant=;path=/";
      });
    }
  };
  Hooks.MaintainAttrs = {
    attrs() {
      return this.el.getAttribute("data-attrs").split(", ");
    },
    beforeUpdate() {
      this.prevAttrs = this.attrs().map((name) => [
        name,
        this.el.getAttribute(name)
      ]);
    },
    updated() {
      this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val));
    }
  };
  Hooks.Typeahead = {
    mounted() {
      this.aborter = new AbortController();
      const signal = this.aborter.signal;
      const target_id = this.el.getAttribute("data-target-id");
      const target_el = document.getElementById(target_id);
      switch (this.el.tagName) {
        case "INPUT":
          this.el.addEventListener("keydown", (e) => {
            if (e.key === "Enter") {
              e.preventDefault();
            }
          }, { signal });
          this.el.addEventListener("keyup", (e) => {
            switch (e.key) {
              case "Enter":
              case "Escape":
                this.el.blur();
                window.setTimeout(function() {
                  target_el.dispatchEvent(new Event("input", { bubbles: true }));
                }, 750);
                break;
            }
          }, { signal });
          break;
        case "LI":
          this.el.addEventListener("click", (e) => {
            window.setTimeout(function() {
              target_el.dispatchEvent(new Event("input", { bubbles: true }));
            }, 750);
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
  var params = () => {
    return {
      _csrf_token: csrfToken,
      tenant: getCookie("tenant"),
      actor_resource: getCookie("actor_resource"),
      actor_primary_key: getCookie("actor_primary_key"),
      actor_tenant: getCookie("actor_tenant"),
      actor_action: getCookie("actor_action"),
      actor_domain: getCookie("actor_domain"),
      actor_authorizing: getCookie("actor_authorizing"),
      actor_paused: getCookie("actor_paused")
    };
  };
  var liveSocket = new LiveView.LiveSocket(socketPath, Phoenix.Socket, {
    params,
    hooks: Hooks,
    dom: {
      onBeforeElUpdated(from, to) {
        if (from._x_dataStack) {
          window.Alpine.clone(from, to);
        }
      }
    }
  });
  import_topbar.default.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
  window.addEventListener("phx:page-loading-start", (_info) => import_topbar.default.show(300));
  window.addEventListener("phx:page-loading-stop", (_info) => import_topbar.default.hide());
  liveSocket.connect();
  liveSocket.enableDebug();
  window.liveSocket = liveSocket;
})();
/**
 * @license MIT
 * topbar 2.0.0, 2023-02-04
 * https://buunguyen.github.io/topbar
 * Copyright (c) 2021 Buu Nguyen
 */
