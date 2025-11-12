// app/javascript/controllers/chart_daily_controller.js
import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

export default class extends Controller {
  static values = {
    labels: Array,
    data: Array,
    type: { type: String, default: "line" } // "line" or "bar"
  }

  connect() {
    const ctx = this.element.getContext("2d");
    if (this._chart) this._chart.destroy();

    const values = this.dataValue || [];
    const allZero = values.length > 0 && values.every(v => (v ?? 0) === 0);

    // ===== 空データ時の表示（HiDPI対応＋自動改行） =====
    if (allZero) {
      const c = ctx;
      const dpr  = window.devicePixelRatio || 1;
      const rect = this.element.getBoundingClientRect();

      // CSSサイズに内部解像度を合わせる
      this.element.width  = Math.max(1, Math.floor(rect.width  * dpr));
      this.element.height = Math.max(1, Math.floor(rect.height * dpr));
      c.setTransform(dpr, 0, 0, dpr, 0, 0); // scale と同等（毎回リセット安全）

      c.clearRect(0, 0, rect.width, rect.height);
      c.textAlign = "center";
      c.textBaseline = "middle";
      c.fillStyle = "rgba(68,64,60,.75)"; // stone-700 相当
      const fontSize = Math.max(12, Math.min(16, Math.floor(rect.width / 22)));
      c.font = `${fontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial`;

      const msg = "まだデータがありません（記録するとグラフが表示されます）";

      // 文字単位で改行
      const maxWidth = rect.width * 0.9;
      const lineH    = fontSize * 1.6;
      const lines = [];
      let buf = "";
      for (const ch of msg) {
        const next = buf + ch;
        if (c.measureText(next).width > maxWidth) {
          lines.push(buf);
          buf = ch;
        } else {
          buf = next;
        }
      }
      if (buf) lines.push(buf);

      const startY = rect.height / 2 - ((lines.length - 1) * lineH) / 2;
      lines.forEach((line, i) => c.fillText(line, rect.width / 2, startY + i * lineH));
      return;
    }
    // ===============================================

    this._chart = new Chart(ctx, {
      type: this.hasTypeValue ? this.typeValue : "line",
      data: {
        labels: this.labelsValue || [],
        datasets: [
          {
            label: "瞑想時間（分）",
            data: values,
            borderWidth: 2,
            tension: 0.3
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: { y: { beginAtZero: true } },
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: (c) => `${c.parsed?.y ?? 0}分` } }
        }
      }
    });
  }

  disconnect() {
    if (this._chart) this._chart.destroy();
  }
}
