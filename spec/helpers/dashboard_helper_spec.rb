require 'rails_helper'

RSpec.describe DashboardHelper, :type => :helper do
  describe '#on_my_files?' do
    context 'controller is my/files' do
      before do
        expect(controller).to receive(:params).and_return(
          :controller => 'my/files')
      end

      it 'returns true' do
        expect(helper.on_my_files?).to be_truthy
      end
    end

    context 'controller is my/shares' do
      before do
        expect(controller).to receive(:params).and_return(
          :controller => 'my/shares')
      end

      it 'returns true' do
        expect(helper.on_my_files?).to be_truthy
      end
    end

    context 'controller is my/highlights' do
      before do
        expect(controller).to receive(:params).and_return(
          :controller => 'my/highlights')
      end

      it 'returns true' do
        expect(helper.on_my_files?).to be_truthy
      end
    end

    context 'controller is something else' do
      before do
        expect(controller).to receive(:params).and_return(
          :controller => 'my/collections')
      end

      it 'returns true' do
        expect(helper.on_my_files?).to be_falsy
      end
    end
  end
end
