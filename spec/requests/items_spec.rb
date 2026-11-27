require 'rails_helper'

RSpec.describe "Api::V1::Items", type: :request do
  describe "账目获取（分页）" do
    it "分页验证（未登录）" do
      user1 = User.create email: '1@163.com'
      user2 = User.create email: '2@163.com'
      11.times do Item.create amount: 100, user_id: user1.id end
      5.times do Item.create amount: 100, user_id: user2.id end
      get '/api/v1/items'
      expect(response).to have_http_status :unauthorized
    end
    it "分页验证（已登录）" do
      user1 = User.create email: '1@163.com'
      user2 = User.create email: '2@163.com'
      11.times do Item.create amount: 100, user_id: user1.id end
      5.times do Item.create amount: 100, user_id: user2.id end

      # 不传 page 参数
      get '/api/v1/items', headers: user1.generate_auth_header

      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 10

      # page=2
      get '/api/v1/items?page=2', headers: user1.generate_auth_header
      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 1
    end
    it "按日期筛选" do
      user = User.create email: '1@163.com'
      # item1 = Item.create amount: 100, created_at: Time.new(2026, 1, 2)
      item1 = Item.create amount: 100, created_at: "2026-01-02", user_id: user.id
      item2 = Item.create amount: 100, created_at: "2026-02-01", user_id: user.id
      item3 = Item.create amount: 100, created_at: "2026-02-02", user_id: user.id

      get '/api/v1/items?created_after=2026-01-01&created_before=2026-02-01',
        headers: user.generate_auth_header
      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 2
      expect(json['resources'][0]['id']).to eq item1.id
      expect(json['resources'][1]['id']).to eq item2.id
      expect(json['resources'][0]['id']).not_to eq item2.id
      expect(json['resources'][0]['id']).not_to eq item3.id
    end
    it "按日期筛选（边界条件：时区）" do
      user = User.create email: '1@163.com'
      # item1 = Item.create amount: 100, created_at: Time.new(2027, 1, 1, 0, 0, 0, "+00:00")
      # item1 = Item.create amount: 100, created_at: Time.new(2027, 1, 1, 0, 0, 0, "Z")
      item1 = Item.create amount: 100, created_at: "2027-01-01", user_id: user.id

      get '/api/v1/items?created_after=2027-01-01&created_before=2027-01-02',
        headers: user.generate_auth_header

      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 1
      expect(json['resources'][0]['id']).to eq item1.id
    end
    it "按日期筛选（边界条件：开始日期范围未传参完整）" do
      user = User.create email: '1@163.com'
      item1 = Item.create amount: 100, created_at: "2027-01-01", user_id: user.id
      item2 = Item.create amount: 100, created_at: "2026-12-01", user_id: user.id

      get '/api/v1/items?created_after=2027-01-01', headers: user.generate_auth_header
      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 1
      expect(json['resources'][0]['id']).to eq item1.id
      expect(json['resources'][0]['id']).not_to eq item2.id
    end
    it "按日期筛选（边界条件：结束日期范围未传参完整）" do
      user = User.create email: '1@163.com'
      item1 = Item.create amount: 100, created_at: "2027-01-01", user_id: user.id
      item2 = Item.create amount: 100, created_at: "2027-02-01", user_id: user.id

      get '/api/v1/items?created_before=2027-01-02', headers: user.generate_auth_header
      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 1
      expect(json['resources'][0]['id']).to eq item1.id
      expect(json['resources'][0]['id']).not_to eq item2.id
    end
  end

  describe "create" do
    it "can create a item" do
      expect {
        post '/api/v1/items', params: { amount: 99 }
      }.to  change { Item.count }.by 1
      expect(response).to have_http_status :ok
      json = JSON.parse response.body
      expect(json['resource']['id']).to be_an(Numeric)
      expect(json['resource']['amount']).to eq 99
    end
  end
  # TODO: 添加更多测试用例
end
