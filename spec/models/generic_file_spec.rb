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
      expect(gf_doi.export_as_apa_citation).to include(
        "href='https://doi.org/11111/bbbb'")
      expect(gf_doi.export_as_apa_citation).to include('Duck')
      expect(gf_doi.export_as_apa_citation).to include('abc')
    end

    it 'adds a doi to mla-formated citations' do
      expect(gf_doi.export_as_mla_citation).to include('doi:11111/bbbb')
      expect(gf_doi.export_as_apa_citation).to include(
        "href='https://doi.org/11111/bbbb'")
      expect(gf_doi.export_as_mla_citation).to include('Duck')
      expect(gf_doi.export_as_mla_citation).to include('Abc')
    end

    it 'adds a doi to chicago-formated citations' do
      expect(gf_doi.export_as_chicago_citation).to include('doi:11111/bbbb')
      expect(gf_doi.export_as_apa_citation).to include(
        "href='https://doi.org/11111/bbbb'")
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

    describe "private_note" do
      it "has it" do
        expect(subject.private_note).to be_empty
        subject.private_note = ['abc bcd']
        subject.save(validate: false)
        expect(subject.reload.private_note).to eq(['abc bcd'])
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
      end
    end

    describe 'missing the creator' do
      subject { make_generic_file(user) }

      it 'does nothing' do
        expect(subject.reload.creator).to be_blank
        expect(subject.check_doi_presence).to eq('metadata')
        expect(subject.reload.doi).to be_blank
      end
    end

    describe 'all required metadata present' do
      let(:identifier) { double(
        'ezid-id', id: 'doi', status: 'reserved'
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
          expect(Ezid::Identifier).not_to receive(:mint)
          expect(Ezid::Identifier).not_to receive(:find)
          expect(subject.check_doi_presence).to eq('page')
          expect(subject.reload.doi).to eq([])
        end

        describe 'with no page_number metadata' do
          before do
            subject.update_attributes(page_number: nil)

            expect(Ezid::Identifier).to receive(:mint)
              .with(
                Ezid::Metadata.new({
                  'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\"></identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>2013</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
                  '_status' => 'reserved',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              ).and_return(identifier)
          end

          it 'creates the doi' do
            expect(subject.check_doi_presence).to eq('generated_reserved')
            expect(subject.reload.doi).to eq(['doi'])
          end
        end
      end

      context 'no date_uploaded' do
        let(:identifier) { double(
          'ezid-id', id: 'doi', status: 'reserved'
        ) }

        before { subject.update_attributes(date_uploaded: nil) }

        it 'sets doi' do
          expect(Ezid::Identifier).to receive(:mint).with(
            Ezid::Metadata.new({
              'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\"></identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>#{Time.zone.today.year.to_s}</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
              '_status' => 'reserved',
              '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
            })
          ).and_return(identifier)
          expect(subject.check_doi_presence).to eq('generated_reserved')
          expect(subject.reload.doi).to eq(['doi'])
        end
      end

      context 'doi already present' do
        before { subject.update_attributes(doi: ['10.abc/FK2']) }

        describe 'does not originate from Galter' do
          before do
            expect(Ezid::Identifier).to receive(:find).with(
              '10.abc/FK2').and_raise(Ezid::Error)
            expect_any_instance_of(Ezid::Identifier).not_to receive(
              :update_metadata)
          end

          it 'does nothing' do
            expect(subject.check_doi_presence).to be_nil
            expect(subject.reload.doi).to eq(['10.abc/FK2'])
          end
        end

        describe 'schema validation errors' do
          let(:identifier) { double(
            'ezid-id', id: 'abc/FK2', status: 'public'
          ) }

          before do
            subject.update_attributes(doi: ['abc/FK2'])
            expect(Ezid::Identifier).to receive(:find).with(
              'abc/FK2').and_return(Ezid::Identifier.new)
            expect_any_instance_of(Ezid::Identifier).not_to receive(:save)
          end

          it 'throws an error' do
            expect { subject.check_doi_presence }.to raise_error(
              EzidGenerator::DataciteSchemaError
            )
            expect(subject.reload.doi).to eq(['abc/FK2'])
          end
        end

        describe 'originates from Galter and visibility set to open' do
          let(:identifier) { double(
            'ezid-id', id: '10.abc/FK2', status: 'public'
          ) }

          before do
            subject.visibility = 'open'
            subject.save!
            expect(Ezid::Identifier).to receive(:find).with(
              '10.abc/FK2').and_return(Ezid::Identifier.new)
            expect_any_instance_of(Ezid::Identifier).to receive(
              :update_metadata).with(
                Ezid::Metadata.new({
                  'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\">10.abc/FK2</identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>2013</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
                  '_status' => 'public',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('updated')
            expect(subject.reload.doi).to eq(['10.abc/FK2'])
          end
        end

        describe 'originates from Galter' do
          before do
            expect(Ezid::Identifier).to receive(:find).with(
              '10.abc/FK2').and_return(Ezid::Identifier.new)
            expect_any_instance_of(Ezid::Identifier).to receive(
              :update_metadata).with(
                Ezid::Metadata.new({
                  'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\">10.abc/FK2</identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>2013</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
                  '_status' => 'unavailable',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('updated_unavailable')
            expect(subject.reload.doi).to eq(['10.abc/FK2'])
          end
        end

        describe 'multiple dois one originating from Galter' do
          before do
            expect(Ezid::Identifier).to receive(:find).with(
              '10.doi1/AA1').and_raise(Ezid::Error)
            expect(Ezid::Identifier).to receive(:find).with(
              '10.doi/BB3').and_raise(Ezid::Error)
            expect(Ezid::Identifier).to receive(:find).with(
              '10.abc/FK2').and_return(Ezid::Identifier.new)
            expect_any_instance_of(Ezid::Identifier).to receive(
              :update_metadata
            ).with(
                Ezid::Metadata.new({
                  'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\">10.abc/FK2</identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>2013</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
                  '_status' => 'unavailable',
                  '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
                })
              )
            expect_any_instance_of(Ezid::Identifier).to receive(:save)
            subject.update_attributes(doi: [
              '10.doi1/AA1', '10.doi/BB3', '10.abc/FK2'
            ])
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('updated_unavailable')
            expect(subject.reload.doi).to eq([
              '10.doi1/AA1', '10.doi/BB3', '10.abc/FK2'
            ])
          end
        end
      end

      it 'sets doi' do
        expect(Ezid::Identifier).to receive(:mint).with(
          Ezid::Metadata.new({
            'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\"></identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>2013</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
            '_status' => 'reserved',
            '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
          })
        ).and_return(identifier)
        expect(subject.check_doi_presence).to eq('generated_reserved')
        expect(subject.reload.doi).to eq(['doi'])
      end

      context 'when visibility set to public' do
        let(:identifier) { double(
          'ezid-id', id: 'doi', status: 'public'
        ) }

        before { subject.visibility = 'open'; subject.save! }

        it 'sets doi' do
          expect(Ezid::Identifier).to receive(:mint).with(
            Ezid::Metadata.new({
              'datacite' => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\" xsi:schemaLocation=\"http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd\">\n  <identifier identifierType=\"DOI\"></identifier>\n  <creators>\n    <creator>\n      <creatorName>bcd</creatorName>\n    </creator>\n  </creators>\n  <titles>\n    <title>title</title>\n  </titles>\n  <publisher>Galter Health Science Library &amp; Learning Center</publisher>\n  <publicationYear>2013</publicationYear>\n  <resourceType resourceTypeGeneral=\"Other\">Book</resourceType>\n  <descriptions/>\n</resource>\n",
              '_status' => 'public',
              '_target' => 'https://digitalhub.northwestern.edu/files/mahid'
            })
          ).and_return(identifier)
          expect(subject.check_doi_presence).to eq('generated')
          expect(subject.reload.doi).to eq(['doi'])
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
      subject.tag = ['d']
      subject.subject = ['e']
      subject.subject_name = ['f']
      subject.subject_geographic = ['g']
      expect(subject.to_solr['tags_sim'].sort).to eq(
        ['a', 'b', 'c', 'd', 'e', 'f', 'g'])
    end

    it 'generates sortable label' do
      subject.title = ['asdf']
      expect(subject.to_solr['label_si']).to eq('asdf')
    end

    it 'generates content_tesim' do
      expect(subject.content).to receive(:present?).and_return(true)
      expect(subject.content).to receive(:uri).and_return(
        RDF::URI.new('http://localhost'))
      expect(subject.to_solr['content_tesim']).to eq('http://localhost')
    end

    it 'stores file_size as `long` and not `integer`' do
      expect(subject.to_solr['file_size_is']).to be_nil
      expect(subject.to_solr['file_size_lts']).to eq('0')
    end

    let(:fifty_bit_int) { ('1' * 50).to_i(2) }
    it 'can store integers longer then 31 bits in file_size' do
      subject.apply_depositor_metadata('abc')
      subject.title = ['asdf']
      allow(subject.content).to receive(:size).and_return(fifty_bit_int)
      expect(subject.save).to be_truthy
      from_solr = ActiveFedora::SolrService.query("id:#{subject.id}").first
      expect(
        from_solr['file_size_lts']
      ).to eq(fifty_bit_int)
      expect(
        from_solr['file_size_is']
      ).to be_nil
    end
  end

  context 'full text indexing' do
    let(:user) { FactoryGirl.create(:user) }
    subject { make_generic_file(user) }

    before do
      subject.label = File.basename('text_file.txt')
      subject.date_uploaded = DateTime.now
      subject.add_file(
        File.open('spec/fixtures/text_file.txt'),
        original_name: subject.label,
        path: 'content',
        mime_type: 'text/plain'
      )
      subject.save!
      expect(subject.content).to receive(:extract_metadata)
    end

    describe 'file smaller then 10MB' do
      before { subject.characterize }
      it 'extracts the text' do
        expect(subject.full_text.content).to include('roar')
      end
    end

    describe 'file larger then 10MB' do
      before do
        allow(subject.content).to receive(:size).and_return(11.megabytes)
        subject.characterize
      end

      it 'does not extracts the text' do
        expect(subject.full_text.content).to be_nil
      end
    end

    describe 'file of resource type other then Dataset' do
      before do
        subject.update_attributes(resource_type: ['Article'])
        subject.characterize
      end

      it 'extracts the text' do
        expect(subject.full_text.content).to include('roar')
      end
    end

    describe 'file of resource type Dataset' do
      before do
        subject.update_attributes(resource_type: ['Dataset'])
        subject.characterize
      end

      it 'does not extracts the text' do
        expect(subject.full_text.content).to be_nil
      end
    end
  end

  let(:public_permission_double) { double("Hydra::AccessControls::Permission") }
  let(:gv_black_photo_sub_collection_double) { double("Collection") }
  let(:gv_black_collection_double) { double("Collection") }
  let(:random_doi) { "10.18131/g3-nqgv-4863" }
  let(:blank_doi) { "" }
  let(:public_record) { GenericFile.new(doi: []) }
  let(:private_record) { GenericFile.new(doi: []) }

  # if record is publc, has a doi, and is either in the gv black photograph sub collection or is not in the greater gv black collection
  describe "#unexportable?" do
    before do
      allow(public_permission_double).to receive(:agent).and_return(GenericFile::PUBLIC_PERMISSION)

      allow(gv_black_photo_sub_collection_double).to receive(:map).and_return([GenericFile::GV_BLACK_PHOTOGRAPH_SUB_COLLECTION_ID])
      allow(gv_black_photo_sub_collection_double).to receive(:id)

      allow(gv_black_collection_double).to receive(:map).and_return([GenericFile::GV_BLACK_COLLECTION_ID])
      allow(gv_black_collection_double).to receive(:id)
    end

    context "record is public" do
      before do
        # GenericFile validates the type of permissions so simply passing a double to the constructor does not work
        public_record.stub(:permissions).and_return([public_permission_double])
      end

      context "has doi" do
        before do
          public_record.stub(:doi).and_return(random_doi)
        end

        context "is in the gv black photograph sub collection" do
          context "is NOT in the gv black papers collection" do
            before do
              public_record.stub(:collections).and_return([gv_black_photo_sub_collection_double])
            end

            it "returns true" do
              expect(public_record.unexportable?).to eq(true)
            end
          end

          context "is in the gv black papers collection" do
            before do
              public_record.stub(:collections).and_return([gv_black_photo_sub_collection_double, gv_black_collection_double])
            end

            it "returns true" do
              expect(public_record.unexportable?).to eq(true)
            end
          end
        end

        context "is NOT in the gv black photograph sub collection" do
          context "is NOT in the gv black papers collection" do
            before do
              public_record.stub(:collections).and_return([])
            end

            it "returns true" do
              expect(public_record.unexportable?).to eq(true)
            end
          end

          context "is in the gv black papers collection" do
            before do
              public_record.stub(:collections).and_return([gv_black_collection_double])
            end

            it "returns true" do
              expect(public_record.unexportable?).to eq(true)
            end
          end
        end
      end

      context "has no doi" do
        before do
          public_record.stub(:doi).and_return(blank_doi)
        end

        context "is in the gv black photograph sub collection" do
          before do
            public_record.stub(:collections).and_return(gv_black_photo_sub_collection_double)
          end

          context "is NOT in the gv black papers collection" do
            it "returns true" do
              expect(public_record.unexportable?).to eq(false)
            end
          end
        end
      end
    end

    context "record is NOT public" do
      before do
        allow(private_record).to receive(:permissions).and_return([])
      end

      context "has doi" do
        before do
          allow(private_record).to receive(:doi).and_return(random_doi)
        end

        context "is in the gv black photograph sub collection" do
          context "is NOT in the gv black papers collection" do
            before do
              allow(private_record).to receive(:collections).and_return([gv_black_photo_sub_collection_double])
            end

            it "returns true" do
              expect(private_record.unexportable?).to eq(false)
            end
          end

          context "is in the gv black papers collection" do
            before do
              allow(private_record).to receive(:collections).and_return([gv_black_photo_sub_collection_double, gv_black_collection_double])
            end

            it "returns true" do
              expect(private_record.unexportable?).to eq(false)
            end
          end
        end

        context "is NOT in the gv black photograph sub collection" do
          context "is NOT in the gv black papers collection" do
            before do
              private_record.stub(:collections).and_return([])
            end

            it "returns true" do
              expect(private_record.unexportable?).to eq(false)
            end
          end

          context "is in the gv black papers collection" do
            before do
              private_record.stub(:collections).and_return([gv_black_collection_double])
            end

            it "returns true" do
              expect(private_record.unexportable?).to eq(false)
            end
          end
        end
      end
    end
  end
end
