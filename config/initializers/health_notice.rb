# config/initializers/health_notice.rb
Rails.application.config.x.health_notice = ActiveSupport::InheritableOptions.new(
  version: "2025-09-16",
  body: <<~MD
    本アプリは医療行為ではありません。体調や持病・服薬によってはリスクが生じます。

    - 妊娠/授乳・小児/思春期・摂食障害の既往/症状・糖尿病など慢性疾患・低栄養に当てはまる方は、必ず医療専門職に相談してください。
    - 体調不良時は直ちに中止し、水分・電解質を補給のうえ医療機関に相談してください。
    - 目標が18時間以上の開始時は「水分・電解質の補給」「体調不良時は中止」を再確認してください（24時間以上は特に注意）。
  MD
)
