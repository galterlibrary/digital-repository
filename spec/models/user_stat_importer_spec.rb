require 'rails_helper'
require 'sufia/models/stats/user_stat_importer'

RSpec.describe Sufia::UserStatImporter do
  describe 'sorted_users' do
    let!(:user1) { create(:user, username: 'user1') }
    let!(:user2) { create(:user, username: 'user2') }
    let!(:inst_user) { create(:user, username: 'institutional-user') }

    subject { Sufia::UserStatImporter.new.sorted_users }

    before do
      allow_any_instance_of(User).to receive(:last_stats_update) {
        Time.now
      }
    end

    it 'ignores the institutional users' do
      expect(subject.map(&:user_key)).to eq(['user1', 'user2'])
      expect(subject).to all(
        be_an_instance_of(Sufia::UserStatImporter::UserRecord)
      )
    end
  end
end
