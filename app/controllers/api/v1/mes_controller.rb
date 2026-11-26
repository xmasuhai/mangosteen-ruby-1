class Api::V1::MesController < ApplicationController
  # 获取当前用户
  # @raise [StandardError]
  # @return [String] jwt
  # @return [String] errors
  # @return [Integer] status
  def show
    # authorization = request.headers["Authorization"]
    # jwt = authorization.split(" ")[1] rescue ""
    # payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: "HS256" } rescue nil
    # return render status: :forbidden, json: { errors: "Invalid JWT" } if payload.nil?
    # user_id = payload[0]["user_id"] rescue nil

    user_id = request.env["current_user_id"] rescue nil
    currentUser = User.find user_id
    return render status: :forbidden, json: { errors: "Invalid JWT" } if currentUser.nil?
    render json: { resource: currentUser }
  end
end
