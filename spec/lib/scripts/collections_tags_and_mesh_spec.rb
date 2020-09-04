require 'rails_helper'
require "#{Rails.root}/lib/scripts/collections_tags_and_mesh"

RSpec.describe 'lib/scripts/collections_tags_and_mesh.rb' do
  let(:user) { FactoryGirl.create(:user) }

  subject { CollectionsTagsAndMeshList.new }

  describe 'CollectionsTagsAndMeshList' do
    before do
      make_collection(user, id: "123", title: "Tags and Mesh List",
                      tag: ["CERN"], mesh: ["invenioRDM"])
    end

    describe '#populate_collections_tags_and_mesh_info' do
      it 'adds collections mesh and tags info to collections_tags_and_mesh_list.csv' do
        subject.populate_collections_tags_and_mesh_info
        collections_tags_and_mesh_list_result = File.readlines(
          "#{Rails.root}/lib/scripts/results/collections_tags_and_mesh_list.csv"
        )
        expected_data = "Tags and Mesh List,"\
                        "https://digitalhub.northwestern.edu/collections/123,"\
                        "CERN,invenioRDM\n"

        expect(collections_tags_and_mesh_list_result[1]).to eq(expected_data)
      end
    end # #populate_user_info
  end

  after do
    FileUtils.rm_f(Dir["#{Rails.root}/lib/scripts/results/collections_tags_and_mesh_list.csv"])
  end
end
