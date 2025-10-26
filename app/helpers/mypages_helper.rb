# frozen_string_literal: true

require "set"

module MypagesHelper
  # Userに関連があってもなくても動くように吸収
  def fasting_records_for(user)
    if user.respond_to?(:fasting_records)
      user.fasting_records
    else
      FastingRecord.where(user_id: user.id)
    end
  end

  # ステータス文 + 見た目タイプ（短文に最適化）
  def fasting_hero(user)
    recs = fasting_records_for(user)

    return ["今日から始めよう！", :start] if recs.blank?

    if recs.where(end_time: nil).exists?
      days = consecutive_success_days(user)
      return ["#{days + 1}日連続で挑戦中！", :ongoing]
    end

    last = recs.where.not(end_time: nil).maximum(:end_time)&.in_time_zone&.to_date
    return ["今日は記録OK。お疲れさま！", :done] if last && last >= Date.current

    days_ago = last ? (Date.current - last).to_i : nil
    msg = days_ago ? "#{days_ago}日ぶりに再開しよう！" : "今日から始めよう！"
    [msg, :gap]
  end

  # 直近の“成功”連続日数（success列 or result='success' を自動判定）
  def consecutive_success_days(user, lookback_days: 90)
    rel = fasting_records_for(user)
            .where.not(end_time: nil)
            .where("end_time >= ?", lookback_days.days.ago)

    if FastingRecord.column_names.include?("success")
      rel = rel.where(success: true)
    elsif FastingRecord.column_names.include?("result")
      rel = rel.where(result: "success")
    else
      return 0
    end

    days = rel.pluck(:end_time).map { |t| t.in_time_zone.to_date }.to_set

    streak = 0
    day = Date.yesterday
    while days.include?(day)
      streak += 1
      day -= 1
    end
    streak
  end

  # 見た目（クラス）
  # theme: :neutral の場合はヘッダー同色＋白文字で統一し、状態は別ドットで表現
  def hero_class_for(kind, theme: :neutral)
    base = "mb-6 inline-flex items-center gap-2 w-fit mx-auto rounded-2xl px-5 py-3 text-center shadow-sm"
    return "#{base} bg-brand-header text-white" if theme == :neutral

    # 既存の色分けを残したいとき用（未使用なら削ってOK）
    case kind
    when :start   then "#{base} bg-sky-50     border border-sky-200     text-sky-900"
    when :ongoing then "#{base} bg-emerald-50 border border-emerald-200 text-emerald-900"
    when :gap     then "#{base} bg-amber-50   border border-amber-200   text-amber-900"
    when :done    then "#{base} bg-indigo-50  border border-indigo-200  text-indigo-900"
    else               "#{base} bg-gray-50    border border-gray-200    text-gray-900"
    end
  end

  # 状態ドットの色（さりげなく区別）
  def status_dot_color(kind)
    case kind
    when :start   then "bg-sky-300"
    when :ongoing then "bg-emerald-300"
    when :gap     then "bg-amber-300"
    when :done    then "bg-indigo-300"
    else               "bg-slate-300"
    end
  end
end
