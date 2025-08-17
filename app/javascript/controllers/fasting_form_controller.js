import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["start", "targetHours", "end"]

  connect() { this.updateEnd() }

  updateEnd() {
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
    const endLocal = `${end.getFullYear()}-${pad(end.getMonth()+1)}-${pad(end.getDate())}T${pad(end.getHours())}:${pad(end.getMinutes())}`
    this.endTarget.value = endLocal
  }
}
