class MintDoiJob < ActiveFedoraIdBasedJob
  def queue_name
    :doi
  end

  def run
    object.check_doi_presence
  end
end
