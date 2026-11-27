require 'rails_helper'
require "active_support/testing/time_helpers"

RSpec.describe "Api::V1::Mes", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  describe "获取当前用户" do
    it "登录后成功获取" do
      user = User.create email: 'xmasuhai@163.com'
      post '/api/v1/session',
        params: { email: 'xmasuhai@163.com', code: '123456' }
      json = JSON.parse response.body
      jwtString = json["jwt"]
      expect(jwtString).to be_a(String)
      headers = {
        "Authorization" => "Bearer #{jwtString}",
        "Accept" => "application/json"
      }
      get '/api/v1/me', headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse response.body
      resource = json["resource"]
      expect(resource["email"]).to eq "xmasuhai@163.com"
      expect(resource["id"]).to eq user.id
    end
    it "jwt 过期" do
      travel_to Time.now - 3.hours
      user = User.create email: '1@163.com'
      jwt = user.generate_jwt
      travel_back
      get "/api/v1/me", headers: { "Authorization": "Bearer #{jwt}" }
      expect(response).to have_http_status(:unauthorized)
    end
    it "jwt 未过期" do
      travel_to Time.now - 1.hours
      user = User.create email: '1@163.com'
      jwt = user.generate_jwt
      travel_back
      get "/api/v1/me", headers: { "Authorization": "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
    end
  end
end
