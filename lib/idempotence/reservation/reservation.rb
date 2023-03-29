module Idempotence
  class Reservation
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

    def call(message, idempotence_key, &block)
      logger.trace(
        "Handling reservation idempotence for message #{message.class.name} #{message.metadata.global_position}",
        tag: :reservation
      )

      if reserved?(message)
        handle_reserved_message(message, &block)
      else
        reserve_message(message, idempotence_key)
      end

      logger.info(
        "Handled reservation idempotence for #{message.class.name} #{message.metadata.global_position}",
        tag: :reservation
      )
    end

    def handle_reserved_message(message, &block)
      logger.trace(
        "Handling reserved message #{message.class.name} #{message.metadata.global_position}",
        tag: :reservation
      )

      yield message

      logger.info(
        "Handled reserved message #{message.class.name} #{message.metadata.global_position}",
        tag: :reservation
      )
    end

    private

    def reserved?(message)
      !!message.metadata.get_local_property(METADATA_NAME)
    end

    def reserve_message(message, idempotence_key)
      logger.trace(
        "Reserving #{message.class.name} #{message.metadata.global_position}, Idempotence Key: #{idempotence_key}",
        tag: :reservation
      )

      reservation_message = message.class.follow(message)
      reservation_message.metadata.set_local_property(METADATA_NAME, message.id)
      origin_stream_name = message.metadata.stream_name

      category = Messaging::StreamName.get_category(origin_stream_name)
      origin_ids = Messaging::StreamName.get_ids(origin_stream_name)

      ids = origin_ids + [idempotence_key]

      stream_name = MessageStore::StreamName.stream_name(category, ids)

      result = Try.(MessageStore::ExpectedVersion::Error) do
        write.initial(reservation_message, stream_name)
      end

      if result
        logger.info(
          "Reserved #{message.class.name} #{message.metadata.global_position}, Idempotence Key: #{idempotence_key}",
          tag: :reservation
        )
      else
        log_ignore(message, stream_name)
      end
    end

    def log_ignore(message, stream_name)
      logger.info(
        "#{message.class.name} #{message.metadata.global_position} ignored, output stream #{stream_name} exists",
        tags: %i[reservation ignored]
      )
    end

    module Substitute
      def self.build
        Reservation.new
      end

      class Reservation
        attr_reader :message
        attr_reader :idempotence_key

        def call(message, idempotence_key, &block)
          @message = message
          @idempotence_key = idempotence_key

          yield message if @yield
        end

        def set_reserved(value)
          @yield = value
        end

        def message?(value)
          message == value
        end

        def idempotence_key?(value)
          idempotence_key == value
        end
      end
    end
  end
end
