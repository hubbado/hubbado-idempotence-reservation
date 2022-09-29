# Idempotence

Idempotence reservation stream pattern for eventide toolkit.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hubbado-idempotence'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hubbado-idempotence

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

`reservation` callable will check if the given message is reserved with metadata `reserved` and the process the 
block given. If metadata `reserved` does not exist then will reserve the message using a [compound ID](http://docs.eventide-project.org/glossary.html#compound-id).

E.g: Picks the message's stream name `someCategory:command-123` and the idempotence key `AAA` so the reserved message's stream name will be
`someCategory:command-123+AAA`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hubbado/idempotence.

## License

The `hubbado-idempotence` library is released under the [MIT License](https://opensource.org/licenses/MIT).
