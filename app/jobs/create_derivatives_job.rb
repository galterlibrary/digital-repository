class CreateDerivativesJob < ActiveFedoraIdBasedJob
  def queue_name
    :derivatives
  end

  def run
    return unless generic_file.content.has_content?
    return if generic_file.video? && !Sufia.config.enable_ffmpeg

    generic_file.create_derivatives
    # force modified_date update
    generic_file.mark_as_changed(:label)
    generic_file.save
    generic_file.update_index
  end
end
