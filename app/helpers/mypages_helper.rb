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

  # ステータス文 + 見た目タイプ
  def fasting_hero(user)
    recs = fasting_records_for(user)
    return [ "ファスティングに挑戦しましょう！", :start ] if recs.blank?

    if recs.where(end_time: nil).exists?
      days = consecutive_success_days(user)
      return [ "#{days + 1}日連続で、ファスティングに挑戦中です！", :ongoing ]
    end

    last = recs.where.not(end_time: nil).maximum(:end_time)&.in_time_zone&.to_date
    return [ "今日は記録済みです。おつかれさま！", :done ] if last && last >= Date.current

    days_ago = last ? (Date.current - last).to_i : nil
    msg = days_ago ? "最後にファスティングの記録をしたのは#{days_ago}日前です" : "ファスティングに挑戦しましょう！"
    [ msg, :gap ]
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

  # ステータスボックスの色・境界線など
  def hero_class_for(kind)
    base = "mb-6 inline-block w-fit mx-auto rounded-2xl border p-5 sm:p-6 text-center"
    case kind
    when :start
      "#{base} bg-sky-50     border-sky-200     text-sky-900"
    when :ongoing
      "#{base} bg-emerald-50 border-emerald-200 text-emerald-900"
    when :gap
      "#{base} bg-amber-50   border-amber-200   text-amber-900"
    when :done
      "#{base} bg-indigo-50  border-indigo-200  text-indigo-900"
    else
      "#{base} bg-gray-50    border-gray-200    text-gray-900"
    end
  end
end
