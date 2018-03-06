require 'rails_helper'

describe 'collection create event jobs' do
  let!(:user) { create(:user, username: 'jill') }
  let(:event) {{
    action: "User <a href=\"/users/jill\">jill</a> has deleted Collection test-123",
    timestamp: '1'
  }}
  let(:job) { CollectionDeleteEventJob.new('test-123', user.user_key) }

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('Collection:*').each { |key| $redis.del key }
  end

  specify do
    expect(Time).to receive(:now).at_least(:once).and_return(1)

    expect(job).not_to receive(:log_for_collection_follower)
    expect(job).not_to receive(:log_collection_event)
    job.run

    # User event stream
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
  end
end
