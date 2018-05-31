require 'rails_helper'

RSpec.describe AuthoritiesController, :type => :controller do
  describe '#query', :vcr do
    context 'invalid query' do
      subject { get :query }
      
      it { is_expected.to have_http_status(:success) }
      
      it 'returns empty array' do
        expect(subject["response"]).to be_nil
      end
    end
    
    context 'lcsh' do
      describe 'with results' do
        subject { JSON.parse(get(:query, q: 'coffee', term: 'lcsh').body) }
        
        it 'returns values from LOC' do
          expect(subject.count).to eq(10)
          
          subject.each{ |s|
            expect(s.downcase).to include('coffee')
          }
        end
      end
      
      describe 'with one result' do
        subject { JSON.parse(get(:query, q: 'coffee bean', term: 'lcsh').body) }
        
        it 'returns one value from LOC' do
          expect(subject.count).to eq(1)
          
          expect(subject.first.downcase).to include('coffee bean')
        end
      end
      
      describe 'with no results' do
        subject { JSON.parse(get(:query, q: 'coughee', term: 'lcsh').body) }
        
        it 'returns empty array' do
          expect(subject.count).to eq(0)
        end
      end
    end
    
    context 'subject_geographic' do
      describe 'with results' do
        subject { JSON.parse(get(:query, q: 'ethiopia', term: 'subject_geographic').body) }
        
        it 'returns values from FAST' do
          expect(subject.count).to eq(10)
          
          subject.each{ |s|
            expect(s.downcase).to include('ethiopia')
          }
        end
      end
      
      describe 'with one result' do
        subject { JSON.parse(get(:query, q: 'empire of ethiopia', term: 'subject_geographic').body) }
        
        it 'returns values from FAST' do
          expect(subject.count).to eq(1)
          
          expect(subject.first.downcase).to eq('empire of ethiopia')
        end
      end
      
      describe 'with no results' do
        subject { JSON.parse(get(:query, q: 'javatown', term: 'subject_geographic').body) }
        
        it 'returns empty array' do
          expect(subject.count).to eq(0)
        end
      end
    end
    
    context 'based_near' do
      describe 'with results' do
        subject { JSON.parse(get(:query, q: 'ethiopia', term: 'based_near').body) }
        
        it 'returns values from GeoNames' do
          expect(subject.count).to eq(10)
          subject.each{ |s|
            expect(s["value"].downcase).to include('ethiopia')
          }
        end
      end
      
      describe 'with one result' do
        subject { JSON.parse(get(:query, q: 'ethiopian plateau', term: 'based_near').body) }

        it 'returns values from GeoNames' do
          expect(subject.count).to eq(1)

          expect(subject.first["value"].downcase).to include('ethiopian plateau')
        end
      end
      
      describe 'with no results' do
        subject { JSON.parse(get(:query, q: 'javatown', term: 'based_near').body) }
        
        it 'returns empty array' do
          expect(subject.count).to eq(0)
        end
      end
    end
  end
end
