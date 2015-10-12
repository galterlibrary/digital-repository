require 'rails_helper'

describe ContactFormController do
  let(:user) { FactoryGirl.create(:user, username: 'badmofo') }
  before { sign_in user }

  describe "#create" do
    before do
      @routes = Sufia::Engine.routes
      expect_any_instance_of(ContactForm).to receive(
        :deliver_now).and_return(true)
    end

    subject { post :create, contact_form: {} }

    it { is_expected.to redirect_to('/contact') }
  end
end
