require 'rails_helper'
describe DublinCoreDatastream do
  let (:ds) do
    mock_obj = double(:mock_obj, pid: 'test:124', new_record?: true,
                      datastreams: {})
    ds = DublinCoreDatastream.new(mock_obj)
  end

  it "should have many contributors" do
    ds.abstract = ['tests']
    expect(ds.abstract).to eq(['tests'])
  end
end
