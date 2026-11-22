class Api::V1::ValidationCodesController < ApplicationController
  def create
    code = SecureRandom.random_number.to_s[2..7]
    validation_code = ValidationCode.new email: params[:email], kind: "sign_in", code: code
    if validation_code.save
      # 不直接在文档中展示验证码，只返回状态码即可
      # render json: { code: code }, status: 200
      render status: 200
    else
      render json: { errors: validation_code.errors }, status: 422
    end
  end
end
