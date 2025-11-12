// app/javascript/controllers/chart_daily_controller.js
import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

export default class extends Controller {
  static values = {
    labels: Array,
    data: Array,
    // "line" or "bar"
    type: { type: String, default: "line" }
  }

  connect() {
    const ctx = this.element.getContext("2d");
    if (this._chart) this._chart.destroy();

    const values  = this.dataValue || [];
    const allZero = values.length > 0 && values.every(v => (v ?? 0) === 0);

    // ===== 空データ時の表示（HiDPI対応＋自動改行＋自動縮小） =====
    if (allZero) {
      const c   = ctx;
      const dpr = window.devicePixelRatio || 1;
      const rect = this.element.getBoundingClientRect();

      // 内部解像度をCSSサイズに合わせる
      this.element.width  = Math.max(1, Math.floor(rect.width  * dpr));
      this.element.height = Math.max(1, Math.floor(rect.height * dpr));
      c.setTransform(dpr, 0, 0, dpr, 0, 0);

      c.clearRect(0, 0, rect.width, rect.height);
      c.textAlign = "center";
      c.textBaseline = "middle";
      c.fillStyle = "rgba(68,64,60,.75)"; // stone-700 相当

      const msg = "まだデータがありません（記録するとグラフが表示されます）";

      // 余白と最大描画領域
      const padX = Math.max(12, Math.floor(rect.width * 0.05));
      const padY = Math.max(10, Math.floor(rect.height * 0.08));
      const boxW = Math.max(1, rect.width  - padX * 2);
      const boxH = Math.max(1, rect.height - padY * 2);

      // 指定幅に収まるように文字単位で折り返し
      const wrapLines = (fontPx) => {
        c.font = `${fontPx}px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial`;
        const lines = [];
        let buf = "";
        for (const ch of msg) {
          const next = buf + ch;
          if (c.measureText(next).width > boxW) {
            lines.push(buf);
            buf = ch;
          } else {
            buf = next;
          }
        }
        if (buf) lines.push(buf);
        return lines;
      };

      // フォントサイズを上から下げて、縦横ともに収まるサイズを探索
      const maxStart = Math.min(18, Math.floor(rect.width / 18)); // 上限（スマホで大きすぎない程度）
      const minStart = 10;
      let fontSize = maxStart;
      let lines    = wrapLines(fontSize);
      let lineH    = Math.round(fontSize * 1.6);

      while ((lines.length * lineH > boxH || lines.some(t => c.measureText(t).width > boxW)) && fontSize > minStart) {
        fontSize -= 1;
        lines  = wrapLines(fontSize);
        lineH  = Math.round(fontSize * 1.6);
      }

      // 中央に描画
      const startY = rect.height / 2 - ((lines.length - 1) * lineH) / 2;
      lines.forEach((line, i) => c.fillText(line, rect.width / 2, startY + i * lineH));

      return;
    }
    // ==========================================================

    // 通常描画（Chart.js）
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
          tooltip: {
            callbacks: {
              label: (c) => `${c.parsed?.y ?? 0}分`
            }
          }
        }
      }
    });
  }

  disconnect() {
    if (this._chart) this._chart.destroy();
  }
}
