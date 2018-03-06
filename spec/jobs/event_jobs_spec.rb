require 'rails_helper'

describe 'collection following event jobs' do
  before do
    @user = create(:user, username: 'jill', email: 'jill')
    @another_user = create(:user, username: 'archivist')
    @third_user = create(:user, username: 'curator')
    @gf = GenericFile.new(id: 'test-123')
    @gf.apply_depositor_metadata(@user)
    @gf.title = ['Hamlet']
    @gf.save
  end

  after do
    $redis.keys('events:*').each { |key| $redis.del key }
    $redis.keys('User:*').each { |key| $redis.del key }
    $redis.keys('GenericFile:*').each { |key| $redis.del key }
  end

  context 'without generic file or collection' do
    it "logs user edit profile events" do
      # UserEditProfile should log the event to the editor's dashboard and his/her followers' dashboards
      @another_user.follow(@user)
      count_user = @user.events.length
      count_another = @another_user.events.length
      expect(Time).to receive(:now).at_least(:once).and_return(1)
      event = {
        action: 'User <a href="/users/jill">jill</a> has edited his or her profile',
        timestamp: '1'
      }
      job = UserEditProfileEventJob.new(@user.user_key)
      expect(job).not_to receive(:log_for_collection_follower)
      job.run
      expect(@user.events.length).to eq(count_user + 1)
      expect(@user.events.first).to eq(event)
      expect(@another_user.events.length).to eq(count_another + 1)
      expect(@another_user.events.first).to eq(event)
    end
  end

  context 'with generic file' do
    describe 'without parent collections' do
      it "logs content deposit events" do
        @another_user.follow(@user)
        @third_user.follow(@user)
        allow_any_instance_of(User).to receive(:can?).and_return(true)
        expect(@user.profile_events.length).to eq(0)
        expect(@another_user.events.length).to eq(0)
        expect(@third_user.events.length).to eq(0)
        expect(@gf.events.length).to eq(0)
        expect(Time).to receive(:now).at_least(:once).and_return(1)
        event = {
          action: 'User <a href="/users/jill">jill</a> has deposited <a href="/files/test-123">Hamlet</a>',
          timestamp: '1'
        }
        job = ContentDepositEventJob.new('test-123', @user.user_key)
        expect(job).to receive(:log_for_collection_follower).and_call_original
        job.run
        expect(@user.profile_events.length).to eq(1)
        expect(@user.profile_events.first).to eq(event)
        expect(@another_user.events.length).to eq(1)
        expect(@another_user.events.first).to eq(event)
        expect(@third_user.events.length).to eq(1)
        expect(@third_user.events.first).to eq(event)
        expect(@gf.events.length).to eq(1)
        expect(@gf.events.first).to eq(event)
      end
    end

    describe 'with parent collections and followers' do
      let(:follower1) { create(:user) }
      let(:follower2) { create(:user) }
      let(:follower3) { create(:user) }
      let(:follower4) { create(:user) }
      let(:parent1) { make_collection(create(:user)) }
      let(:parent2) { make_collection(create(:user)) }
      let(:parent3) { make_collection(create(:user)) }
      let(:parent4) { make_collection(create(:user)) }

      before do
        parent1.follow(follower1)
        parent1.follow(follower2)
        parent3.follow(follower2)
        parent3.follow(follower3)
        parent4.follow(follower4)
        parent2.follow(follower4)
        @gf.collections << [parent1, parent2, parent3]
      end

      it "logs content deposit events for user and collection followers" do
        @another_user.follow(@user)
        @third_user.follow(@user)
        allow_any_instance_of(User).to receive(:can?).and_return(true)
        expect(@user.profile_events.length).to eq(0)
        expect(@another_user.events.length).to eq(0)
        expect(@third_user.events.length).to eq(0)
        expect(@gf.events.length).to eq(0)
        expect(Time).to receive(:now).at_least(:once).and_return(1)
        event = {
          action: 'User <a href="/users/jill">jill</a> has deposited <a href="/files/test-123">Hamlet</a>',
          timestamp: '1'
        }
        job = ContentDepositEventJob.new('test-123', @user.user_key)
        expect(job).to receive(:log_for_collection_follower).and_call_original
        job.run
        expect(@user.profile_events.length).to eq(1)
        expect(@user.profile_events.first).to eq(event)
        expect(@another_user.events.length).to eq(1)
        expect(@another_user.events.first).to eq(event)
        expect(@third_user.events.length).to eq(1)
        expect(@third_user.events.first).to eq(event)
        expect(@gf.events.length).to eq(1)
        expect(@gf.events.first).to eq(event)
        # Collection following related
        expect(follower1.events.length).to eq(1)
        parent1_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent1.id}'>#{parent1.title}</a>",
          timestamp: '1'
        }
        expect(follower1.events.first).to eq(parent1_event)

        expect(follower2.events.length).to eq(2)
        expect(follower2.events).to include(parent1_event)
        parent3_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent3.id}'>#{parent3.title}</a>",
          timestamp: '1'
        }
        expect(follower2.events).to include(parent3_event)

        expect(follower3.events.length).to eq(1)
        expect(follower3.events.first).to eq(parent3_event)

        parent2_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent2.id}'>#{parent2.title}</a>",
          timestamp: '1'
        }
        expect(follower4.events.length).to eq(1)
        expect(follower4.events.first).to eq(parent2_event)
      end

      it 'cares about permissions' do
        @gf.visibility = 'restricted'
        @gf.collections << [parent4]
        @gf.permissions.create(
          name: follower2.username, type: 'person', access: 'read'
        )
        @gf.permissions.create(
          name: follower3.username, type: 'person', access: 'read'
        )
        @gf.permissions.create(
          name: follower4.username, type: 'person', access: 'edit'
        )
        @gf.save!
        parent3.visibility = 'restricted'
        parent3.permissions.create(
          name: follower2.username, type: 'person', access: 'read'
        )
        parent3.save!
        expect(Time).to receive(:now).at_least(:once).and_return(1)
        ContentDepositEventJob.new('test-123', @user.user_key).run

        event = {
          action: 'User <a href="/users/jill">jill</a> has deposited <a href="/files/test-123">Hamlet</a>',
          timestamp: '1'
        }

        # Follower1 has permissions to read parent1 but not the gf
        expect(follower1.events.length).to eq(0)

        parent1_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent1.id}'>#{parent1.title}</a>",
          timestamp: '1'
        }
        # Follower2 has permissions to read parent1, parent3 and the gf
        expect(follower2.events.length).to eq(2)
        expect(follower2.events).to include(parent1_event)
        parent3_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent3.id}'>#{parent3.title}</a>",
          timestamp: '1'
        }
        expect(follower2.events).to include(parent3_event)

        # Follower3 has permissions to the gf but not parent3
        expect(follower3.events.length).to eq(0)

        # Follower4 has permissions to read parent2, parent4 and the gf
        expect(follower4.events.length).to eq(2)
        parent2_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent2.id}'>#{parent2.title}</a>",
          timestamp: '1'
        }
        expect(follower4.events).to include(parent2_event)
        parent4_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{parent4.id}'>#{parent4.title}</a>",
          timestamp: '1'
        }
        expect(follower4.events).to include(parent4_event)
      end
    end
  end

  context 'with a collection' do
    let!(:collection) { make_collection(@user) }
    let!(:follower1) { create(:user) }
    let!(:follower2) { create(:user) }
    let!(:follower3) { create(:user) }
    let!(:follower4) { create(:user) }
    let!(:parent1) { make_collection(create(:user)) }
    let!(:parent2) { make_collection(create(:user)) }
    let!(:parent3) { make_collection(create(:user)) }
    let!(:parent4) { make_collection(create(:user)) }
    let(:action) { 'User <a href="/users/jill">jill</a> has done something' }
    let(:event) {{ action: action, timestamp: '1' }}

    before do
      parent1.follow(follower1)
      parent1.follow(follower2)
      parent3.follow(follower2)
      parent3.follow(follower3)
      parent4.follow(follower4)
      parent2.follow(follower4)
      collection.collections << [parent1, parent2, parent3, parent4]
    end

    it 'processes collections and cares about permissions' do
      collection.visibility = 'restricted'
      collection.permissions.create(
        name: follower2.username, type: 'person', access: 'read'
      )
      collection.permissions.create(
        name: follower3.username, type: 'person', access: 'read'
      )
      collection.permissions.create(
        name: follower4.username, type: 'person', access: 'edit'
      )
      collection.save!
      parent3.visibility = 'restricted'
      parent3.permissions.create(
        name: follower2.username, type: 'person', access: 'read'
      )
      parent3.save!

      expect(Time).to receive(:now).at_least(:once).and_return(1)
      job = EventJob.new(@user.user_key)
      allow(job).to receive(:collection).and_return(collection)
      allow(job).to receive(:action).and_return(action)
      job.run

      # Follower1 has permissions to read parent1 but not the gf
      expect(follower1.events.length).to eq(0)

      parent1_event = {
        action: "#{event[:action]} for Collection: <a href='/collections/#{parent1.id}'>#{parent1.title}</a>",
        timestamp: '1'
      }
      # Follower2 has permissions to read parent1, parent3 and the gf
      expect(follower2.events.length).to eq(2)
      expect(follower2.events).to include(parent1_event)
      parent3_event = {
        action: "#{event[:action]} for Collection: <a href='/collections/#{parent3.id}'>#{parent3.title}</a>",
        timestamp: '1'
      }
      expect(follower2.events).to include(parent3_event)

      # Follower3 has permissions to the gf but not parent3
      expect(follower3.events.length).to eq(0)

      # Follower4 has permissions to read parent2, parent4 and the gf
      expect(follower4.events.length).to eq(2)
      parent2_event = {
        action: "#{event[:action]} for Collection: <a href='/collections/#{parent2.id}'>#{parent2.title}</a>",
        timestamp: '1'
      }
      expect(follower4.events).to include(parent2_event)
      parent4_event = {
        action: "#{event[:action]} for Collection: <a href='/collections/#{parent4.id}'>#{parent4.title}</a>",
        timestamp: '1'
      }
      expect(follower4.events).to include(parent4_event)
    end
  end
end
