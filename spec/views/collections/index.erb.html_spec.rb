require 'rails_helper'
require 'capybara/rspec'


describe 'collections/index.html.erb' do
  let(:solr_docs) { [
    double('user_col1', depositor: 'someone', title: 'user_col1',
           id: 'user_col1'),
    double('user_col2', depositor: 'stranger', title: 'user_col2',
           id: 'user_col2'),
    double('galter_col1', depositor: 'galter-is', title: 'galter_col1',
           id: 'galter_col1'),
    double('galter_col2', depositor: 'galter-is', title: 'galter_col2',
           id: 'galter_col2'),
    double('ipham_col1', depositor: 'ipham-system', title: 'ipham_col1',
           id: 'ipham_col1'),
    double('ipham_col2', depositor: 'ipham-system', title: 'ipham_col2',
           id: 'ipham_col2')
  ] }

  context 'when not logged in' do
    before do
      assign(:document_list, solr_docs)
      render
    end

    it 'renders the collections groups' do
      expect(rendered).to have_content "Researchers' Collections"
      expect(rendered).to have_content 'Galter Health Sciences Library Collections'
      expect(rendered).to have_content 'Institute for Public Health and Medicine'
      expect(rendered).to have_link('user_col1')
      expect(rendered).to have_link('user_col2')
      expect(rendered).to have_link('galter_col1')
      expect(rendered).to have_link('galter_col2')
      expect(rendered).to have_link('ipham_col1')
      expect(rendered).to have_link('ipham_col2')
    end
  end
end
