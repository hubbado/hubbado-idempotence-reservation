module Idempotence
  module Controls
    Metadata = Messaging::Controls::Metadata

    module Metadata::Reserved
      def self.example
        metadata = Metadata::Random.example

        metadata.local_properties[Reservation::METADATA_NAME] = :value

        metadata
      end
    end
  end
end
