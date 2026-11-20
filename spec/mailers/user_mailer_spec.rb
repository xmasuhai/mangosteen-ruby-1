require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#welcome_email" do
    let(:mail) { described_class.welcome_email("012345") }

    it "renders the verification code with its leading zero in the HTML body" do
      expect(mail.body.decoded).to include("code: 012345")
    end

    context "when an SMTP username is configured" do
      let(:smtp_username) { "xmasuhai@qq.com" }

      before do
        allow(described_class).to receive(:smtp_settings).and_return(user_name: smtp_username)
      end

      it "uses the SMTP username as the header and envelope sender" do
        expect(mail.from).to eq([smtp_username])
        expect(mail.smtp_envelope_from).to eq(smtp_username)
      end

      it "keeps the configured recipient" do
        expect(mail.to).to eq(["xmasuhai@qq.com"])
      end
    end

    context "when no SMTP username is configured" do
      before do
        allow(described_class).to receive(:smtp_settings).and_return({})
      end

      it "uses the existing default sender" do
        expect(mail.from).to eq(["xmasuhai@qq.com"])
      end
    end
  end
end
