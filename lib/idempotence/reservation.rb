module Idempotence
  class Reservation
    include Messaging::StreamName
    include Log::Dependency

    METADATA_NAME = :reserved

    dependency :write, Messaging::Postgres::Write

    configure :reservation

    def self.call(message, idempotence_key, session: nil)
      instance = build(session: session)
      instance.(message, idempotence_key)
    end

    def self.build(session: nil)
      instance = new
      instance.configure(session: session)
      instance
    end

    def configure(session: nil)
      Messaging::Postgres::Write.configure(self, session: session)
    end

    def call(message, idempotence_key)
      reserved_metadata = message.metadata.get_property(METADATA_NAME)

      if reserved_metadata
        yield
        return
      end

      reservation_message = message.class.follow(message)
      reservation_message.metadata.set_property(METADATA_NAME, message.id)
      category, id = MessageStore::StreamName.split(message.metadata.stream_name)

      stream_name = MessageStore::StreamName.stream_name(category, [id, idempotence_key])

      result = Try.(MessageStore::ExpectedVersion::Error) do
        write.initial(reservation_message, stream_name)
      end

      return if result

      logger.info(
        "#{message.class.name} #{message.metadata.global_position} ignored, output stream #{stream_name} exists",
        tags: %i[reservation ignored]
      )
    end
  end
end
