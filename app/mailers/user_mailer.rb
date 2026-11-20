class UserMailer < ApplicationMailer
  # default from: "notifications@example.com"

  def welcome_email(code)
    # @user = params[:user]
    # @url  = "http://example.com/login"
    @code = code
    mail(to: "xmasuhai@qq.com", subject: "hi")
  end
end
