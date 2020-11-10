require 'rails_helper'
require "#{Rails.root}/lib/scripts/collection_items_list"

RSpec.describe 'lib/scripts/collection_items_list.rb' do
  let(:user) { FactoryGirl.create(:user) }
  let(:file) {
    make_generic_file(user, { id: 'bogus-file-id', title: ['Test File'] })
  }
  let(:parent_collection) {
    make_collection(user, { title: 'Test Collection'})
  }

  before do
    parent_collection.members << file
    parent_collection.save!
  end

  describe 'CollectionItemsList' do
    subject { CollectionItemsList.new(parent_collection.id) }

    it '#initialize' do
      expect(subject.collection.present?).to be_truthy
      expect(subject.collection_items_csv_file.present?).to be_truthy
    end

    it 'creates the file with sanitized title' do
      expect(
        File.basename(subject.collection_items_csv_file.path)
      ).to eq("Test_Collection_items_list.csv")
    end

    describe '#get_items_and_add_to_csv' do
      context 'collection with one file' do
        it 'adds items data to Test_Collection_items_list.csv' do
          subject.get_items_and_add_to_csv
          csv_result = File.readlines(
            "#{Rails.root}/lib/scripts/results/Test_Collection_items_list.csv"
          )
          expected_data = "#{parent_collection.title},"\
                          "#{file.title.first},"\
                          "https://digitalhub.northwestern.edu/files/#{file.id}\n"
          expect(csv_result[1]).to eq(expected_data)
        end
      end

      context 'collection with one file and one child collection with one file' do
        let(:child_file) {
          make_generic_file(user, { id: 'bogus-child-file-id', title: ['Test Child File'] })
        }
        let(:child_collection) {
          make_collection(user, {title: 'Test Child Collection'})
        }

        before do
          child_collection.members << child_file
          child_collection.save!
          parent_collection.members << child_collection
          parent_collection.save!
        end

        it 'adds items data to Test_Collection_items_list.csv' do
          subject.get_items_and_add_to_csv
          csv_result = File.readlines(
            "#{Rails.root}/lib/scripts/results/Test_Collection_items_list.csv"
          )
          expected_data_1 = "#{parent_collection.title},"\
                            "#{file.title.first},"\
                            "https://digitalhub.northwestern.edu/files/#{file.id}\n"
          expected_data_2 = "#{child_collection.title},"\
                            "#{child_file.title.first},"\
                            "https://digitalhub.northwestern.edu/files/#{child_file.id}\n"
          expect(csv_result[1]).to eq(expected_data_1)
          expect(csv_result[2]).to eq(expected_data_2)
        end
      end # with child collection
    end # #get_stats_and_add_to_csv
  end

  after do
    FileUtils.rm_f(Dir["#{Rails.root}/lib/scripts/results/Test_Collection_*.csv"])
  end
end
