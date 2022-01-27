# kiwi-schema GEM

Kiwi is a schema-based binary format for efficiently encoding trees of data.

This is a ruby implementation of the kiwi message format, see [evanw/kiwi](https://github.com/evanw/kiwi/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kiwi-schema'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install kiwi-schema

## Usage

```ruby
require "kiwi"

# This is the encoding of the Kiwi schema "message ABC { int[] xyz = 1; }"
schema_bytes = [1, 65, 66, 67, 0, 2, 1, 120, 121, 122, 0, 5, 1, 1]
schema = Kiwi::Schema.from_binary(schema_bytes)
schema.encode_abc({ "xyz" => [99, -12] }).bytes # => [1, 2, 198, 1, 23, 0]
schema.decode_abc(Kiwi::ByteBuffer.new([1, 2, 198, 1, 23, 0]))  # => {"xyz"=>[99, -12]}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/haberbyte/kiwi-schema.

