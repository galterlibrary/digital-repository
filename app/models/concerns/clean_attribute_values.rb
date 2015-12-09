module CleanAttributeValues
  extend ActiveSupport::Concern

  included do
    before_save :clean_changed_attributes
  end

  # Stolen from:
  # http://rosettacode.org/wiki/Strip_control_codes_and_extended_characters_from_a_string#Ruby
  def strip_control_characters(value)
    return value unless value.is_a?(String)
    value.chars.inject('') do |str, char|
      next str if !char.ascii_only? || char.ord < 32 || char.ord == 127
      str << char
    end
  end
  private :strip_control_characters

  def cleaned_value(value)
    if value.is_a?(String)
      value = strip_control_characters(value)
    elsif value.is_a?(Array)
      value = value.map {|o| strip_control_characters(o) }
    end
    value
  end
  private :cleaned_value

  def clean_changed_attributes
    changed.each do |attr_name|
      self[attr_name] = cleaned_value(self[attr_name])
    end
  end
  protected :clean_changed_attributes
end
