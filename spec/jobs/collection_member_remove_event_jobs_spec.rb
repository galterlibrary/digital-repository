require 'rails_helper'

describe 'collection member removal event jobs' do
  let(:user) { create(:user, username: 'jill') }
  let(:follower1) { create(:user) }
  let(:follower2) { create(:user) }
  let(:event) {{
    action: "User <a href=\"/users/jill\">jill</a> has removed DOESNTEXIST from Collection <a href=\"/collections/test-123\">Hamlet</a>",
    timestamp: '1'
  }}
  let!(:collection) {
    make_collection(user, title: 'Hamlet', id: 'test-123', visibility: 'restricted')
  }
  let(:job) {
    CollectionMemberRemoveEventJob.new(
      collection.id, 'DOESNTEXIST', user.user_key
    )
  }

  before do
    follower1.follow(user)
    collection.set_follower(follower1)
    follower2.follow(user)
    collection.set_follower(follower2)
    collection.permissions.create(
      name: follower1.username, type: 'person', access: 'read'
    )
    collection.save!
  end

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('Collection:*').each { |key| $redis.del key }
  end

  it 'processes the upload and cares about permissions' do
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

    # Follower1 has permissions for both parent and child
    expect(follower1.events.length).to eq(2)
    expect(follower1.events).to include(event)

    # Follower2 has permissions for the parent only
    expect(follower2.events.length).to eq(0)
  end
end
