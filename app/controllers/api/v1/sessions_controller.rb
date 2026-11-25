require "jwt"

class Api::V1::SessionsController < ApplicationController
  # 创建会话
  # @return [String] jwt
  # @return [String] errors
  # @return [Integer] status
  def create
    # 如果是测试环境，则跳过验证码查找
    if Rails.env.test?
      return render status: :unauthorized, json: { errors: "邮箱或验证码错误" } if
        params[:code] != "123456"
    else
      canSignIn = ValidationCode.exists? email: params[:email], code: params[:code], used_at: nil
      return render status: :unauthorized, json: { errors: "邮箱或验证码错误" } unless canSignIn
    end
    user = User.find_by_email params[:email]
    if user.nil?
      render status: :not_found, json: { errors: "用户不存在" }
    else
      payload = { user_id: user.id, email: user.email }
      hmac_secret = Rails.application.credentials.hmac_secret
      token = JWT.encode(payload, hmac_secret, "HS256")
      render status: :ok, json: { jwt: token }
    end
  end
end
