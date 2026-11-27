class Api::V1::MesController < ApplicationController
  # 获取当前用户
  # @raise [StandardError]
  # @return [String] jwt
  # @return [String] errors
  # @return [Integer] status
  def show
    user_id = request.env["current_user_id"] rescue nil
    currentUser = User.find user_id
    return render status: :unauthorized, json: { errors: "Invalid JWT" } if currentUser.nil?
    render json: { resource: currentUser }
  end
end
