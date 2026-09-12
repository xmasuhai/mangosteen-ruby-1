class Api::V1::ItemsController < ApplicationController
  def index
    # item = Item.page(params[:page]).per(100)
    items = Item.page params[:page]
    render json: {
      resources: items,
      pager: {
        page: params[:page],
        per_page: 100,
        count: Item.count
      }
    }
  end

  def create
    item = Item.new amount: params[:amount]
    if item.save
      render json: { resource: item }
    else
      render json: { error: item.errors }
    end
  end
end
