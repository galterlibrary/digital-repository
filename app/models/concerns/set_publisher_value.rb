module SetPublisherValue
  extend ActiveSupport::Concern

  included do
    after_initialize :preset_publisher, if: :new_record?
  end

  def preset_publisher
    self.publisher += ['DigitalHub. Galter Health Sciences Library & Learning Center']
  end
  private :preset_publisher
end
