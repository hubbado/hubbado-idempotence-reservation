# Hubbado Idempotence Reservation

Idempotent handling of re-issued commands using the resevation pattern for the [Eventide](https://eventide-project.org/) framework

## The Reservation Pattern

The reservation pattern is way of ensuring that messages sent more than once are only processed once. The service sending the message cannot be always be certain that it has sent the message (for example, it may crash after sending the message, but before failing to record that it has been sent), and therefore may send the message multiple times.

To achiveve this each copy of the message is given the same, unique, idempotence key, that is used to detect duplicates. The processor of the messages ensures that it will only handle messages with this idempotence key once. To do this it makes a unique reservation for the idempotence key and only if it has successfully made the reservation will it process the message. After the first copy has been successfully processed it will not process the duplicates as it cannot successfully reserve a previously used idempotence key.

In Eventide this pattern is tpyically used for commands streams. A service writes command messages into a command stream. A handler of the command stream writes each command into a second stream, using the idempotence key as part of stream identifier, with the expected version set to `initial`, so that the write will only succeed if it is the initial message in the stream.

A second handler handles these second streams, where it will only find one copy of each command, regardless of how many times the command was re-issued.

## A Word of Warning

This library should not be used without fully understanding how it works and why to use it. We firmly recommend that you are fully up to speed on idempotence, and the various ways of implementing it, before attempting to use this library.

Some useful resources for this are:

- [Idempotence: A Primer](https://blog.eventide-project.org/articles/idempotence-primer/) From the Eventide Blog
- [Video: Idempotence (or why our understanding of elevator buttons is incorrect](https://www.youtube.com/watch?v=mVkIC512ihM) From the Utah Microservices Meetup
- [Nobody Needs Reliable Messaging](https://www.infoq.com/articles/no-reliable-messaging/) From InfoQ. Do not be put off by this older article referencing Web Services, it's explanation of idempotence is very good and still relevant - design fundamentals do not date

We also highly recommend the Eventide training course [3-Day Evented Microservices, Autonomous Services, and Event Sourcing Workshop](https://eventide-project.org/#training-section)

## Purpose of this library

This library allows you to implement the command reservation pattern without requiring a second stream or handler.

In your command handler you process the command like this:

```ruby
class SomeHandler
  dependency :reservation, Idempotence::Reservation

  def configure(session: nil)
    Idempotence::Reservation.configure(self, session: session)
  end

  handle SomeMessage do |some_message|
    reservation.(some_message, :some_idempotence_key) do
      # Handle reserved message
    end
  end
end
```

The `reservation.()` method will do one of two things, depending on whether it finds its own "reservation" metadata in the message or not.

The first tine a command is handled it will not yet have had metadata added indicating that it has been "reserved". It will therefore skip the given block and instead write a copy of the command:

- with metadata recording that the command has reserved (the metadata local property `reserved` is set to the value of the idempotence key)
- into a stream with a compound ID consisting of the original stream name plus the value of`idempotence_key`. For example if the original stream name was `someCategory:command-123` and the value of `idemopotence_key` is `AAA` this copy will be written into `someCategory:command-123+AAA`
- using `write.initial` so that it will only ever write one copy of the command

Because the command handler is processing the command "category" (e.g. `someCategory`), it will find this copy, and handling it will also pass it into the same `reservation.()` method. This time it will find the metadata recording that the command has been reserved, so the behaviour changes - instead of writing a copy of the message, the block is processed instead.

## Eventide Account Component Example

The Eventide [AccountComponent](https://github.com/eventide-examples/account-component) is an example used as training material on the excellent Eventide training course "3-Day Evented Microservices, Autonomous Services, and Event Sourcing Workshop" which you can read about here: https://eventide-project.org/#training-section

This documentation will not explain the Account Component, and we heavily recommend that you are able to understand all the working parts of that component before attempting to use this library.

The Account Component uses the reservation pattern to ensure that Deposit and Withdraw commands are only handled once, which we will recap briefly here.

Each deposit has a unique `deposit_id` and each withdrawl has a unique `withdrawal_id`

https://github.com/eventide-examples/account-component/blob/master/lib/account_component/messages/commands/deposit.rb#L7

https://github.com/eventide-examples/account-component/blob/master/lib/account_component/messages/commands/withdraw.rb#L7

When these commands are handled copies of them are written to an accountTransaction stream, using either `deposit_id` or `withdrawal_id` as the identifier for the stream, and using `write.initial` to ensure they are only written once:

https://github.com/eventide-examples/account-component/blob/master/lib/account_component/handlers/commands.rb#L62

That stream is processed by this handler, which contains the actual business logic for command processing: https://github.com/eventide-examples/account-component/blob/master/lib/account_component/handlers/commands/transactions.rb

We can reimplement the logic in the AccountComponent example by inlining the logic from the Transactions handler inside `reversation.(...)` calls in the command handler:

`lib/account_component/handlers/commands.rb`:

```ruby
      handle Deposit do |deposit|
        reservation.(deposit, :deposit_id) do
          account, version = store.fetch(account_id, include: :version)

          sequence = deposit.metadata.global_position

          if account.processed?(sequence)
            logger.info(tag: :ignored) { "Command ignored (Command: #{deposit.message_type}, Account ID: #{account_id}, Account Sequence: #{account.sequence}, Deposit Sequence: #{sequence})" }
            return
          end

          time = clock.iso8601

          deposited = Deposited.follow(deposit)
          deposited.processed_time = time
          deposited.sequence = sequence

          stream_name = stream_name(account_id)

          write.(deposited, stream_name, expected_version: version)
        end
      end

      handle Withdraw do |withdraw|
        reservation.(withdraw, :withdrawal_id) do
          account_id = withdraw.account_id

          account, version = store.fetch(account_id, include: :version)

          sequence = withdraw.metadata.global_position

          if account.processed?(sequence)
            logger.info(tag: :ignored) { "Command ignored (Command: #{withdraw.message_type}, Account ID: #{account_id}, Account Sequence: #{account.sequence}, Withdrawal Sequence: #{sequence})" }
            return
          end

          time = clock.iso8601

          stream_name = stream_name(account_id)

          unless account.sufficient_funds?(withdraw.amount)
            withdrawal_rejected = WithdrawalRejected.follow(withdraw)
            withdrawal_rejected.time = time
            withdrawal_rejected.sequence = sequence

            write.(withdrawal_rejected, stream_name, expected_version: version)

            return
          end

          withdrawn = Withdrawn.follow(withdraw)
          withdrawn.processed_time = time
          withdrawn.sequence = sequence

          write.(withdrawn, stream_name, expected_version: version)
        end
      end
```

The handler `AccountComponent::Handlers::Commands::Transactions` and the consumer that invokes it (`AccountComponent::Consumers::Commands::Transaction`) are no longer needed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hubbado-idempotence-reservation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hubbado-idempotence-reservation

## Usage

Use it inside a handler

```ruby
class SomeHandler
  dependency :reservation, Idempotence::Reservation

  def configure(session: nil)
    Idempotence::Reservation.configure(self, session: session)
  end

  handle SomeMessage do |some_message|
    reservation.(some_message, :some_idempotence_key) do
      # Handle reserved message
    end
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/hubbado/hubbado-idempotence-reservation.

## License

The `hubbado-idempotence` library is released under the [MIT License](https://opensource.org/licenses/MIT).
