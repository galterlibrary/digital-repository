require 'rails_helper'
RSpec.describe Role do
  it { is_expected.to respond_to(:description) }
end
