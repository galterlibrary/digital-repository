require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user) }
  let(:generic_file) { make_generic_file(user, doi: ["doi:123/ABC"]) }
  let(:json) { "{\"pids\":{\"doi\":{\"identifier\":\"#{generic_file.doi.shift}\",\"provider\":\"datacite\",\"client\":\"digitalhub\"}},\"provenance\":\"#{user.username}\"}" }

  describe "#to_json" do
    subject { described_class.new(generic_file).to_json }

    it { is_expected.to eq json }
  end
end
