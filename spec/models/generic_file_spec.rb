require 'rails_helper'
RSpec.describe GenericFile do
  # Tested in collection_spec
  it { is_expected.to respond_to(:add_institutional_admin_permissions) }

  context 'export citations' do
    let(:gf_doi) { GenericFile.new(title: ['abc'],
                                   creator: ['Donald Duck'],
                                  doi: ['doi:11111/bbbb']) }
    let(:gf_no_doi) { GenericFile.new(title: ['meow'],
                                      creator: ['Cicero']) }

    it 'adds a doi to apa-formated citations' do
      expect(gf_doi.export_as_apa_citation).to include('doi:11111/bbbb')
      expect(gf_doi.export_as_apa_citation).to include('Duck')
      expect(gf_doi.export_as_apa_citation).to include('abc')
    end

    it 'adds a doi to mla-formated citations' do
      expect(gf_doi.export_as_mla_citation).to include('doi:11111/bbbb')
      expect(gf_doi.export_as_mla_citation).to include('Duck')
      expect(gf_doi.export_as_mla_citation).to include('Abc')
    end

    it 'adds a doi to chicago-formated citations' do
      expect(gf_doi.export_as_chicago_citation).to include('doi:11111/bbbb')
      expect(gf_doi.export_as_chicago_citation).to include('Duck')
      expect(gf_doi.export_as_chicago_citation).to include('Abc')
    end

    it 'does nothing for gf with no doi' do
      expect(gf_no_doi.export_as_apa_citation).to include('Cicero')
      expect(gf_no_doi.export_as_apa_citation).to include('meow')
    end
  end

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
        expect(subject.check_doi_presence).to eq('metadata')
        expect(subject.doi).to be_blank
      end
    end

    describe 'missing the title' do
      subject { make_generic_file(user, creator: ['bcd']) }

      it 'does nothing' do
        subject.update_attributes(title: [])
        expect(subject.reload.title).to be_blank
        expect(subject.check_doi_presence).to eq('metadata')
        expect(subject.reload.doi).to be_blank
        expect(subject.ark).to be_blank
      end
    end

    describe 'missing the creator' do
      subject { make_generic_file(user) }

      it 'does nothing' do
        expect(subject.reload.creator).to be_blank
        expect(subject.check_doi_presence).to eq('metadata')
        expect(subject.reload.doi).to be_blank
        expect(subject.ark).to be_blank
      end
    end

    describe 'all required metadata present' do
      let(:identifier) { double(
        'ezid-id', id: 'doi', shadowedby: 'ark', status: 'reserved'
      ) }

      subject { make_generic_file(
        user, title: ['title'], creator: ['bcd'],
        date_uploaded: Date.new(2013), id: 'mahid',
        resource_type: ['Book']
      ) }

      context 'generic file of type Page' do
        subject do
          page = Page.new(
            :title => ['title'], creator: ['bcd'],
            :date_uploaded => Date.new(2013), id: 'mahid',
            resource_type: ['Book'], page_number: '1'
          )
          page.apply_depositor_metadata('abc')
          page.save
          page
        end

        it 'does nothing' do
          expect(Ezid::Identifier).not_to receive(:create)
          expect(Ezid::Identifier).not_to receive(:find)
          expect(subject.check_doi_presence).to eq('page')
          expect(subject.reload.doi).to eq([])
          expect(subject.ark).to eq([])
        end

        describe 'with no page_number metadata' do
          before do
            subject.update_attributes(page_number: nil)
            expect(Ezid::Identifier).to receive(:create)
              .with(
                Ezid::Metadata.new({
                  'datacite.creator' => 'bcd',
                  'datacite.title' => 'title',
                  'datacite.publisher' => 'Galter Health Science Library',
                  'datacite.publicationyear' => '2013',
                  #'datacite.resourcetype' => 'Book',
                  '_status' => 'reserved',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              ).and_return(identifier)
          end

          it 'creates the doi and ark' do
            expect(subject.check_doi_presence).to eq('generated_reserved')
            expect(subject.reload.doi).to eq(['doi'])
            expect(subject.ark).to eq(['ark'])
          end
        end
      end

      context 'no date_uploaded' do
        let(:identifier) { double(
          'ezid-id', id: 'doi', shadowedby: 'ark', status: 'reserved'
        ) }

        before { subject.update_attributes(date_uploaded: nil) }

        it 'sets doi and ark' do
          expect(Ezid::Identifier).to receive(:create).with(
            Ezid::Metadata.new({
              'datacite.creator' => 'bcd',
              'datacite.title' => 'title',
              'datacite.publisher' => 'Galter Health Science Library',
              'datacite.publicationyear' => Time.zone.today.year.to_s,
              #'datacite.resourcetype' => 'Book',
              '_status' => 'reserved',
              '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
            })
          ).and_return(identifier)
          expect(subject.check_doi_presence).to eq('generated_reserved')
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
            expect(subject.check_doi_presence).to be_nil
            expect(subject.reload.doi).to eq(['doi1'])
            expect(subject.ark).to eq([])
          end
        end

        describe 'originates from Galter and visibility set to open' do
          let(:identifier) { double(
            'ezid-id', id: 'doi', shadowedby: 'ark', status: 'public'
          ) }

          before do
            subject.visibility = 'open'
            subject.save!
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
                  '_status' => 'public',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('updated')
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
                  '_status' => 'unavailable',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('updated_unavailable')
            expect(subject.reload.doi).to eq(['doi1'])
            expect(subject.ark).to eq([])
          end
        end

        describe 'multiple dois one originating from Galter' do
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
                  '_status' => 'unavailable',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('updated_unavailable')
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
            '_status' => 'reserved',
            '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
          })
        ).and_return(identifier)
        expect(subject.check_doi_presence).to eq('generated_reserved')
        expect(subject.reload.doi).to eq(['doi'])
        expect(subject.ark).to eq(['ark'])
      end

      context 'when visibility set to public' do
        let(:identifier) { double(
          'ezid-id', id: 'doi', shadowedby: 'ark', status: 'public'
        ) }

        before { subject.visibility = 'open'; subject.save! }

        it 'sets doi and ark' do
          expect(Ezid::Identifier).to receive(:create).with(
            Ezid::Metadata.new({
              'datacite.creator' => 'bcd',
              'datacite.title' => 'title',
              'datacite.publisher' => 'Galter Health Science Library',
              'datacite.publicationyear' => '2013',
              #'datacite.resourcetype' => 'Book',
              '_status' => 'public',
              '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
            })
          ).and_return(identifier)
          expect(subject.check_doi_presence).to eq('generated')
          expect(subject.reload.doi).to eq(['doi'])
          expect(subject.ark).to eq(['ark'])
        end
      end
    end
  end

  describe '#to_solr' do
    it 'generates rights_sim for Rights Statement' do
      subject.rights = ['http://creativecommons.org/publicdomain/zero/1.0/']
      expect(subject.to_solr['rights_sim']).to eq(['CC0 1.0 Universal'])
    end

    it 'generates tags_sim' do
      subject.mesh = ['a']
      subject.lcsh = ['b', 'c']
      expect(subject.to_solr['tags_sim'].sort).to eq(['a', 'b', 'c'])
    end

    it 'generates sortable label' do
      subject.title = ['asdf']
      expect(subject.to_solr['label_si']).to eq('asdf')
    end

  end
end
