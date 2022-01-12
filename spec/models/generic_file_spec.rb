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

    describe 'all required metadata present', :vcr do
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
          expect(DataciteRest).not_to receive(:mint)
          expect(DataciteRest).not_to receive(:get_doi)
          expect(subject.check_doi_presence).to eq('page')
          expect(subject.reload.doi).to eq([])
        end

        describe 'with no page_number metadata' do
          before do
            subject.update_attributes(page_number: nil)
          end

          it 'creates the doi' do
            expect(subject.check_doi_presence).to eq('draft_restricted')
            expect(subject.reload.doi).to eq(['10.82113/as-zwv6-gf43'])
          end
        end
      end

      context 'no date_uploaded' do
        before { subject.update_attributes(date_uploaded: nil) }

        it 'sets doi' do
          expect(subject.check_doi_presence).to eq('draft_restricted')
          expect(subject.reload.doi).to eq(['10.82113/as-9n6h-wf43'])
        end
      end

      context 'doi already present' do
        describe 'does not originate from Galter' do
          before { subject.update_attributes(doi: ['10.abc/FK2']) }

          it 'does nothing' do
            expect(subject.check_doi_presence).to be_nil
            expect(subject.reload.doi).to eq(['10.abc/FK2'])
          end
        end

        describe 'originates from Galter and visibility set to open' do
          before do
            subject.update_attributes(doi: ['10.82113/as-4e2m-fd12'])
            subject.visibility = 'open'
            subject.save!
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('already_findable')
            expect(subject.reload.doi).to eq(['10.82113/as-4e2m-fd12'])
          end
        end

        describe 'originates from Galter and visibility set to restricted' do
          before do
            subject.update_attributes(doi: ['10.82113/as-4e2m-fd12'])
            subject.visibility = 'authenticated'
            subject.save!
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('hide_findable')
            expect(subject.reload.doi).to eq(['10.82113/as-4e2m-fd12'])
          end
        end

        describe 'multiple dois one originating from Galter' do
          before do
            subject.visibility = 'authenticated'
            subject.update_attributes(doi: [
              '10.doi1/AA1', '10.doi/BB3', '10.abc/FK2', '10.82113/as-5edn-6577'
            ])
          end

          it 'updates the metadata remotely but not the ids locally' do
            expect(subject.check_doi_presence).to eq('hide_findable')
            expect(subject.reload.doi).to eq([
              '10.doi1/AA1', '10.doi/BB3', '10.abc/FK2', '10.82113/as-5edn-6577'
            ])
          end
        end
      end

      it 'sets doi' do
        expect(subject.check_doi_presence).to eq('draft_restricted')
        expect(subject.reload.doi).to eq(['10.82113/as-20qw-j035'])
      end

      context 'when visibility set to public' do
        before { subject.visibility = 'open'; subject.save! }

        it 'sets doi' do
          expect(subject.check_doi_presence).to eq('draft_published')
          expect(subject.reload.doi).to eq(['10.82113/as-5edn-6577'])
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
end
