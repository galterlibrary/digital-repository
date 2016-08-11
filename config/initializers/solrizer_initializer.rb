Rails.configuration.to_prepare do
  module Solrizer
    module GalterDescriptors
      def self.stored_long
        @stored_long ||= Solrizer::Descriptor.new(:long, :stored)
      end

      def self.stored_integer
        @stored_integer ||= Solrizer::Descriptor.new(:integer, :stored)
      end
    end
  end

  Solrizer::FieldMapper.descriptors = [
    Solrizer::DefaultDescriptors,
    Solrizer::GalterDescriptors
  ]
end
