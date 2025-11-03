# app/controllers/legal_controller.rb
class LegalController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def terms;   end
  def privacy; end
end

# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def new
    @contact = OpenStruct.new
  end

  def create
    # まずはMailerなしで受理→サンクス画面へ
    flash[:notice] = "お問い合わせを受け付けました。返信まで今しばらくお待ちください。"
    redirect_to new_contact_path
  end
end
