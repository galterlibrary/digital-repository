require 'rails_helper'
RSpec.describe User do
  describe '#standardized_name' do
    context 'no middle name' do
      subject {
        Nuldap.standardized_name({
          'sn' => ['Last'], 'givenName' => ['First']
        })
      }

      it { is_expected.to eq('Last, First') }
    end

    context 'middle name' do
      describe 'one letter' do
        context 'middle name is different then first name' do
          subject {
            Nuldap.standardized_name({
              'sn' => ['Last'], 'givenName' => ['First P'], 'nuMiddleName' => ['F']
            })
          }

          it { is_expected.to eq('Last, First P F') }
        end

        context 'middle name is part of first name' do
          subject {
            Nuldap.standardized_name({
              'sn' => ['Last'], 'givenName' => ['First P F'], 'nuMiddleName' => ['F']
            })
          }

          it { is_expected.to eq('Last, First P F') }
        end
      end

      describe 'more than one letter' do
        context 'middle name is different then first name' do
          subject {
            Nuldap.standardized_name({
              'sn' => ['Last'], 'givenName' => ['First P'], 'nuMiddleName' => ['Nope']
            })
          }

          it { is_expected.to eq('Last, First P Nope') }
        end

        context 'middle name is part of first name' do
          subject {
            Nuldap.standardized_name({
              'sn' => ['Last'], 'givenName' => ['P. Nope'], 'nuMiddleName' => ['nope']
            })
          }

          it { is_expected.to eq('Last, P. Nope') }
        end
      end
    end
  end
end
