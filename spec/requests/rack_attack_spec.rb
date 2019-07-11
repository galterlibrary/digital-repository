require 'rails_helper'

RSpec.describe 'Rack::Attack.throttle', :type => :request do
  before do
    @period = 1.hour
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it 'includes throttle keys' do
    expect(Rack::Attack.throttles.keys).to match_array(['req/subnet', 'catalog/subnet'])
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

        it 'suppresses the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:req/subnet:1.2.3."
          Rack::Attack.cache.store.increment(key, 999)
          @epoch_time = Time.now.to_i

          get '/about', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 1001, :limit => 1000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(429)
          expect(response.headers['Retry-After']).to eq(@period.to_s)
          expect(Rack::Attack.cache.store.read(key)).to eq(1001)
          expect(request.env['rack.attack.throttle_data']['req/subnet']).to eq(data)
        end
      end # all paths

      context '/catalog(?|/) paths' do
        before do
          @epoch_time = Time.now.to_i
          get '/catalog?q=test', {}, 'REMOTE_ADDR' => '1.2.3.4'
        end

        it 'counts the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to eq(1)
        end

        it 'does not count /catalog only' do
          get '/catalog', {}, 'REMOTE_ADDR' => '1.2.3.4'

          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to eq(1)
        end

        it 'tracks the subnet' do
          data = { :count => 1, :limit => 100,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(request.env['rack.attack.throttle_data']['catalog/subnet']).to eq(data)
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end

        it 'suppresses the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          Rack::Attack.cache.store.increment(key, 99)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 101, :limit => 100,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(429)
          expect(response.headers['Retry-After']).to eq(@period.to_s)
          expect(Rack::Attack.cache.store.read(key)).to eq(101)
          expect(
            request.env['rack.attack.throttle_data']['catalog/subnet']
          ).to eq(data)
        end
      end # /catalog paths
    end # not signed in user

    describe 'signed in user' do
      let(:user) { create(:user) }

      before do
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

        it 'counts the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:req/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to eq(1)
        end

        it 'tracks the subnet' do
          data = { :count => 1, :limit => 10000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(request.env['rack.attack.throttle_data']['req/subnet']).to eq(data)
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end

        it 'suppresses the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:req/subnet:1.2.3."
          Rack::Attack.cache.store.increment(key, 9999)
          @epoch_time = Time.now.to_i

          get '/about', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 10001, :limit => 10000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(429)
          expect(response.headers['Retry-After']).to eq(@period.to_s)
          expect(Rack::Attack.cache.store.read(key)).to eq(10001)
          expect(request.env['rack.attack.throttle_data']['req/subnet']).to eq(data)
        end
      end # all paths

      context '/catalog(?|/) paths' do
        before do
          @epoch_time = Time.now.to_i
          get '/catalog?q=test', {}, 'REMOTE_ADDR' => '1.2.3.4'
        end

        it 'counts the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to eq(1)
        end

        it 'does not count /catalog only' do
          get '/catalog', {}, 'REMOTE_ADDR' => '1.2.3.4'

          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          expect(Rack::Attack.cache.store.read(key)).to eq(1)
        end

        it 'tracks the subnet' do
          data = { :count => 1, :limit => 5000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(request.env['rack.attack.throttle_data']['catalog/subnet']).to eq(data)
          expect(request.env['REMOTE_ADDR']).to eq('1.2.3.4')
        end

        it 'suppresses the subnet' do
          key = "rack::attack:#{(Time.now.to_i/@period).to_i}:catalog/subnet:1.2.3."
          Rack::Attack.cache.store.increment(key, 4999)
          @epoch_time = Time.now.to_i

          get '/catalog/suppressed', {}, 'REMOTE_ADDR' => '1.2.3.5'
          data = { :count => 5001, :limit => 5000,
                   :period => @period.to_i, :epoch_time => @epoch_time }
          expect(response.status).to eq(429)
          expect(response.headers['Retry-After']).to eq(@period.to_s)
          expect(Rack::Attack.cache.store.read(key)).to eq(5001)
          expect(request.env['rack.attack.throttle_data']['catalog/subnet']).to eq(data)
        end
      end # /catalog paths
    end # signed in user
  end

  after(:all) do
    Rack::Attack.clear_configuration
  end
end
