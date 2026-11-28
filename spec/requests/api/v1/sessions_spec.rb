require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "登录会话" do
    it "可以登录（创建会话）" do
      user = User.create email: '1@163.com'
      post '/api/v1/session', params: { email: user.email, code: '123456' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse response.body
      expect(json["jwt"]).to be_a(String)
    end
    it "首次登录" do
      post '/api/v1/session', params: { email: "1@qq.com", code: '123456' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse response.body
      expect(json["jwt"]).to be_a(String)
    end
  end
end
