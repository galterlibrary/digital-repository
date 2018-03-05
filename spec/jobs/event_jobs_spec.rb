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

  context 'without generic file' do
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
      expect(job).to receive(:log_for_collection_follower).and_call_original
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
      let(:col1) { make_collection(create(:user)) }
      let(:col2) { make_collection(create(:user)) }
      let(:col3) { make_collection(create(:user)) }
      let(:col4) { make_collection(create(:user)) }

      before do
        col1.follow(follower1)
        col1.follow(follower2)
        col3.follow(follower2)
        col3.follow(follower3)
        col4.follow(follower4)
        col2.follow(follower4)
        @gf.collections << [col1, col2, col3]
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
        col1_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{col1.id}'>#{col1.title}</a>",
          timestamp: '1'
        }
        expect(follower1.events.first).to eq(col1_event)
        expect(follower2.events.length).to eq(1)
        expect(follower2.events.first).to eq(col1_event)
        expect(follower3.events.length).to eq(1)
        col3_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{col3.id}'>#{col3.title}</a>",
          timestamp: '1'
        }
        expect(follower3.events.first).to eq(col3_event)
        expect(follower4.events.length).to eq(0)
      end

      it 'cares about permissions' do
        @gf.visibility = 'restricted'
        @gf.collections << [col4]
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
        col3.visibility = 'restricted'
        col3.permissions.create(
          name: follower2.username, type: 'person', access: 'read'
        )
        col3.save!
        expect(Time).to receive(:now).at_least(:once).and_return(1)
        ContentDepositEventJob.new('test-123', @user.user_key).run

        event = {
          action: 'User <a href="/users/jill">jill</a> has deposited <a href="/files/test-123">Hamlet</a>',
          timestamp: '1'
        }

        # Follower1 has permissions to read col1 but not the gf
        expect(follower1.events.length).to eq(0)

        col1_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{col1.id}'>#{col1.title}</a>",
          timestamp: '1'
        }
        # Follower2 has permissions to read col1, col3 and the gf
        expect(follower2.events.length).to eq(2)
        expect(follower2.events).to include(col1_event)
        col3_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{col3.id}'>#{col3.title}</a>",
          timestamp: '1'
        }
        expect(follower2.events).to include(col3_event)

        # Follower3 has permissions to the gf but not col3
        expect(follower3.events.length).to eq(0)

        # Follower4 has permissions to read col2, col4 and the gf
        expect(follower4.events.length).to eq(2)
        col2_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{col2.id}'>#{col2.title}</a>",
          timestamp: '1'
        }
        expect(follower4.events).to include(col2_event)
        col4_event = {
          action: "#{event[:action]} for Collection: <a href='/collections/#{col4.id}'>#{col4.title}</a>",
          timestamp: '1'
        }
        expect(follower4.events).to include(col4_event)
      end
    end
  end
end
