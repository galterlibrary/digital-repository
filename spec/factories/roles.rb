FactoryGirl.define do
  factory :role do
    sequence :name do |n|
      "role#{n}"
    end
  end
end
