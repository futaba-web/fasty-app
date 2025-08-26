import { Controller } from "@hotwired/stimulus"

// data-controller="timer" data-timer-start-at-value="<unix秒>"
export default class extends Controller {
  static values = { startAt: Number }

  connect() {
    this._tick = this._tick.bind(this)
    this._tick()
    this.timer = setInterval(this._tick, 1000)
  }

  disconnect() { clearInterval(this.timer) }

  _tick() {
    const sec = Math.max(0, Math.floor((Date.now() - this.startAtValue * 1000) / 1000))
    this.element.textContent = String(sec)
  }
}
