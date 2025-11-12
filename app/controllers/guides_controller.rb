# app/controllers/guides_controller.rb
class GuidesController < ApplicationController
  # 未ログインでも閲覧できるように（アプリ全体で認証をかけている場合を考慮）
  skip_before_action :authenticate_user!, only: [:show] rescue nil

  # もしアプリ側で「ヘルス通知の同意が必要」など独自フィルタがある場合は除外
  skip_before_action :require_health_notice!, only: [:show] rescue nil

  def show
    # FAQ は最初はハードコード。将来はYAMLやDBに移せます。
    @faq = [
      {
        q: "途中でやめたらどうなる？",
        a: "終了ボタンを押して終了します。計測は終了時刻までの時間で保存されます。"
      },
      {
        q: "開始・終了の時間は後から変更できる？",
        a: "記録の編集画面から変更できます。思い出した時に修正してOKです。"
      },
      {
        q: "コメントはどこで書く？",
        a: "終了後のサマリー画面にコメント欄があります。あとから編集も可能です。"
      },
      {
        q: "目標時間に届かなかったら？",
        a: "そのまま保存して大丈夫。継続が一番大切です。振り返りの材料に使いましょう。"
      },
      {
        q: "二重で開始してしまったかも…",
        a: "最新の進行中レコードのみ扱います。重複している場合は片方を削除してください。"
      }
    ]
  end
end
