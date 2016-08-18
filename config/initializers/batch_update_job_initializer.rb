Rails.configuration.to_prepare do
  BatchUpdateJob.class_eval do
    alias_method :super_queue_additional_jobs, :queue_additional_jobs
    def queue_additional_jobs(gf)
      super_queue_additional_jobs(gf)
      Sufia.queue.push(MintDoiJob.new(gf.id, login))
    end
  end
end
