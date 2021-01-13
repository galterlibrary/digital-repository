require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user, username: "usr1234") }
  let(:assistant) { FactoryGirl.create(:user, username: "ast9876") }

  before do
    ProxyDepositRights.create(grantor_id: assistant.id, grantee_id: user.id)
  end

  let(:generic_file) {
    make_generic_file(
      user,
      doi: ["doi:123/ABC"],
      resource_type: ["Account Books"],
      proxy_depositor: assistant.username,
      on_behalf_of: user.username
    )
  }
  let(:json) do
    {
      "pids": {
        "doi": {
          "identifier": "#{generic_file.doi.shift}",
          "provider":"datacite",
          "client":"digitalhub"
        }
      },
      "metadata": {
        "resource_type": {
          "type": "Books",
          "subtype": "Account Book"
        }
      },
      "provenance": {
        "created_by": {
          "user": assistant.username
        },
        "on_behalf_of": {
          "user": user.username
        }
      }
    }.to_json
  end

  describe "#to_json" do
    subject { described_class.new(generic_file).to_json }

    it { is_expected.to eq json }
  end
end
