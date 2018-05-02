require 'rails_helper'

describe 'collection upload event jobs' do
  let!(:user) { create(:user, username: 'jill') }
  let!(:follower1) { create(:user) }
  let!(:follower2) { create(:user) }
  let!(:follower3) { create(:user) }
  let!(:follower4) { create(:user) }
  let!(:collection) {
    make_collection(user, title: 'Hamlet', id: 'test-123', visibility: 'restricted')
  }
  let(:job) {
    CollectionUploadEventJob.new(
      collection.id, child.id, user.user_key
    )
  }
  let(:child_job) {
    CollectionUploadEventJob.new(
      child.id, gf.id, user.user_key
    )
  }

  before do
    follower1.follow(user)
    follower2.follow(user)
    follower3.follow(user)
    # follower1 also follows the collection
    collection.set_follower(follower1)
    collection.permissions.create(
      name: follower1.username, type: 'person', access: 'read'
    )
    child.permissions.create(
      name: follower1.username, type: 'person', access: 'read'
    )
    collection.permissions.create(
      name: follower2.username, type: 'person', access: 'read'
    )
    child.permissions.create(
      name: follower3.username, type: 'person', access: 'read'
    )
    collection.save!
    child.save!
  end

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('Collection:*').each { |key| $redis.del key }
    $redis.keys('GenericFile:*').each { |key| $redis.del key }
  end

  context 'with a Collection-type child' do
    let(:event) {
      "User <a href=\"/users/jill\">jill</a> has added <a href=\"/collections/test-321\">Lil&#39; Hamlet</a> to Collection <a href=\"/collections/test-123\">Hamlet</a>"
    }
    let(:child) { make_collection(
        user,
        title: "Lil' Hamlet",
        id: 'test-321',
        visibility: 'restricted'
    ) }

    it 'processes collections and cares about permissions' do

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

      # Follower1 has permissions for both parent and child
      expect(follower1.events.length).to eq(2)
      expect(follower1.events.first[:action]).to include(event)

      # Follower2 has permissions for the parent only
      expect(follower2.events.length).to eq(0)

      # Follower3 has permissions for the parent only
      expect(follower3.events.length).to eq(0)
    end
  end
  
  context 'with follower of child and parent collection' do
    let(:child) { make_collection(
      user,
      title: "Lil' Hamlet",
      id: 'test-321',
      visibility: 'open'
    ) }
    
    let(:gf) { make_generic_file(
        user,
        title: ["Lil' Hamlet II"],
        id: 'test-333',
        visibility: 'open'
    ) }
      
    before do
      collection.visibility = 'open'
      child.set_follower(follower4)
      collection.set_follower(follower4)
      child.members << gf
      child.collections << collection
      child.save!
      collection.save!
    end
    
    it 'does not process duplicate events for child and parent followers' do

      expect(child_job).to receive(:log_for_collection_follower).with(
        child_job.collection
      ).and_call_original
      expect(child_job).to receive(:log_to_followers).and_call_original
      child_job.run
      
      expect(follower4.events.length).to eq(1)
    end
  end
  
  context 'child with multiple parents' do
    let(:child) { make_collection(
      user,
      title: "Lil' Hamlet",
      id: 'test-321',
      visibility: 'open'
    ) }
    
    let(:gf) { make_generic_file(
        user,
        title: ["Lil' Hamlet II"],
        id: 'test-333',
        visibility: 'open'
    ) }
    
    let(:collection2) { make_collection(
      user, 
      title: 'Hamlet2', 
      id: 'test-234', 
      visibility: 'open'
    ) }
    
    before do
      collection.visibility = 'open'
      child.set_follower(follower4)
      child.members << gf
      child.collections << [collection, collection2]
      child.save!
      collection.save!
    end
    
    it 'does not spam user that only follows child, and not any of its parents' do

      expect(child_job).to receive(:log_for_collection_follower).with(
        child_job.collection
      ).and_call_original
      expect(child_job).to receive(:log_to_followers).and_call_original
      child_job.run
      
      expect(follower4.events.length).to eq(1)
    end
  end

  context 'with a GenericFile-type child' do
    let(:event) {
      "User <a href=\"/users/jill\">jill</a> has added <a href=\"/files/test-333\">Lil&#39; Hamlet II</a> to Collection <a href=\"/collections/test-123\">Hamlet</a>"
    }
    let(:child) { make_generic_file(
        user,
        title: ["Lil' Hamlet II"],
        id: 'test-333',
        visibility: 'restricted'
    ) }

    it 'processes the upload and cares about permissions' do

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

      # Follower1 has permissions for both parent and child
      expect(follower1.events.length).to eq(2)
      expect(follower1.events.first[:action]).to include(event)

      # Follower2 has permissions for the parent only
      expect(follower2.events.length).to eq(0)

      # Follower3 has permissions for the parent only
      expect(follower3.events.length).to eq(0)
    end
  end
end
