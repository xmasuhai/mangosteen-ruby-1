require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "登录会话" do
    it "可以登录（创建会话）" do
      User.create email: 'xmasuhai@163.com'
      post '/api/v1/session',
        params: { email: 'xmasuhai@163.com', code: '123456' }
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      decoded_token = JWT.decode json["jwt"],
        "my$ecretK3y", true, { algorithm: 'HS256' }
      p("jwt_______________________")
      p json["jwt"]
      jwt_parts = json["jwt"].split(".")
      p jwt_parts
      p decoded_token
      p("_______________________jwt")
      expect(json["jwt"]).to be_a(String)
    end
  end
end
