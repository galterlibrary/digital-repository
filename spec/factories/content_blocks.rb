FactoryGirl.define do
  factory :content_block do
    sequence :name do |n|
      "role#{n}"
    end

    sequence :value do |n|
      "value#{n}"
    end
  end
end
