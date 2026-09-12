require 'rails_helper'

RSpec.describe "Items", type: :request do
  describe "GET /items" do
    it "works! (now write some real specs)" do
      11.times do
        Item.new amount: 100
      end
      p "11.times------------------"
      p Item
      p "------------------11.times"
      expect(Item.count).to eq(11)
      get '/api/v1/items'
      expect(response).to have_http_status(200)
      p "response------------------"
      p response.body
      p "------------------response"
      json = JSON.parse(response.body)
      expect(json['resources'].size).to eq(10)
    end
  end
end
