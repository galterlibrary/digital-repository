require 'rails_helper'

RSpec.describe Riiif::Image do
  describe '#cache_key' do
    let(:gf) { make_generic_file(create(:user)) }
    let(:options) { { size: 'large' } }

    it 'includes solr timestamp in the cache key' do
      doc = ActiveFedora::SolrService.query("id:#{gf.id}", rows: 1).first
      str = options.merge(id: gf.id).merge(date: doc['timestamp']).to_s
      md5_str = Digest::MD5.hexdigest(str)
      expect(Riiif::Image.cache_key(gf.id, options)).to eq(md5_str)
    end
  end
end
