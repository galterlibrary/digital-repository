require 'rails_helper'
require 'capybara/rspec'


describe 'collections/index.html.erb' do
  let(:solr_docs) { [
    {
      'depositor_ssim' => ['someone'],
      'title_tesim' => ['user_col1'],
      'id' => 'user_col1'
    }, {
      'depositor_ssim' => ['stranger'],
      'title_tesim' => ['user_col2'],
      'id' => 'user_col2'
    }, {
      'depositor_ssim' => ['institutional-galter-root'],
      'title_tesim' => ['ABC'],
      'id' => 'galter_col1',
      'hasCollectionMember_ssim' => ['galter_col2', 'galter_col3']
    }, {
      'depositor_ssim' => ['institutional-glater'],
      'title_tesim' => ['blah blah'],
      'id' => 'galter_col2'
    }, {
      'depositor_ssim' => ['institutional-glater'],
      'title_tesim' => ['moo moo'],
      'id' => 'galter_col3',
      'hasCollectionMember_ssim' => ['galter_col4']
    }, {
      'depositor_ssim' => ['institutional-glater'],
      'title_tesim' => ['not there'],
      'id' => 'galter_col4'
    }, {
      'depositor_ssim' => ['institutional-ipham-root'],
      'title_tesim' => ['Institute for Public Health and Medicine'],
      'id' => 'ipham_col1',
      'hasCollectionMember_ssim' => ['ipham_col2']
    }, {
      'depositor_ssim' => ['institutional-ipham'],
      'title_tesim' => ['ipham_col2'],
      'id' => 'ipham_col2'
    }
  ] }

  context 'when not logged in' do
    before do
      assign(:document_list, solr_docs)
      render
    end

    it 'will not render institutional collections who are not root children' do
      expect(rendered).not_to have_link('not there')
    end

    it 'renders the collections groups' do
      expect(rendered).to have_content "Researchers' Collections"
      expect(rendered).to have_link(
        'Institute for Public Health and Medicine',
        href: '/collections/ipham_col1')
      expect(rendered).to have_link('ABC', href: '/collections/galter_col1')
      expect(rendered).to have_link('blah blah', href: '/collections/galter_col2')
      expect(rendered).to have_link('moo moo', href: '/collections/galter_col3')
      expect(rendered).to have_link('ipham_col2', href: '/collections/ipham_col2')
      expect(rendered).to have_link('user_col1', href: '/collections/user_col1')
      expect(rendered).to have_link('user_col2', href: '/collections/user_col2')
    end
  end
end
