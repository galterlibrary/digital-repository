require 'rails_helper'

RSpec.describe "/_footer.html.erb", :type => :view do
  before do
    render
  end
  
  describe '#nuBrand' do
    describe 'copyright year' do
      let(:this_yr) { Time.now }
      let(:next_yr) { Time.now + 1.year }
      
      it 'shows this year' do
        expect(rendered).to have_text("© #{this_yr.year} Northwestern University")
        expect(rendered).to_not have_text("© #{next_yr.year} Northwestern University")
      end
      
      it 'shows a year later' do
        Timecop.freeze(next_yr) do
          render
          expect(rendered).to have_text("© #{next_yr.year} Northwestern University")
        end
      end
    end
  end
  
  describe '#footerLinks' do
    it 'has the coar logo' do
      expect(rendered).to have_css("a[href*='www.coar-repositories.org']")
      expect(rendered).to have_css("img[src*=coar-logo]")
    end
  end
end
