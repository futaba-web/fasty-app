# app/controllers/contacts_controller.rb
require "ostruct"
class ContactsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def new
    @contact = OpenStruct.new
  end

  def create
    # まずは受理だけ（必要になったらMailerに切替）
    flash[:notice] = "お問い合わせを受け付けました。返信まで今しばらくお待ちください。"
    redirect_to new_contact_path
  end
end
