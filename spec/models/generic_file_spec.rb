require 'rails_helper'
RSpec.describe GenericFile do
  after do
    subject.delete
  end

  describe "abstract" do
    it "has it" do
      expect(subject.abstract).to eq([])
      subject.abstract = ['abc']
      subject.save(validate: false)
      expect(subject.reload.abstract).to be_truthy
    end
  end

  describe "bibliographic_citation" do
    it "has it" do
      expect(subject.bibliographic_citation).to eq([])
      subject.bibliographic_citation = ['abc']
      subject.save(validate: false)
      expect(subject.reload.bibliographic_citation).to be_truthy
    end
  end

  describe "subject_name" do
    it "has it" do
      expect(subject.subject_name).to eq([])
      subject.subject_name = ['abc']
      subject.save(validate: false)
      expect(subject.reload.subject_name).to be_truthy
    end
  end

  describe "subject_geographic" do
    it "has it" do
      expect(subject.subject_geographic).to eq([])
      subject.subject_geographic = ['abc']
      subject.save(validate: false)
      expect(subject.reload.subject_geographic).to be_truthy
    end
  end

  describe "lcsh" do
    it "has it" do
      expect(subject.lcsh).to eq([])
      subject.lcsh = ['abc']
      subject.save(validate: false)
      expect(subject.reload.lcsh).to be_truthy
    end
  end

  describe "mesh" do
    it "has it" do
      expect(subject.mesh).to eq([])
      subject.mesh = ['abc']
      subject.save(validate: false)
      expect(subject.reload.mesh).to be_truthy
    end
  end

  describe "digital_origin" do
    it "has it" do
      expect(subject.digital_origin).to eq([])
      subject.digital_origin = ['abc']
      subject.save(validate: false)
      expect(subject.reload.digital_origin).to be_truthy
    end
  end
end
