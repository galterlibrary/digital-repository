FactoryGirl.define do
  factory :subject_local_authority_entry do
    sequence(:lowerLabel) {|n| "name#{n}" }
    sequence(:label) {|n| "Full Name #{n}" }
    sequence(:url) {|n| "http://a.net/name#{n}" }
  end
end
