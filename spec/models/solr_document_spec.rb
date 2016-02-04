require 'rails_helper'

describe SolrDocument, type: :model do
  describe '#member_ids' do
    before do
      subject['hasCollectionMember_ssim'] = ['abc', 'bcd']
    end

    specify do
      expect(subject.member_ids).to match_array(['abc', 'bcd'])
    end
  end

  describe '#width' do
    before do
      subject[Solrizer.solr_name(:width, :type => :integer)] = [128]
    end

    specify do
      expect(subject.width).to eq(128)
    end
  end

  describe '#height' do
    before do
      subject[Solrizer.solr_name(:height, :type => :integer)] = [128]
    end

    specify do
      expect(subject.height).to eq(128)
    end
  end
end
