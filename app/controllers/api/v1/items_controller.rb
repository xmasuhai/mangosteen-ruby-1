class Api::V1::ItemsController < ApplicationController
  def index
    # item = Item.page(params[:page]).per(100)
    item = Item.page params[:page]
    render json: {
      resource: item,
      pager: {
        page: params[:page],
        per_page: 100,
        count: Item.count
      }
    }
  end

  def create
    item = Item.new amount: 1
    if item.save
      render json: { resource: item }
    else
      render json: { error: item.errors }
    end
  end
end
