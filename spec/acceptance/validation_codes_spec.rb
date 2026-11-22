require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource "验证码api" do
  post "/api/v1/validation_codes" do
    parameter :email, type: :string
    let(:email) { '1@qq.com' }

    example "请求发送验证码" do
      do_request
      expect(status).to eq 200
      # jsStr = JSON.parse response_body
      # p jsStr
      # 不直接在文档中展示验证码，只返回状态码即可
      expect(response_body).to eq " "
    end
  end
end
