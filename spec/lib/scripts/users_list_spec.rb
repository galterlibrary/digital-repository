require 'rails_helper'
require "#{Rails.root}/lib/scripts/users_list"

RSpec.describe 'lib/scripts/users_list.rb' do
  describe 'UsersList' do
    subject { UsersList.new }

    it '#initialize' do
      expect(subject).to be_truthy
      expect(subject.csv_file).to be_truthy
    end

    describe '#populate_user_info' do
      let!(:test_date) { DateTime.now.in_time_zone('Central Time (US & Canada)') }

      before do
        FactoryGirl.create(:user, formal_name: "Vera, Sam", username: "abc123",
                           email: "fake@email.com", title: "Technical Lead",
                           address: "123 ABC Ave. Chicago, Ill",
                           last_sign_in_at: test_date,
                           current_sign_in_at: test_date)
      end

      it 'adds user info to users_list.csv' do
        subject.populate_user_info
        users_list_result = File.readlines(
          "#{Rails.root}/lib/scripts/results/users_list.csv"
        )
        expected_data = "\"Vera, Sam\",abc123,fake@email.com,Technical Lead,\"123 ABC Ave. Chicago, Ill\",#{test_date},#{test_date},0,No File Uploaded\n"

        expect(users_list_result[1]).to eq(expected_data)
      end
    end # #populate_user_info
  end

  after do
    FileUtils.rm_f(Dir["#{Rails.root}/lib/scripts/results/users_list.csv"])
  end
end
