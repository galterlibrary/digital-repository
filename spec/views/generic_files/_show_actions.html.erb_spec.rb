require 'rails_helper'

describe 'generic_files/_show_actions.html.erb' do
  let(:user) { create(:user) }
  let(:gf) { make_generic_file(user, doi: ['test']) }
  
  before do
    RSpec.configure do |config|
      config.include Devise::TestHelpers, :type => :view
    end
    assign(:generic_file, gf)
    sign_in(user)
    expect(view).to receive(:can?).and_return(true).twice
    render
  end
  
  context 'altmetric' do
    context 'with score of 0' do
      it 'does not have link' do
        expect(rendered).to_not have_selector('span.altmetric-embed > a')
      end
    end
    
    context 'with score > 0' do
      it 'has a link to altmetric' do
        skip "Check back after altmetric starts tracking and try with a gf on staging"
        expect(rendered).to have_selector('span.altmetric-embed > a')
      end
    end
  end
end
