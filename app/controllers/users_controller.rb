class UsersController < ApplicationController
  def create
    user = User.new email: "frank@x.com", name: "frank"
    if user.save
      p 'save 成功了' # rubocop:disable Style/StringLiterals
    else
      p 'save 失败了' # rubocop:disable Style/StringLiterals
    end
  end

  def show
    p "你访问了 show"
  end
end
