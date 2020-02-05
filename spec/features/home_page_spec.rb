require 'rails_helper'

feature "HomePage", :type => :feature do
  subject { page }
  let(:user) { FactoryGirl.create(:user) }
  
  describe 'masthead' do
    it 'has branding and links' do
      visit '/'

      within('#masthead') do
        expect(page).to have_link(nil, href: "https://www.feinberg.northwestern.edu/")
        expect(page).to have_selector(:css, "div a.institutionLogo")
        expect(page).to have_link('DigitalHub', href: '/')
      end
    end
  end

  describe 'tag cloud' do
    let!(:cancer) {
      make_generic_file(user, {
        mesh: ['cancer'], lcsh: ['neoplasm'], visibility: 'open', title: ['ABC']
      })
    }
    let!(:neuroblastoma) {
      make_generic_file(user, {
        mesh: ['something'], subject_name: ['neoplasm'], visibility: 'open',
        title: ['BCD']
      })
    }

    before { visit '/' }

    it 'lists all the subjects in the cloud', js: true do
      expect(page).to have_link('cancer')
      expect(page).to have_link('neoplasm')
      expect(page).to have_link('something')
    end

    it 'links the subjects in the cloud to the catalog', js: true do
      click_link 'neoplasm'
      expect(page).to have_text('neoplasm')
      expect(find('span.selected.facet-count').text).to eq('2')
      expect(page).to have_link('cancer')
      expect(page).to have_link('something')
      expect(page).to have_text('ABC')
      expect(page).to have_text('BCD')
    end
  end

  describe 'navigation bar' do
    before { visit '/' }
    it { is_expected.to have_link('News') }

    it 'links to the news page' do
      within('.navbar-nav') do
        click_link 'News'
        expect(current_path).to eq('/news')
      end
    end
  end

  describe 'Featured Works and recent' do
      let(:gf) { make_generic_file(user, {
        tag: ['cancer'], visibility: 'open', title: ['ABC']
      }) }

      before do
        gf.label = File.basename('test1.png')
        gf.date_uploaded = DateTime.now
        gf.add_file(
          File.open(Rails.root.join('spec/fixtures/test1.png')),
          original_name: 'test1.png',
          path: 'content',
          mime_type: 'image/png'
        )
        gf.save!
        gf.update_index
        FeaturedWork.create(generic_file_id: gf.id)
      end

      specify do
        visit '/'
        within('#featured_container') do
          expect(page).to have_text('ABC')
          expect(page).to have_text('cancer')
          expect(page).to have_text(user.user_key)
          expect(page).to have_text('no resource specified')
          expect(page).not_to have_text(gf.label)
        end

        within('#recently_uploaded') do
          expect(page).to have_text('ABC')
          expect(page).to have_text('cancer')
          expect(page).not_to have_text(gf.label)
        end
      end
  end

  describe 'Featured Researcher' do
    let(:admin_user) { FactoryGirl.create(:admin_user) }
    let!(:researcher1) {
      FactoryGirl.create(
        :content_block, name: 'featured_researcher', value: 'Tesla')
    }
    let!(:researcher2) {
      FactoryGirl.create(
        :content_block, name: 'featured_researcher',
        :value => 'Edison', created_at: 7.days.ago)
    }

    before do
      visit '/'
    end

    it { pending 'Featured Reasercher removed'; is_expected.to have_text('Tesla') }
    it { skip 'Featured Reasercher removed'; is_expected.not_to have_text('Edison') }

    context 'admin functions' do
      describe 'anonymous user' do
        before { pending 'Featured Reasercher removed'; click_link 'View other featured researchers' }

        it { is_expected.not_to have_link('Delete') }
        it { is_expected.not_to have_link('Re-feature') }
      end

      describe 'logged in user' do
        before do
          login_as(user)
          pending 'Featured Reasercher removed'
          click_link 'View other featured researchers'
        end

        it { is_expected.to have_link(user.name) }
        it { is_expected.not_to have_link('Delete') }
        it { is_expected.not_to have_link('Re-feature') }
      end

      describe 'logged in admin user' do
        before do
          login_as(admin_user)
          pending 'Featured Reasercher removed'
          click_link 'View other featured researchers'
        end

        it { is_expected.to have_link('Delete') }
        it { is_expected.to have_link('Re-feature') }

        it 'can re-feature researcher' do
          within("#featuredResearcher#{researcher2.id}") do
            expect {
              click_link 'Re-feature'
            }.not_to change { ContentBlock.count }
          end
          expect(current_path).to eq('/')
          expect(page).to have_text('Edison')
          expect(page).not_to have_text('Tesla')
        end

        it 'can delete a researcher' do
          within("#featuredResearcher#{researcher1.id}") do
            expect {
              click_link 'Delete'
            }.to change { ContentBlock.count }.by(-1)
          end
          expect(current_path).to eq('/')
          expect(page).to have_text('Edison')
          expect(page).not_to have_text('Tesla')
        end
      end
    end
  end
end
