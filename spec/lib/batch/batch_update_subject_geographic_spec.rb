require 'rails_helper'
require "#{Rails.root}/lib/batch/batch_update_subject_geographic"

RSpec.describe 'rails runner lib/batch/batch_update_subject_geographic.rb' do
  before do 
    @user = FactoryGirl.create(:user)
    @one_subject_geographic = make_generic_file(@user, :subject_geographic => ["Chicago--Illinois"])
    @two_subject_geographic = make_generic_file(@user, :subject_geographic => ["Chicago--Illinois", "Chicago, Illinois"])
    @random_subject_geographic = make_generic_file(@user, :subject_geographic => ["Evanston--Illinois"])
  end

  describe '#batch_update_subject_geographic' do
    context "with one old_terms passed" do
      it 'updates subject_geographic with new value' do

        batch_update_subject_geographic(
          solr_query: "chicago",
          old_terms: ["Chicago--Illinois"],
          new_term: "Chicago (Ill.)"
        ) 

        @one_subject_geographic.reload
        @two_subject_geographic.reload
        @random_subject_geographic.reload

        expect(@one_subject_geographic.subject_geographic).to eq(["Chicago (Ill.)"])
        expect(@two_subject_geographic.subject_geographic).to eq(["Chicago, Illinois", "Chicago (Ill.)"])
        expect(@random_subject_geographic.subject_geographic).to eq(["Evanston--Illinois"])
      end
    end

    context "with two old_terms passed" do
      it 'updates subject_geographic with new value' do

        batch_update_subject_geographic(
          solr_query: "chicago",
          old_terms: ["Chicago--Illinois", "Chicago, Illinois"],
          new_term: "Chicago (Ill.)"
        ) 

        @one_subject_geographic.reload
        @two_subject_geographic.reload
        @random_subject_geographic.reload

        expect(@one_subject_geographic.subject_geographic).to eq(["Chicago (Ill.)"])
        expect(@two_subject_geographic.subject_geographic).to eq(["Chicago (Ill.)"])
        expect(@random_subject_geographic.subject_geographic).to eq(["Evanston--Illinois"])
      end
    end
  end
end
