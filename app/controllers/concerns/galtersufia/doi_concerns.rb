module Galtersufia
  module DoiConcerns
    extend ActiveSupport::Concern

    def schedule_doi_deactivation_jobs(target)
      return unless target.respond_to?(:doi)
      target.doi.each do |doi|
        schedule_doi_deactivation_job_for(doi, target)
      end
    end
    protected :schedule_doi_deactivation_jobs

    def schedule_doi_deactivation_job_for(doi, target)
        Sufia.queue.push(
          DeactivateDoiJob.new(
            target.id, doi, current_user.username, target.title.first
          )
        )
    end
    protected :schedule_doi_deactivation_job_for

  end
end
