require 'rails_helper'

describe Sufia::GenericFile::Actor do
  include ActionDispatch::TestProcess # for fixture_file_upload

  let(:user) { FactoryGirl.create(:user) }
  let(:generic_file) { GenericFile.new }
  let(:actor) { described_class.new(generic_file, user) }

  describe "#create_metadata" do
    context 'generic file creator' do
      let(:user) { FactoryGirl.create(
        :user, display_name: 'Display Name', formal_name: 'Name, Formal' ) }
      before do
        actor.create_metadata(nil)
      end
      subject { generic_file.creator }

      it { is_expected.to eql(['Name, Formal']) }
    end
  end
end
