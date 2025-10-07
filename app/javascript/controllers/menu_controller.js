// app/javascript/controllers/menu_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "overlay", "button"]

  connect() {
    console.log("[menu] connected v4")

    this.drawerEl  = this.hasDrawerTarget  ? this.drawerTarget  : document.getElementById("site-drawer")
    this.overlayEl = this.hasOverlayTarget ? this.overlayTarget : document.querySelector('[data-menu-target="overlay"], .menu-overlay')
    this.buttonEl  = this.hasButtonTarget  ? this.buttonTarget  : document.querySelector('button[data-action*="menu#toggle"]')

    this.isOpen = false
    this.#applyClosedStyles()
    this.buttonEl?.setAttribute("aria-expanded", "false")

    // デバッグ: window._menu.open()/close()
    window._menu = this

    // フォールバック & 伝播停止
    this._delegatedClick = (e) => {
      const btn = e.target.closest('button[data-action*="menu#toggle"]')
      if (btn) { e.preventDefault(); e.stopPropagation(); this.toggle(); return }

      const ov = e.target.closest('[data-menu-target="overlay"], .menu-overlay')
      if (ov) { e.preventDefault(); e.stopPropagation(); this.close(); }
    }
    document.addEventListener("click", this._delegatedClick, true)

    this._onKeydown = (e) => { if (e.key === "Escape") this.close() }
    window.addEventListener("keydown", this._onKeydown, true)

    this._beforeCache = () => this.close()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  disconnect() {
    document.removeEventListener("click", this._delegatedClick, true)
    window.removeEventListener("keydown", this._onKeydown, true)
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    if (window._menu === this) delete window._menu
  }

  // Actions
  toggle() { this.isOpen ? this.close() : this.open() }

  open() {
    if (!this.drawerEl || !this.overlayEl) return
    this.isOpen = true

    // --- Drawer を確実に前面 + 0px に（CSS !important を上書き） ---
    this.drawerEl.classList.add("is-open")
    this.drawerEl.classList.remove("-translate-x-full")
    this.drawerEl.style.setProperty("transform", "translateX(0)", "important")
    this.drawerEl.style.setProperty("z-index", "60", "important")

    // --- Overlay を確実に表示 ---
    this.overlayEl.classList.add("is-open")
    this.overlayEl.style.setProperty("opacity", "1", "important")
    this.overlayEl.style.setProperty("pointer-events", "auto", "important")
    this.overlayEl.style.setProperty("z-index", "55", "important")

    document.body.classList.add("menu-open", "overflow-hidden")
    this.buttonEl?.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.drawerEl || !this.overlayEl) return
    this.isOpen = false

    this.#applyClosedStyles()
    document.body.classList.remove("menu-open", "overflow-hidden")
    this.buttonEl?.setAttribute("aria-expanded", "false")
  }

  // Helpers
  #applyClosedStyles() {
    this.drawerEl?.classList.remove("is-open")
    this.drawerEl?.classList.add("-translate-x-full")
    this.drawerEl?.style.setProperty("transform", "translateX(-100%)", "important")

    this.overlayEl?.classList.remove("is-open")
    this.overlayEl?.style.setProperty("opacity", "0", "important")
    this.overlayEl?.style.setProperty("pointer-events", "none", "important")
  }
}
