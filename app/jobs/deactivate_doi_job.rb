class DeactivateDoiJob < ActiveFedoraIdBasedJob
  attr_accessor :username, :doi, :title, :status
  def initialize(file_id, doi, username, gf_title=nil)
    self.id = file_id
    self.title = gf_title || find_title
    self.doi = doi.to_s.strip
    self.username = username
  end

  def find_title
    object.title.first
  rescue Ldp::Gone, ActiveFedora::ObjectNotFoundError
    self.id
  end

  def file_link_or_title
    "<a href='/files/#{object.id}'>#{self.title}</a>"
  rescue Ldp::Gone, ActiveFedora::ObjectNotFoundError
    "a deleted object: '#{self.title}'"
  end

  def queue_name
    :doi
  end

  def user
    User.find_by(username: username)
  end

  def body
    case self.status
    when 'deactivated'
      "DOI '#{self.doi}' was deactivated for #{file_link_or_title}"
    when 'deleted'
      "DOI '#{self.doi}' was removed for #{file_link_or_title}"
    end
  end

  def subject
    case self.status
    when 'deactivated'
      'DOI deactivated'
    when 'deleted'
      'DOI deleted'
    end
  end

  def deactivate_or_remove_doi
    identifier = Ezid::Identifier.find(self.doi)
    if identifier.status == 'reserved'
      identifier.delete
      self.status = 'deleted'
    else
      identifier.status = 'unavailable'
      identifier.save
      self.status = 'deactivated'
    end
  rescue Ezid::Error
  end

  def run
    deactivate_or_remove_doi
    return unless self.status.present?
    User.batchuser.send_message(user, body, subject, false)
  end
end
