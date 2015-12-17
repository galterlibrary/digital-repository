module Galtersufia
  module BatchController
    extend ActiveSupport::Autoload
  end

  module BatchControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::BatchControllerBehavior
    included do
      self.edit_form_class = Sufia::Forms::GalterGenericFileEditForm
      after_action :schedule_doi_job, only: [:update]
    end

    def schedule_doi_job
      @batch.generic_files.each do |gf|
        if gf.persisted?
          Sufia.queue.push(MintDoiJob.new(gf.id))
        end
      end
    end
    private :schedule_doi_job
  end
end
