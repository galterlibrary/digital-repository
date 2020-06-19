require 'rails_helper'
require "#{Rails.root}/lib/batch/batch_metadata_updates_654"

RSpec.describe 'rails runner lib/batch/batch_metadata_updates_654.rb' do
  before do 
    @user = FactoryGirl.create(:user)
    @public = make_generic_file(@user, visibility: 'open') 
    @nu_only = make_generic_file(@user, visibility: 'authenticated') 
    @private = make_generic_file(@user, visibility: 'restricted') 
    @has_publisher = make_generic_file(@user, visibility: 'open')
    @has_publisher.update_attributes(:publisher => ["Some Publisher"])
  end

  describe 'add_digitalhub_to_non_private_empty_publisher_record' do
    before do 
      # because we create new records with the new publisher value, we have 
      # to 'unset' it
      @public.update_attributes(:publisher => [])
      @nu_only.update_attributes(:publisher => [])
      @private.update_attributes(:publisher => [])
    end

    it 'updates non-private record with empty publisher field' do
      expect(@public.publisher).to eq([])
      expect(@nu_only.publisher).to eq([])
      expect(@private.publisher).to eq([])
      expect(@has_publisher.publisher).to eq(["Some Publisher"])

      add_digitalhub_to_non_private_empty_publisher_record 

      @public.reload
      @nu_only.reload
      @private.reload
      @has_publisher.reload

      expect(@public.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
      expect(@nu_only.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
      expect(@private.publisher).to eq([])
      expect(@has_publisher.publisher).to eq(["Some Publisher"])
    end
  end

  describe 'add_digitalhub_to_publisher' do
    context "when publisher is 'Galter Health Sciences Library & Learning Center'" do
      before do
        # because we create new records with the new publisher value, we have 
        # to set it accordingly
        @public.update_attributes(
          :publisher => ["Galter Health Sciences Library & Learning Center", "ABC Publisher"])
        @nu_only.update_attributes(:publisher => ["Galter Health Sciences Library & Learning Center"])
        @private.update_attributes(:publisher => ["Galter Health Sciences Library & Learning Center"])
      end

      it "updates the field with 'DigitalHub.'" do 
        expect(@public.publisher).to eq(
          ["Galter Health Sciences Library & Learning Center", "ABC Publisher"])
        expect(@nu_only.publisher).to eq(["Galter Health Sciences Library & Learning Center"])
        expect(@private.publisher).to eq(["Galter Health Sciences Library & Learning Center"])
        expect(@has_publisher.publisher).to eq(["Some Publisher"])

        add_digitalhub_to_publisher("Galter Health Sciences Library & Learning Center")

        @public.reload
        @nu_only.reload
        @private.reload
        @has_publisher.reload

        expect(@public.publisher).to eq(
          ["DigitalHub. Galter Health Sciences Library & Learning Center", "ABC Publisher"])
        expect(@nu_only.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
        expect(@private.publisher).to eq(["DigitalHub. Galter Health Sciences Library & Learning Center"])
        expect(@has_publisher.publisher).to eq(["Some Publisher"])
      end
    end

    context "when publisher is 'Galter Health Sciences Library'" do
      before do
        # because we create new records with the new publisher value, we have 
        # to set it accordingly 
        @public.update_attributes(:publisher => ["Galter Health Sciences Library"])
        @nu_only.update_attributes(:publisher => ["Galter Health Sciences Library"])
        @private.update_attributes(:publisher => ["Galter Health Sciences Library"])
      end

      it "updates the field with 'DigitalHub.'" do 
        expect(@public.publisher).to eq(["Galter Health Sciences Library"])
        expect(@nu_only.publisher).to eq(["Galter Health Sciences Library"])
        expect(@private.publisher).to eq(["Galter Health Sciences Library"])
        expect(@has_publisher.publisher).to eq(["Some Publisher"])

        add_digitalhub_to_publisher("Galter Health Sciences Library")

        @public.reload
        @nu_only.reload
        @private.reload
        @has_publisher.reload

        expect(@public.publisher).to eq(["DigitalHub. Galter Health Sciences Library"])
        expect(@nu_only.publisher).to eq(["DigitalHub. Galter Health Sciences Library"])
        expect(@private.publisher).to eq(["DigitalHub. Galter Health Sciences Library"])
        expect(@has_publisher.publisher).to eq(["Some Publisher"])
      end
    end
  end
end
