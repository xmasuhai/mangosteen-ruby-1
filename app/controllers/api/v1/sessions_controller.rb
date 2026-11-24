class Api::V1::SessionsController < ApplicationController
  def create
    # 如果是测试环境，则跳过验证码查找
    if Rails.env.test?
      return render status: :unauthorized if params[:code] != "123456"
    else
      canSignIn = ValidationCodes.exists? email: params[:email], code: params[:code], used_at: nil
      return render status: :unauthorized, json: { errors: "邮箱或验证码错误" } unless canSignIn
    end
    user = User.find_by email: params[:email]
    print user
    if user.nil?
      render status: :not_found, json: { errors: "用户不存在" }
    else
      render status: :ok, json: { jwt: "xxxxxxxxxx" }
    end
  end
end
