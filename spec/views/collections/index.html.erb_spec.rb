require 'rails_helper'
require 'capybara/rspec'


describe 'collections/index.html.erb' do
  let(:solr_docs) { [
    double('user_col1', depositor: 'someone', title: 'user_col1',
           id: 'user_col1'),
    double('user_col2', depositor: 'stranger', title: 'user_col2',
           id: 'user_col2'),
    double('galter_col1', depositor: 'institutional-galter-root', title: 'ABC',
           id: 'galter_col1', member_ids: ['galter_col2', 'galter_col3']),
    double('galter_col2', depositor: 'institutional-glater', title: 'blah blah',
           id: 'galter_col2'),
    double('galter_col3', depositor: 'institutional-glater', title: 'moo moo',
           id: 'galter_col3', member_ids: ['galter_col4']),
    double('galter_col4', depositor: 'institutional-glater', title: 'not there',
           id: 'galter_col4'),
    double('ipham_col1', depositor: 'institutional-ipham-root',
                         title: 'Institute for Public Health and Medicine',
                         id: 'ipham_col1', member_ids: ['ipham_col2']),
    double('ipham_col2', depositor: 'institutional-ipham', title: 'ipham_col2',
           id: 'ipham_col2')
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
