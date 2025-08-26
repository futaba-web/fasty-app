// app/javascript/controllers/timer_controller.js
import { Controller } from "@hotwired/stimulus"

// 使い方：
// <span data-controller="timer"
//       data-timer-start-at-value="<UNIX秒>">00:00:00</span>
export default class extends Controller {
  static values = { startAt: Number }

  connect() {
    // startAt が無い場合は何もしない
    if (!this.hasStartAtValue || !Number.isFinite(this.startAtValue)) return

    this.tick = this.tick.bind(this)

    // 初回即時反映
    this.tick()

    // 1秒ごとに更新（「終了」ボタンを押すまでカウント）
    this._interval = setInterval(this.tick, 1000)

    // Turbo/Navigate対策（キャッシュ直前にタイマー停止）
    document.addEventListener("turbo:before-cache", this._clear)
  }

  disconnect() {
    this._clear()
    document.removeEventListener("turbo:before-cache", this._clear)
  }

  // ===== private =====
  _interval = null
  _clear = () => { if (this._interval) clearInterval(this._interval) }

  tick() {
    const nowSec   = Math.floor(Date.now() / 1000)
    const elapsed  = Math.max(0, nowSec - Number(this.startAtValue)) // 経過秒
    const h = Math.floor(elapsed / 3600)
    const m = Math.floor((elapsed % 3600) / 60)
    const s = elapsed % 60

    this.element.textContent = [h, m, s].map(n => String(n).padStart(2, "0")).join(":")
  }
}
