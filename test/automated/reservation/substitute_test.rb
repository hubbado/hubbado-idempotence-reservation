require_relative "../../test_init"

context "Reservation" do
  context "Substitute" do
    block_called = false
    block_message = nil
    message = "Message"
    idempotence_key = "Key"

    substitute = Reservation::Substitute.build
    substitute.(message, idempotence_key) do |m|
      block_called = true
      block_message = m
    end

    test "Block is called" do
      assert(block_called)
      assert(block_message == message)
    end

    test "Called with message" do
      assert(substitute.message?(message))
    end

    test "Called with idempotence_key" do
      assert(substitute.idempotence_key?(idempotence_key))
    end
  end
end
