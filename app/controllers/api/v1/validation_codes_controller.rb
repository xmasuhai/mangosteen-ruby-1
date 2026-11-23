class Api::V1::ValidationCodesController < ApplicationController
  def create
    # 查找60秒内创建的 ValidationCode
    return render status: :too_many_requests if
      ValidationCode.exists?(email: params[:email], kind: "sign_in", created_at: 1.minutes.ago..Time.now)
    validation_code = ValidationCode.new email: params[:email], kind: "sign_in"
    if validation_code.save
      render status: 200
    else
      render json: { errors: validation_code.errors }, status: 422
    end
  end
end
