require 'rails_helper'
require "#{Rails.root}/lib/batch/add_tags_for_collection_members"

RSpec.describe 'rails runner lib/batch/add_tags_for_collection_members.rb' do
  let(:user) { FactoryGirl.create(:user) }
  let(:item) {  make_generic_file(user, tag: ["Old Dogs"]) }
  let(:collection) { make_collection(user, tag: ["Old Dogs"]) }
  let(:nested_item) { make_generic_file(user, tag: ["Old Dogs"]) }
  let(:nested_collection) { make_collection(user, tag: ["Old Dogs"]) }

  before do
    collection.update_attributes(members: [item])
    nested_collection.update_attributes(members: [nested_item])
  end

  describe "#add_tags_for_collection_members" do
    context "for collection with no collections as members" do
      it "should add the new tag" do
        expect(item.tag).to eq(["Old Dogs"])
        expect(collection.tag).to eq(["Old Dogs"])

        add_tag_for_collection_members(collection_id: collection.id, tags: ["NUCATS"])

        item.reload
        collection.reload

        expect(item.tag).to eq(["Old Dogs", "NUCATS"])
        expect(collection.tag).to eq(["Old Dogs"])
      end
    end

    context "for collection a collection as member" do
      before do
        collection.update_attributes(:members => [item, nested_collection])
      end

      it "should add the new tag" do
        expect(item.tag).to eq(["Old Dogs"])
        expect(nested_item.tag).to eq(["Old Dogs"])
        expect(nested_collection.tag).to eq(["Old Dogs"])

        add_tag_for_collection_members(collection_id: collection.id, tags: ["NUCATS"])

        item.reload
        collection.reload
        nested_item.reload
        nested_collection.reload

        expect(item.tag).to eq(["Old Dogs", "NUCATS"])
        expect(collection.tag).to eq(["Old Dogs"])
        expect(nested_item.tag).to eq(["Old Dogs", "NUCATS"])
        expect(nested_collection.tag).to eq(["Old Dogs"])
      end
    end
  end
end
