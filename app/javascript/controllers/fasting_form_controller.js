import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["start", "targetHours", "end"]

  connect() {
    // 入力精度を秒に
    this.startTarget?.setAttribute("step", "1")
    this.endTarget?.setAttribute("step", "1")

    // ★ 既に end に値がある（=「終了する」直後など）場合は上書きしない
    if (!this.endTarget.value) this.updateEnd()
  }

  updateEnd() {
    // ★ end に値が入っているなら、ユーザー入力/自動終了を尊重して上書きしない
    if (this.endTarget.value) return

    const startStr = this.startTarget.value
    const hours = parseInt(this.targetHoursTarget.value, 10)
    if (!startStr || Number.isNaN(hours)) {
      this.endTarget.value = ""
      return
    }

    const start = new Date(startStr) // datetime-local はローカル時刻
    if (Number.isNaN(start.getTime())) return

    const end = new Date(start.getTime() + hours * 3600 * 1000)
    const pad = n => String(n).padStart(2, "0")
    const v = `${end.getFullYear()}-${pad(end.getMonth()+1)}-${pad(end.getDate())}`
            + `T${pad(end.getHours())}:${pad(end.getMinutes())}:${pad(end.getSeconds())}`
    this.endTarget.value = v
  }

  // （任意）“目標から再計算”ボタン用
  forceRecalc() { this.endTarget.value = ""; this.updateEnd() }
}
