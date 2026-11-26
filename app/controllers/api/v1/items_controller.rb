class Api::V1::ItemsController < ApplicationController
  # 分页查询账目.
  #
  # @return [Object]
  def index
    current_user_id = request.env["current_user_id"]
    return render status: :forbidden, json: { errors: "Invalid JWT" } if current_user_id.nil?
    items = Item
      .where(user_id: current_user_id)
      .where({ created_at: params[:created_after]..params[:created_before] })
      .page(params[:page])
    render json: {
      resources: items,
      pager: {
        page: params[:page] || 1,
        per_page: Item.default_per_page,
        count: Item.count
      }
    }
  end

  # 创建账目.
  #
  # @return [Object]
  def create
    item = Item.new amount: params[:amount]
    if item.save
      render json: { resource: item }
    else
      render json: { error: item.errors }
    end
  end
end
