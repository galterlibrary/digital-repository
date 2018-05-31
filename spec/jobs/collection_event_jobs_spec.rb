require 'rails_helper'

describe 'collection event jobs' do
  let(:user) { create(:user, username: 'jill') }
  let(:collection) { make_collection(user, title: ['Hamlet'], id: 'test-123') }

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('Collection:*').each { |key| $redis.del key }
  end

  context 'with followers' do
    let!(:collection) { make_collection(user) }
    let!(:follower1) { create(:user) }
    let!(:follower2) { create(:user) }
    let!(:follower3) { create(:user) }
    let(:action) { 'User <a href="/users/jill">jill</a> has done something' }

    before do
      follower1.follow(user)
      follower2.follow(user)
      follower3.follow(user)
      #allow_any_instance_of(User).to receive(:can?).and_return(true)
    end

    it 'processes collections and cares about permissions' do
      collection.visibility = 'restricted'
      collection.permissions.create(
        name: follower1.username, type: 'person', access: 'read'
      )
      collection.permissions.create(
        name: follower2.username, type: 'person', access: 'edit'
      )
      collection.save!

      job = CollectionEventJob.new(collection.id, user.user_key)
      expect(job).to receive(:log_for_collection_follower).with(
        job.collection
      ).and_call_original
      allow(job).to receive(:action).and_return(action)
      job.run

      # Fan out to followers
      expect(follower1.events.length).to eq(1)
      expect(follower1.events.first[:action]).to eq(action)
      expect(follower2.events.length).to eq(1)
      expect(follower2.events.first[:action]).to eq(action)
      # follower3 has no permission for the collection
      expect(follower3.events.length).to eq(0)
      
      # Collection event stream
      expect(collection.events.length).to eq(1)
      expect(collection.events.first[:action]).to eq(action)
      
      # User event stream
      expect(user.profile_events.length).to eq(1)
      expect(user.profile_events.first[:action]).to eq(action)
    end
  end
end
