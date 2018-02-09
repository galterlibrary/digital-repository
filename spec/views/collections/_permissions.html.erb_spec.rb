require 'rails_helper'
require 'capybara/rspec'

describe 'collections/_permissions.html.erb' do
  before do
    RSpec.configure do |config|
      config.include Devise::TestHelpers, :type => :view
    end
  end
  
  context 'user collection' do
    let(:user) { create(:user) }
    let(:user_col) {
      make_collection(user, { title: 'Warden Norton' })
    }
    
    before do
      assign(:collection, user_col)
      sign_in user
      render
    end
    
    it 'does not hide user permissions field' do
      expect(rendered).to have_css('div#new-user')
      expect(rendered).to_not have_text("This is an Institutional Collection")
    end
  end
  
  context 'institutional collection' do
    let(:admin) { create(:admin_user) }
    let(:instl_col) {
      make_collection(admin, { title: 'Shawshank Redemption' })
    }
    
    before do
      instl_col.convert_to_institutional('institutional-shawshank')
      assign(:collection, instl_col)
      sign_in admin
      render
    end
    
    it 'hides user permissions field' do
      expect(rendered).to_not have_css('div#new-user')
      expect(rendered).to have_text("This is an Institutional Collection")
    end
  end
end
