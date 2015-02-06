require 'rails_helper'
RSpec.describe GenericFile do
  describe "terms_for_editing" do
    it "should return a list" do
      expect(subject.terms_for_editing).to eq([
        :resource_type, :title, :creator, :contributor, :description, :tag, :rights,
        :publisher, :date_created, :subject, :language, :identifier, :based_near,
        :related_url, :abstract, :bibliographic_citation])
    end
  end

  describe "terms_for_display" do
    it "should return a list" do
      expect(subject.terms_for_display).to eq([
        :resource_type, :title, :creator, :contributor, :description, :tag, :rights,
        :publisher, :date_created, :subject, :language, :identifier, :based_near,
        :related_url, :abstract, :bibliographic_citation])
    end
  end

  describe "abstract" do
    after do
      subject.delete
    end

    it "has it" do
      expect(subject.abstract).to eq([])
      subject.abstract = ['abc']
      subject.save(validate: false)
      expect(subject.reload.abstract).to be_truthy
    end
  end

  describe "bibliographic_citation" do
    after do
      subject.delete
    end

    it "has it" do
      expect(subject.bibliographic_citation).to eq([])
      subject.bibliographic_citation = ['abc']
      subject.save(validate: false)
      expect(subject.reload.bibliographic_citation).to be_truthy
    end
  end
end
