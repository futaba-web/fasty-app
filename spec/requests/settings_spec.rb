# spec/requests/settings_spec.rb
require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user) }

  describe "GET /settings" do
    context "ログインしている場合（ヘルス注意事項に未同意）" do
      before do
        # Devise 認証は stub で「ログイン済み状態」を再現
        allow_any_instance_of(SettingsController)
          .to receive(:authenticate_user!).and_return(true)

        allow_any_instance_of(SettingsController)
          .to receive(:current_user).and_return(user)
      end

      it "ヘルス注意事項の同意画面にリダイレクトされること" do
        get setting_path
        expect(response).to redirect_to health_notice_path
      end
    end

    context "未ログインの場合" do
      it "ログイン画面へリダイレクトすること" do
        get setting_path
        expect(response).to redirect_to new_user_session_path
      end
    end
  end
end
