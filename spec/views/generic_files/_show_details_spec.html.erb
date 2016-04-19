require 'rails_helper'
require 'capybara/rspec'

describe 'generic_files/_show_details.html.erb' do
  let(:user) { create(:user) }
  let(:gf) { make_generic_file(user) }

  before do
    RSpec.configure do |config|
      config.include Devise::TestHelpers, :type => :view
    end
    assign(:generic_file, gf)
    expect(gf).to receive(:modified_date).and_return(
      DateTime.parse('Fri, 15 Apr 2016 11:13:03 -0000'))
    expect(gf).to receive(:date_uploaded).and_return(
      DateTime.parse('Fri, 14 Apr 2016 11:13:03 -0000'))
    sign_in(user)
    expect(view).to receive(:can?).and_return(true).twice
    render
  end

  it 'lists dates in proper formats' do
    expect(rendered).to have_text('April 15th, 2016 06:13')
    expect(rendered).to have_text('April 14th, 2016 06:13')
  end
end
