require 'rails_helper'
require 'capybara/rspec'

describe 'generic_files/upload/_form.html.erb' do
  let(:user) { create(:user) }
  let(:jaja) { create(:user, username: 'jaja', display_name: 'Ale Jaja') }
  let(:tata) { create(:user, username: 'tata', display_name: 'Tata Mama') }
  let(:gf) { make_generic_file(user) }

  before do
    RSpec.configure do |config|
      config.include Devise::TestHelpers, :type => :view
    end
    ProxyDepositRights.create(grantor_id: jaja.id, grantee_id: user.id)
    ProxyDepositRights.create(grantor_id: tata.id, grantee_id: user.id)
    assign(:generic_file, gf)
    sign_in user
    render
  end

  it 'lists users by name' do
    expect(rendered).to have_select(
      'On Behalf of', options: ['Yourself', 'Ale Jaja', 'Tata Mama'])
  end
end
