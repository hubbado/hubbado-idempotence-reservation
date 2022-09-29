require_relative '../../test_init'

context "Reservation" do
  idempotence_key = '123'

  context "When Reserved Metadata Name exists in the Message" do
    metadata = Controls::Metadata::Reserved.example
    message = Controls::Message::New.example
    message.metadata = metadata

    block_accessed = false

    reservation = Reservation.new
    reservation.(message, idempotence_key) do
      block_accessed = true
    end

    test "Reservation Message is not Written" do
      writer = reservation.write
      refute(writer.written?)
    end

    test "Accesses the Block" do
      assert(block_accessed)
    end
  end

  context "When Reserved Metadata does not exist in the Message" do
    original_stream_name = "someStream-987"

    metadata = Controls::Metadata::Random.example
    message = Controls::Message::New.example
    metadata.stream_name = original_stream_name
    message.metadata = metadata

    block_accessed = false

    reservation = Reservation.new
    reservation.(message, idempotence_key) do
      block_accessed = true
    end

    writer = reservation.write

    reservation_message = writer.one_message

    test "Reservation Message is Written" do
      written_to_stream = writer.written?(reservation_message) do |stream_name|
        stream_name == "#{original_stream_name}+#{idempotence_key}"
      end

      assert(written_to_stream)
    end

    test "Does not Access the Block" do
      refute(block_accessed)
    end
  end
end
