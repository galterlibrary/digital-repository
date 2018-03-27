require 'rails_helper'

describe ContactFormController do
  context 'logged in user' do
    let(:user) { FactoryGirl.create(:user, username: 'badmofo') }
    before { sign_in user }

    describe "#create" do
      before do
        session['antispam_timestamp'] = (Time.now - 6.seconds).to_s
        @routes = Sufia::Engine.routes
      end

      context 'not a spam' do
        before do
          expect_any_instance_of(ContactForm).to receive(
            :deliver_now).and_return(true)
        end

        subject { post :create, contact_form: {} }

        it { is_expected.to redirect_to('/contact') }
      end

      context 'spam prevention' do
        describe "hidden customerDetail field" do
          before do
            expect_any_instance_of(ContactForm).not_to receive(:deliver_now)
          end

          subject {
            post :create,
            contact_form: { customerDetail: 'Hello future friend.' }
          }

          it { is_expected.to redirect_to('/') }
        end

        describe "antispam_timestamp is to low" do
          before do
            session['antispam_timestamp'] = (Time.now - 1).to_s
            expect_any_instance_of(ContactForm).not_to receive(:deliver_now)
          end

          subject {
            post :create, contact_form: {}
          }

          it { is_expected.to redirect_to('/') }
        end
      end
    end
  end
end
