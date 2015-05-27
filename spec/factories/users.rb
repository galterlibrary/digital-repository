FactoryGirl.define do
  factory :user do
    sequence :email do |n|
      "user#{n}@example.com"
    end

    sequence :username do |n|
      "user#{n}"
    end
  end
end
