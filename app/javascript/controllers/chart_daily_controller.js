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

    // 空データ時は描画しない（ビュー側で文言を表示）
    if (allZero) return;

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
