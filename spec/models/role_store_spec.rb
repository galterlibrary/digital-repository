require 'rails_helper'

RSpec.describe RoleStore do
  let(:role_store) { RoleStore.new }

  describe "#build_role_store_data" do
    it "does not error" do
      expect{ role_store.build_role_store_data }.not_to raise_error
    end
  end
end
