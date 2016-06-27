require 'rails_helper'
RSpec.describe ContactForm do
  describe '#headers' do
    context 'email was specified' do
      subject { ContactForm.new(email: 'abc@bcd.cde').headers }
      specify do
        expect(subject[:from]).to eq('abc@bcd.cde')
      end
    end

    context 'email was not specified' do
      subject { ContactForm.new(email: '').headers }
      specify do
        expect(subject[:from]).to eq(Sufia.config.from_email)
      end
    end
  end
end
