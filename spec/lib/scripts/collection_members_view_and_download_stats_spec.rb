require 'rails_helper'
require "#{Rails.root}/lib/scripts/collection_members_view_and_download_stats"

RSpec.describe 'lib/scripts/collection_members_views_and_download_stats.rb', :vcr do
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

  describe 'CollectionMembersViewAndDownloadStats' do
    subject { CollectionMembersViewAndDownloadStats.new(parent_collection.id) }

    it '#initialize' do
      expect(subject.collection).to be_truthy
      expect(subject.pageviews_csv_file).to be_truthy
      expect(subject.downloads_csv_file).to be_truthy
    end

    it 'has constant STAT_TYPES' do
      expect(subject.class::STAT_TYPES).to eq(["downloads", "pageviews"])
    end

    it 'creates the file with sanitized title for each stat type' do
      expect(
        File.basename(subject.pageviews_csv_file.path)
      ).to eq("Test_Collection_pageviews_stats.csv")
      expect(
        File.basename(subject.downloads_csv_file.path)
      ).to eq("Test_Collection_downloads_stats.csv")
    end

    describe '#get_stats_and_add_to_csv' do
      context 'collection with one file' do
        before do
          mock_file_usage = double("File Usage")
          allow(FileUsage).to receive(:new).with(file.id).and_return(mock_file_usage)
          allow(mock_file_usage).to receive(:pageviews).and_return([[1570406400000, 2]])
          allow(mock_file_usage).to receive(:downloads).and_return([[1570406400000, 1]])
        end

        it 'adds pageviews data to Test_Collection_pageviews_stats.csv' do
          subject.get_stats_and_add_to_csv(type: 'pageviews')
          pageviews_csv_result = File.readlines(
            "#{Rails.root}/lib/scripts/results/Test_Collection_pageviews_stats.csv"
          )
          expected_data = "#{parent_collection.title},"\
                          "#{file.title.first},"\
                          "https://digitalhub.northwestern.edu/files/#{file.id},"\
                          "10-2019,"\
                          "2\n"
          expect(pageviews_csv_result[1]).to eq(expected_data)
        end

        it 'adds downloads data to Test_Collection_downloads_stats.csv' do
          subject.get_stats_and_add_to_csv(type: 'downloads')
          downloads_csv_result = File.readlines(
            "#{Rails.root}/lib/scripts/results/Test_Collection_downloads_stats.csv"
          )
          expected_data = "#{parent_collection.title},"\
                          "#{file.title.first},"\
                          "https://digitalhub.northwestern.edu/files/#{file.id},"\
                          "10-2019,"\
                          "1\n"
          expect(downloads_csv_result[1]).to eq(expected_data)
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

          mock_file_usage = double("File Usage")
          allow(FileUsage).to receive(:new).with(file.id).and_return(mock_file_usage)
          allow(mock_file_usage).to receive(:pageviews).and_return([[1570406400000, 2]])
          allow(mock_file_usage).to receive(:downloads).and_return([[1570406400000, 1]])

          mock_child_file_usage = double("Child File Usage")
          allow(FileUsage).to receive(:new).with(child_file.id).and_return(mock_child_file_usage)
          allow(mock_child_file_usage).to receive(:pageviews).and_return([[1573084800000, 99]])
          allow(mock_child_file_usage).to receive(:downloads).and_return([[1573084800000, 49]])
        end

        it 'adds pageviews data to Test_Collection_pageviews_stats.csv' do
          subject.get_stats_and_add_to_csv(type: 'pageviews')
          pageviews_csv_result = File.readlines(
            "#{Rails.root}/lib/scripts/results/Test_Collection_pageviews_stats.csv"
          )
          expected_data_1 = "#{parent_collection.title},"\
                            "#{file.title.first},"\
                            "https://digitalhub.northwestern.edu/files/#{file.id},"\
                            "10-2019,"\
                            "2\n"
          expected_data_2 = "#{child_collection.title},"\
                            "#{child_file.title.first},"\
                            "https://digitalhub.northwestern.edu/files/#{child_file.id},"\
                            "11-2019,"\
                            "99\n"
          expect(pageviews_csv_result[1]).to eq(expected_data_1)
          expect(pageviews_csv_result[2]).to eq(expected_data_2)
        end

        it 'adds downloads data to Test_Collection_downloads_stats.csv' do
          subject.get_stats_and_add_to_csv(type: 'downloads')
          downloads_csv_result = File.readlines(
            "#{Rails.root}/lib/scripts/results/Test_Collection_downloads_stats.csv"
          )
          expected_data_1 = "#{parent_collection.title},"\
                            "#{file.title.first},"\
                            "https://digitalhub.northwestern.edu/files/#{file.id},"\
                            "10-2019,"\
                            "1\n"
          expected_data_2 = "#{child_collection.title},"\
                            "#{child_file.title.first},"\
                            "https://digitalhub.northwestern.edu/files/#{child_file.id},"\
                            "11-2019,"\
                            "49\n"
          expect(downloads_csv_result[1]).to eq(expected_data_1)
          expect(downloads_csv_result[2]).to eq(expected_data_2)
        end
      end # with child collection
    end # #get_stats_and_add_to_csv
  end

  after do
    FileUtils.rm_rf(Dir["#{Rails.root}/lib/scripts/results/Test_Collection_*.csv"])
  end
end
