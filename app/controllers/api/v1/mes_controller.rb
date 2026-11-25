class Api::V1::MesController < ApplicationController
  # 获取当前用户
  # @raise [StandardError]
  # @return [String] jwt
  # @return [String] errors
  # @return [Integer] status
  def show
    # get jwt from header
    authorization = request.headers["Authorization"]
    # 去除Bearer
    jwt = authorization.split(" ")[1] rescue ""
    # decode jwt
    payload = JWT.decode jwt,
      Rails.application.credentials.hmac_secret,
      true, { algorithm: "HS256" } rescue nil
    if payload.nil?
      render status: :unauthorized, json: { errors: "Invalid JWT" }
      return
    end
    user_id = payload[0]["user_id"] rescue nil
    currentUser = User.find user_id
    if currentUser.nil?
      render status: :unauthorized, json: { errors: "Invalid JWT" }
      return
    end
    render json: { resource: currentUser }
  end
end
