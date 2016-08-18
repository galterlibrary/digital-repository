require 'rails_helper'

describe BatchUpdateJob do
  let(:batch) { Batch.create }
  let(:gf1) { make_generic_file(create(:user), id: 'gf1') }

  context '#queue_additional_jobs' do
    subject { described_class.new('somedude', batch.id, nil, {}, 'open') }

    before do
      cue_job = double('cue')
      allow(ContentUpdateEventJob).to receive(:new)
                                  .with(gf1.id, 'somedude')
                                  .and_return(cue_job)
      expect(Sufia.queue).to receive(:push).with(cue_job)
      rjf_job = double('rgf')
      allow(ResolrizeGenericFileJob).to receive(:new)
                                    .with(gf1.id)
                                    .and_return(rjf_job)
      expect(Sufia.queue).to receive(:push).with(rjf_job)
    end

    it 'queues the MintDoiJob' do
      md_job = double('md')
      allow(MintDoiJob).to receive(:new)
                       .with(gf1.id, 'somedude')
                       .and_return(md_job)
      expect(Sufia.queue).to receive(:push).with(md_job)
      subject.queue_additional_jobs(gf1)
    end
  end
end
