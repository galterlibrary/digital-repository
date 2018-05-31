require 'rails_helper'

describe 'collection create event jobs' do
  let!(:user) { create(:user, username: 'jill') }
  let!(:collection) { make_collection(user, title: 'Hamlet', id: 'test-123') }
  let(:event) {
    "User <a href=\"/users/jill\">jill</a> has created a new Collection <a href=\"/collections/test-123\">Hamlet</a>"
  }
  let(:job) { CollectionCreateEventJob.new(collection.id, user.user_key) }

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('Collection:*').each { |key| $redis.del key }
  end

  specify do

    expect(job).to receive(:log_for_collection_follower).with(
      job.collection
    ).and_call_original
    expect(job).to receive(:log_to_followers).and_call_original
    job.run

    # Collection event stream
    expect(collection.events.length).to eq(1)
    expect(collection.events.first[:action]).to eq(event)
    
    # User event stream
    expect(user.profile_events.length).to eq(1)
    expect(user.profile_events.first[:action]).to eq(event)
  end
end
