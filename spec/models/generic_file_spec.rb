require 'rails_helper'
RSpec.describe GenericFile do
  # Tested in collection_spec
  it { is_expected.to respond_to(:add_institutional_admin_permissions) }

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

    describe "grants_and_funding" do
      it "has it" do
        expect(subject.grants_and_funding).to eq([])
        subject.grants_and_funding = ['abc']
        subject.save(validate: false)
        expect(subject.reload.grants_and_funding).to eq(['abc'])
      end
    end

    describe "acknowledgments" do
      it "has it" do
        expect(subject.acknowledgments).to eq([])
        subject.acknowledgments = ['abc']
        subject.save(validate: false)
        expect(subject.reload.acknowledgments).to eq(['abc'])
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

    describe 'doi' do
      specify do
        expect(subject.doi).to eq([])
        subject.doi = ['10.6666/XXX']
        subject.save(validate: false)
        expect(subject.reload.doi).to eq(['10.6666/XXX'])
      end
    end

    describe 'ark' do
      specify do
        expect(subject.ark).to eq([])
        subject.ark = ['10.6666/XXX']
        subject.save(validate: false)
        expect(subject.reload.ark).to eq(['10.6666/XXX'])
      end
    end
  end

  context 'parent relationship' do
    let(:user) { FactoryGirl.create(:user) }
    let(:collection) {
      col = Collection.new(title: 'hello', tag: ['tag'])
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
      expect(subject.all_tags.sort).to eq(['a', 'b', 'c', 'd', 'e', 'f'])
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

  describe 'invalid characters' do
    it 'can save a file with UTF control characters in the metadata' do
      subject.title = ["Northwestern University, \vChicago"]
      subject.apply_depositor_metadata('nope')
      expect(subject.save!).to be_truthy
      expect(subject.title).to eq(["Northwestern University, Chicago"])
    end
  end

  describe '#check_doi_presence' do
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(GenericFile).to receive(
        :check_doi_presence).and_call_original
    end

    describe 'missing the id' do
      subject { GenericFile.new(title: ['abc'], creator: ['bcd']) }

      it 'does nothing' do
        subject.check_doi_presence
        expect(subject.doi).to be_blank
      end
    end

    describe 'missing the title' do
      subject { make_generic_file(user, creator: ['bcd']) }

      it 'does nothing' do
        subject.update_attributes(title: [])
        expect(subject.reload.title).to be_blank
        subject.check_doi_presence
        expect(subject.reload.doi).to be_blank
        expect(subject.ark).to be_blank
      end
    end

    describe 'missing the creator' do
      subject { make_generic_file(user) }

      it 'does nothing' do
        expect(subject.reload.creator).to be_blank
        subject.check_doi_presence
        expect(subject.reload.doi).to be_blank
        expect(subject.ark).to be_blank
      end
    end

    describe 'all required metadata present' do
      subject { make_generic_file(
        user, title: ['title'], creator: ['bcd'],
        date_uploaded: Date.new(2013), id: 'mahid',
        resource_type: ['Book']
      ) }
      let(:identifier) { double('ezid-id', id: 'doi', shadowedby: 'ark') }

      context 'no date_uploaded' do
        before { subject.update_attributes(date_uploaded: nil) }

        it 'sets doi and ark' do
          expect(Ezid::Identifier).to receive(:create).with(
            Ezid::Metadata.new({
              'datacite.creator' => 'bcd',
              'datacite.title' => 'title',
              'datacite.publisher' => 'Galter Health Science Library',
              'datacite.publicationyear' => Time.zone.today.year.to_s,
              #'datacite.resourcetype' => 'Book',
              '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
            })
          ).and_return(identifier)
          subject.check_doi_presence
          expect(subject.reload.doi).to eq(['doi'])
          expect(subject.ark).to eq(['ark'])
        end
      end

      context 'doi already present' do
        before { subject.update_attributes(doi: ['doi1']) }

        describe 'does not originate from Galter' do
          before do
            expect(Ezid::Identifier).to receive(:find).with(
              'doi1').and_raise(Ezid::Error)
            expect_any_instance_of(Ezid::Identifier).not_to receive(
              :update_metadata)
          end

          it 'does nothing' do
            subject.check_doi_presence
            expect(subject.reload.doi).to eq(['doi1'])
            expect(subject.ark).to eq([])
          end
        end

        describe 'originates from Galter' do
          before do
            expect(Ezid::Identifier).to receive(:find).with(
              'doi1').and_return(Ezid::Identifier.new)
            expect_any_instance_of(Ezid::Identifier).to receive(
              :update_metadata).with(
                Ezid::Metadata.new({
                  'datacite.creator' => 'bcd',
                  'datacite.title' => 'title',
                  'datacite.publisher' => 'Galter Health Science Library',
                  'datacite.publicationyear' => '2013',
                  #'datacite.resourcetype' => 'Book',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            subject.check_doi_presence
            expect(subject.reload.doi).to eq(['doi1'])
            expect(subject.ark).to eq([])
          end
        end

        context 'multiple dois one originating from Galter' do
          before do
            subject.update_attributes(doi: ['doi1', 'doi2', 'doi3'])
            expect(Ezid::Identifier).to receive(:find).with(
              'doi1').and_raise(Ezid::Error)
            expect(Ezid::Identifier).to receive(:find).with(
              'doi2').and_raise(Ezid::Error)
            expect(Ezid::Identifier).to receive(:find).with(
              'doi3').and_return(Ezid::Identifier.new)
            expect_any_instance_of(Ezid::Identifier).to receive(
              :update_metadata).with(
                Ezid::Metadata.new({
                  'datacite.creator' => 'bcd',
                  'datacite.title' => 'title',
                  'datacite.publisher' => 'Galter Health Science Library',
                  'datacite.publicationyear' => '2013',
                  #'datacite.resourcetype' => 'Book',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            subject.check_doi_presence
            expect(subject.reload.doi).to eq(['doi1', 'doi2', 'doi3'])
            expect(subject.ark).to eq([])
          end
        end
      end

      it 'sets doi and ark' do
        expect(Ezid::Identifier).to receive(:create).with(
          Ezid::Metadata.new({
            'datacite.creator' => 'bcd',
            'datacite.title' => 'title',
            'datacite.publisher' => 'Galter Health Science Library',
            'datacite.publicationyear' => '2013',
            #'datacite.resourcetype' => 'Book',
            '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
          })
        ).and_return(identifier)
        subject.check_doi_presence
        expect(subject.reload.doi).to eq(['doi'])
        expect(subject.ark).to eq(['ark'])
      end
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
