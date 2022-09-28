require_relative '../../test_init'

context "Reservation" do
  idempotence_key = '123'

  context "When reserved metadata name exists in the message" do
    metadata = Messaging::Controls::Metadata::Random.example
    metadata.properties[Reservation::METADATA_NAME] = :a_value

    message = Messaging::Controls::Message::New.example
    message.metadata = metadata

    block_accessed = nil
    reservation = Reservation.new
    reservation.(message, idempotence_key) do
      block_accessed = "block"
    end

    writer = reservation.write

    reservation_message = writer.one_message

    test "Reservation Message is not Written" do
      assert(reservation_message.nil?)
    end

    test "Access Block" do
      assert(block_accessed == "block")
    end
  end

  context "When reserved metadata does not exist in the message" do
    metadata = Messaging::Controls::Metadata::Random.example
    message = Messaging::Controls::Message::New.example
    message.metadata = metadata

    reservation = Reservation.new
    reservation.(message, idempotence_key)

    writer = reservation.write

    reservation_message = writer.one_message

    test "Reservation Message is Written" do
      written_to_stream = writer.written?(reservation_message) do |stream_name|
        stream_name == "#{message.metadata.stream_name}-+#{idempotence_key}"
      end

      assert(written_to_stream)
    end
  end
end
