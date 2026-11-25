class Api::V1::MesController < ApplicationController
  # 获取当前用户
  # @return [String] jwt
  # @return [String] errors
  # @return [Integer] status
  def show
    # get jwt from header
    authorization = request.headers["Authorization"]
    # 去除Bearer
    jwt = authorization.split(" ")[1]
    # decode jwt
    payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: "HS256" }
    user_id = payload[0]["user_id"]
    userOk = User.find user_id
    render json: { resource: userOk }
  end
end
