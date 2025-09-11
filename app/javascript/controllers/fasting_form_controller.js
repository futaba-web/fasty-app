import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["start", "targetHours", "end"]

  connect() {
    // 念のため JS 側でも step を 1 に（HTML側でも step: 1 を付けてね）
    this.startTarget?.setAttribute("step", "1")
    this.endTarget?.setAttribute("step", "1")
    this.updateEnd()
  }

  updateEnd() {
    const startStr = this.startTarget.value
    const hours = parseInt(this.targetHoursTarget.value, 10)

    if (!startStr || Number.isNaN(hours)) {
      this.endTarget.value = ""
      return
    }

    // datetime-local はローカル時刻として解釈される
    const start = new Date(startStr)
    if (Number.isNaN(start.getTime())) return

    const end = new Date(start.getTime() + hours * 3600 * 1000)

    const pad = n => String(n).padStart(2, "0")
    // ★ 秒まで含める（YYYY-MM-DDTHH:MM:SS）
    const endLocal =
      `${end.getFullYear()}-${pad(end.getMonth() + 1)}-${pad(end.getDate())}` +
      `T${pad(end.getHours())}:${pad(end.getMinutes())}:${pad(end.getSeconds())}`

    this.endTarget.value = endLocal

    // 任意: 開始より前を禁止したい場合
    // this.endTarget.min = this.startTarget.value
  }
}
