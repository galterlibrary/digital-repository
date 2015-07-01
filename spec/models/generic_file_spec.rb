require 'rails_helper'
RSpec.describe GenericFile do
  context 'custom metadata' do
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

    describe "page_number" do
      it "has it" do
        expect(subject.page_number).to be_nil
        subject.page_number = '22'
        subject.save(validate: false)
        expect(subject.reload.page_number).to eq('22')
      end
    end

    describe "page_number_actual" do
      it "has it" do
        expect(subject.page_number_actual).to be_nil
        subject.page_number_actual = 22
        subject.save(validate: false)
        expect(subject.reload.page_number_actual).to eq(22)
      end
    end

    describe 'setting page_number_actual via page_number' do
      it "sets page_number_actual when page_number is set" do
        subject.page_number = '22'
        subject.save(validate: false)
        expect(subject.reload.page_number_actual).to eq(22)
      end

      it "sets page_number_actual when page_number is changed" do
        subject.page_number = '22'
        subject.save(validate: false)
        subject.page_number = '33'
        subject.save(validate: false)
        expect(subject.reload.page_number_actual).to eq(33)
      end

      it "prefers page_number_actual over page_number" do
        subject.page_number = '22'
        subject.page_number_actual = '33'
        subject.save(validate: false)
        expect(subject.reload.page_number_actual).to eq(33)
      end

      it "leaves page_number_actual blank if page_number is not an integer" do
        subject.page_number = '22a'
        subject.save(validate: false)
        expect(subject.reload.page_number_actual).to eq(nil)
      end
    end
  end

  context 'parent relationship' do
    let(:user) { FactoryGirl.create(:user) }
    let(:collection) {
      col = Collection.new(title: 'hello')
      col.apply_depositor_metadata(user.user_key)
      col.save!
      col
    }
    let(:generic_file) {
      gf = GenericFile.new(title: ['hello'])
      gf.apply_depositor_metadata(user.user_key)
      gf.save!
      gf
    }

    it { is_expected.to respond_to(:parent) }

    it 'can store a parent object of Collection type' do
      expect(subject.parent).to eq(nil)
      subject.parent = collection
      subject.save(validate: false)
      expect(subject.reload.parent).to eq(collection)
    end

    it 'will not store a parent object of any other type' do
      expect(subject.parent).to eq(nil)
      expect { subject.parent = generic_file }.to raise_error(
        ActiveFedora::AssociationTypeMismatch)
      expect(subject.parent).to be(nil)
    end
  end

  describe '#all_tags' do
    it 'combines all subjects into one array' do
      subject.mesh = ['a']
      subject.lcsh = ['b', 'c']
      subject.subject_geographic = ['d', 'e']
      subject.subject_name = ['f']
      subject.subject = ['g']
      expect(subject.all_tags.sort).to eq(['a', 'b', 'c', 'd', 'e', 'f', 'g'])
    end

    it 'combines all subjects into one array when some are blank' do
      subject.mesh = ['a']
      subject.lcsh = ['b', 'c']
      subject.subject_geographic = []
      subject.subject_name = ['f']
      subject.subject = []
      expect(subject.all_tags.sort).to eq(['a', 'b', 'c', 'f'])
    end
  end

  describe '#to_solr' do
    it 'generates tags_sim' do
      subject.mesh = ['a']
      subject.lcsh = ['b', 'c']
      expect(subject.to_solr['tags_sim'].sort).to eq(['a', 'b', 'c'])
    end
  end
end
