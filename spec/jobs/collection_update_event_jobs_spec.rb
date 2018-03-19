require 'rails_helper'

describe 'collection update event jobs' do
  let!(:user) { create(:user, username: 'jill') }
  let!(:collection) { make_collection(user, title: 'Hamlet', id: 'test-123') }
  let(:event) {{
    action: "User <a href=\"/users/jill\">jill</a> has updated Collection <a href=\"/collections/test-123\">Hamlet</a>",
    timestamp: '1'
  }}
  let(:job) { CollectionUpdateEventJob.new(collection.id, user.user_key) }

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('Collection:*').each { |key| $redis.del key }
  end

  specify do
    expect(Time).to receive(:now).at_least(:once).and_return(1)

    expect(job).to receive(:log_for_collection_follower).with(
      job.collection
    ).and_call_original
    expect(job).to receive(:log_to_followers).and_call_original
    job.run

    # Collection event stream
    expect(collection.events.length).to eq(1)
    expect(collection.events.first).to eq(event)
    
    # User event stream
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first).to eq(event)
  end
end
