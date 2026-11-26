require 'rails_helper'
require 'rspec_api_documentation/dsl'
require_relative '../support/rspec_api_documentation'

resource "账目" do
  get "/api/v1/items" do
    # 基础验证
    authentication :basic, :auth
    # 添加输入
    parameter :page, "页码"
    parameter :created_after, "创建起始时间（筛选条件）"
    parameter :created_before, "创建结束时间（筛选条件）"
    # 响应描述
    # response_field :id, "ID", scope: :resource
    # response_field :amount, "金额（单位：分）", scope: :resource
    # 共有选项语法 with_options
    with_options scope: :resources do
      response_field :id, "ID"
      response_field :amount, "金额（单位：分）"
    end

    # 传参声明示例
    let(:created_after) { "2026-11-10" }
    let(:created_before) { "2026-12-11" }
    let(:current_user) { User.create email: '1@163.com' }
    let(:auth) { "Bearer #{current_user.generate_jwt}" }

    example "获取账目" do
      11.times do
        Item.create amount: 100, created_at: "2026-11-20", user_id: current_user.id
      end
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["resources"].size).to eq 10
    end
  end
end
