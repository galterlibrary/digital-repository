require 'rails_helper'

RSpec.describe 'Rack::Attack.throttle', :type => :request do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it 'includes throttle keys' do
    expect(Rack::Attack.throttles.keys).to match_array(
      ['req/subnet',
       'catalog/subnet/6',
       'catalog/subnet/7',
       'catalog/subnet/8',
       'catalog/subnet/9',
       'catalog/subnet/10']
    )
  end

  context 'safelisted ips' do
    describe 'localhost 127.0.0.1'do
      before do
        get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'
      end

      it 'success status' do
        expect(response.status).to eq(200)
      end

      it 'does not track the ip' do
        expect(request.env['rack.attack.matched']).to eq('allow from localhost')
        expect(request.env['rack.attack.match_type']).to eq(:safelist)
        expect(request.env['rack.attack.match_data']).to_not be_present
        expect(request.env['REMOTE_ADDR']).to eq('127.0.0.1')
      end
    end

    describe 'localhost ::1' do
      before do
        get '/', {}, 'REMOTE_ADDR' => '::1'
      end

      it 'success status' do
        expect(response.status).to eq(200)
      end

      it 'does not track the ip' do
        expect(request.env['rack.attack.matched']).to eq('allow from localhost')
        expect(request.env['rack.attack.match_type']).to eq(:safelist)
        expect(request.env['rack.attack.match_data']).to_not be_present
        expect(request.env['REMOTE_ADDR']).to eq('::1')
      end
    end

    describe 'NU network 165.124.0.0/16' do
      before do
        get '/', {}, 'REMOTE_ADDR' => '165.124.124.32'
      end

      it 'success status' do
        expect(response.status).to eq(200)
      end

      it 'does not track the ip' do
        expect(request.env['rack.attack.match_type']).to eq(:safelist)
        expect(request.env['rack.attack.match_data']).to_not be_present
        expect(request.env['REMOTE_ADDR']).to eq('165.124.124.32')
      end
    end

    describe 'NU network 129.105.0.0/16' do
      before do
        get '/', {}, 'REMOTE_ADDR' => '129.105.215.146'
      end

      it 'success status' do
        expect(response.status).to eq(200)
      end

      it 'does not track the ip' do
        expect(request.env['rack.attack.match_type']).to eq(:safelist)
        expect(request.env['rack.attack.match_data']).to_not be_present
        expect(request.env['REMOTE_ADDR']).to eq('129.105.215.146')
      end
    end
  end

  context 'throttle subnets' do
    describe 'not signed in user' do
      context 'all paths' do
        before do
          @period = 1.hour
          @epoch_time = Time.now.to_i
          get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
        end

        it 'counts the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:req/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to eq(1)
        end

        it 'tracks the subnet' do
          data = { :count => 1, :limit => 1000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(request.env['rack.attack.throttle_data']['req/subnet']).to eq(data)
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end

        it 'suppresses the subnet with custom response' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:req/subnet:1.2.3."
          Rack::Attack.cache.store.increment(key, 999)
          @epoch_time = Time.now.to_i

          get '/about', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 1001, :limit => 1000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(503)
          expect(response.body).to include("Please log in to get the full experience")
          expect(Rack::Attack.cache.store.read(key)).to eq(1001)
          expect(request.env['rack.attack.throttle_data']['req/subnet']).to eq(data)
        end
      end # all paths

      context '/catalog(?|/) paths' do
        before do
          @level_6_period = 64.minutes
          @level_7_period = 128.minutes
          @level_8_period = 256.minutes
          @level_9_period = 512.minutes
          @level_10_period = 1024.minutes
          @epoch_time = Time.now.to_i
          get '/catalog?q=test', {}, 'REMOTE_ADDR' => '1.2.3.4'
        end

        it 'counts the subnet' do
          key_6 = "rack::attack:#{(Time.now.to_i/@level_6_period).to_i}:catalog/subnet/6:1.2.3."
          key_7 = "rack::attack:#{(Time.now.to_i/@level_7_period).to_i}:catalog/subnet/7:1.2.3."
          key_8 = "rack::attack:#{(Time.now.to_i/@level_8_period).to_i}:catalog/subnet/8:1.2.3."
          key_9 = "rack::attack:#{(Time.now.to_i/@level_9_period).to_i}:catalog/subnet/9:1.2.3."
          key_10 = "rack::attack:#{(Time.now.to_i/@level_10_period).to_i}:catalog/subnet/10:1.2.3."
          expect(Rack::Attack.cache.store.read(key_6)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_7)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_8)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_9)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_10)).to eq(1)
        end

        it 'does not count /catalog only' do
          get '/catalog', {}, 'REMOTE_ADDR' => '1.2.3.4'

          key_6 = "rack::attack:#{(Time.now.to_i/@level_6_period).to_i}:catalog/subnet/6:1.2.3."
          key_7 = "rack::attack:#{(Time.now.to_i/@level_7_period).to_i}:catalog/subnet/7:1.2.3."
          key_8 = "rack::attack:#{(Time.now.to_i/@level_8_period).to_i}:catalog/subnet/8:1.2.3."
          key_9 = "rack::attack:#{(Time.now.to_i/@level_9_period).to_i}:catalog/subnet/9:1.2.3."
          key_10 = "rack::attack:#{(Time.now.to_i/@level_10_period).to_i}:catalog/subnet/10:1.2.3."
          expect(Rack::Attack.cache.store.read(key_6)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_7)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_8)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_9)).to eq(1)
          expect(Rack::Attack.cache.store.read(key_10)).to eq(1)
        end

        it 'tracks the subnet' do
          data_6 = { :count => 1, :limit => 96,
                   :period => @level_6_period.to_i, :epoch_time => @epoch_time }
          data_7 = { :count => 1, :limit => 112,
                   :period => @level_7_period.to_i, :epoch_time => @epoch_time }
          data_8 = { :count => 1, :limit => 128,
                   :period => @level_8_period.to_i, :epoch_time => @epoch_time }
          data_9 = { :count => 1, :limit => 144,
                   :period => @level_9_period.to_i, :epoch_time => @epoch_time }
          data_10 = { :count => 1, :limit => 160,
                   :period => @level_10_period.to_i, :epoch_time => @epoch_time }
          expect(request.env['rack.attack.throttle_data']['catalog/subnet/6']).to eq(data_6)
          expect(request.env['rack.attack.throttle_data']['catalog/subnet/7']).to eq(data_7)
          expect(request.env['rack.attack.throttle_data']['catalog/subnet/8']).to eq(data_8)
          expect(request.env['rack.attack.throttle_data']['catalog/subnet/9']).to eq(data_9)
          expect(request.env['rack.attack.throttle_data']['catalog/subnet/10']).to eq(data_10)
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end

        it 'suppresses subnet/6' do
          key_6 = "rack::attack:#{(Time.now.to_i/@level_6_period).to_i}:catalog/subnet/6:1.2.3."
          Rack::Attack.cache.store.increment(key_6, 95)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.7'
          data_6 = { :count => 97, :limit => 96,
                   :period => @level_6_period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(503)
          expect(response.body).to include("Please log in")
          expect(Rack::Attack.cache.store.read(key_6)).to eq(97)
          expect(
            request.env['rack.attack.throttle_data']['catalog/subnet/6']
          ).to eq(data_6)
        end

        it 'suppresses subnet/7' do
          key_7 = "rack::attack:#{(Time.now.to_i/@level_7_period).to_i}:catalog/subnet/7:1.2.3."
          Rack::Attack.cache.store.increment(key_7, 111)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 113, :limit => 112,
                   :period => @level_7_period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(503)
          expect(response.body).to include("Please log in")
          expect(Rack::Attack.cache.store.read(key_7)).to eq(113)
          expect(
            request.env['rack.attack.throttle_data']['catalog/subnet/7']
          ).to eq(data)
        end

        it 'suppresses subnet/8' do
          key_8 = "rack::attack:#{(Time.now.to_i/@level_8_period).to_i}:catalog/subnet/8:1.2.3."
          Rack::Attack.cache.store.increment(key_8, 127)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 129, :limit => 128,
                   :period => @level_8_period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(503)
          expect(response.body).to include("Please log in")
          expect(Rack::Attack.cache.store.read(key_8)).to eq(129)
          expect(
            request.env['rack.attack.throttle_data']['catalog/subnet/8']
          ).to eq(data)
        end

        it 'suppresses subnet/9' do
          key_9 = "rack::attack:#{(Time.now.to_i/@level_9_period).to_i}:catalog/subnet/9:1.2.3."
          Rack::Attack.cache.store.increment(key_9, 143)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 145, :limit => 144,
                   :period => @level_9_period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(503)
          expect(response.body).to include("Please log in")
          expect(Rack::Attack.cache.store.read(key_9)).to eq(145)
          expect(
            request.env['rack.attack.throttle_data']['catalog/subnet/9']
          ).to eq(data)
        end

        it 'suppresses subnet/10' do
          key_10 = "rack::attack:#{(Time.now.to_i/@level_10_period).to_i}:catalog/subnet/10:1.2.3."
          Rack::Attack.cache.store.increment(key_10, 159)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 161, :limit => 160,
                   :period => @level_10_period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(503)
          expect(response.body).to include("Please log in")
          expect(Rack::Attack.cache.store.read(key_10)).to eq(161)
          expect(
            request.env['rack.attack.throttle_data']['catalog/subnet/10']
          ).to eq(data)
        end
      end # /catalog paths
    end # not signed in user

    describe 'signed in user' do
      let(:user) { create(:user) }

      before do
        @period = 1.hour

        RSpec.configure do |config|
          config.include Warden::Test::Helpers
        end

        login_as user
      end

      context 'all paths' do
        before do
          @epoch_time = Time.now.to_i
          get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
        end

        it 'does not track the ip' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:req/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to be_nil 
          expect(request.env['rack.attack.matched']).to eq('authenticated user')
          expect(request.env['rack.attack.match_type']).to eq(:safelist)
          expect(request.env['rack.attack.match_data']).to_not be_present
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end
      end # all paths

      context '/catalog(?|/) paths' do
        before do
          @epoch_time = Time.now.to_i
          get '/catalog?q=test', {}, 'REMOTE_ADDR' => '1.2.3.4'
        end

        it 'does not track the ip' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to be_nil
          expect(request.env['rack.attack.matched']).to eq('authenticated user')
          expect(request.env['rack.attack.match_type']).to eq(:safelist)
          expect(request.env['rack.attack.match_data']).to_not be_present
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end
      end # /catalog paths
    end # signed in user
  end

  after(:all) do
    Rack::Attack.clear_configuration
  end
end
