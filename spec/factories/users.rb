FactoryGirl.define do
  factory :user do
    sequence :email do |n|
      "user#{n}@example.com"
    end

    sequence :username do |n|
      "user#{n}"
    end

    factory :admin_user do
      after :create do |user|
        Role.find_or_create_by(name: 'admin')
        user.add_role('admin')
      end
    end
  end
end
