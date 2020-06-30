require 'rails_helper'
require "#{Rails.root}/lib/batch/add_publisher_for_collection_members"

RSpec.describe 'rails runner lib/batch/add_publisher_for_collection_members.rb' do
  let(:user) { FactoryGirl.create(:user) }
  let(:item) {  make_generic_file(user) }
  let(:collection) { make_collection(user) }
  let(:nested_item) { make_generic_file(user) }
  let(:nested_collection) { make_collection(user) }

  before do
    item.update_attributes(publisher: [])
    collection.update_attributes(members: [item])
    nested_item.update_attributes(publisher: [])
    nested_collection.update_attributes(publisher: [], members: [nested_item])
  end

  describe "#add_publisher_for_collection_members" do
    context "for collection with no collections as members" do
      it "should add the DigitalHub publisher" do
        expect(item.publisher).to eq([])

        add_publisher_for_collection_members(collection_id: collection.id)

        item.reload

        expect(item.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
      end
    end

    context "for collection a collection as member" do
      before do
        collection.update_attributes(:members => [item, nested_collection])
      end

      it "should add the DigitalHub publisher" do
        expect(item.publisher).to eq([])
        expect(nested_item.publisher).to eq([])
        expect(nested_collection.publisher).to eq([])

        add_publisher_for_collection_members(collection_id: collection.id)

        item.reload
        nested_item.reload
        nested_collection.reload

        expect(item.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
        expect(nested_item.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
        expect(nested_collection.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
      end
    end
  end
end
