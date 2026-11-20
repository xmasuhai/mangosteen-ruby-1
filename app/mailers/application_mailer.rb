class ApplicationMailer < ActionMailer::Base
  # default from: -> { smtp_settings[:user_name].presence || "xmasuhai@qq.com" }
  default from: "xmasuhai@qq.com"
  layout "mailer"
end
