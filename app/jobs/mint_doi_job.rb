class MintDoiJob < ActiveFedoraIdBasedJob
  attr_accessor :username
  def initialize(file_id, username)
    self.id = file_id
    self.username = username
  end

  def queue_name
    :doi
  end

  def user
    User.find_by(username: username)
  end

  def title
    object.title.first
  end

  def body(status)
    case status
    when 'generated'
      "DOI was generated for <a href='/files/#{self.id}'>#{title}</a>"
    when 'updated'
      "DOI metadata was updated for <a href='/files/#{self.id}'>#{title}</a>"
    when 'page'
      "DOI was not generated for <a href='/files/#{self.id}'>#{title}</a>, because the file is a page in a document."
    when 'metadata'
      "DOI was not generated for <a href='/files/#{self.id}'>#{title}</a>, because the file is missing required metadata. Please edit the file to generate a DOI."
    end
  end

  def subject(status)
    case status
    when 'generated'
      'DOI generated'
    when 'updated'
      'DOI metadata updated'
    when 'page', 'metadata'
      'DOI not generated'
    end
  end

  def run
    status = object.check_doi_presence
    return unless status.present?
    User.batchuser.send_message(user, body(status), subject(status), false)
  end
end
