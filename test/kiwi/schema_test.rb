# frozen_string_literal: true

require "test_helper"

require "kiwi"

class Kiwi::SchemaTest < Minitest::Test
  def setup
    @schema = Kiwi::Schema.new([
      Kiwi::Definition.new(name: "Enum", kind: Kiwi::Definition::KIND_ENUM, fields: [
        Kiwi::Field.new(name: "FOO", type_id: 0, is_array: false, value: 100),
        Kiwi::Field.new(name: "BAR", type_id: 0, is_array: false, value: 200)
      ]),

      Kiwi::Definition.new(name: "Struct", kind: Kiwi::Definition::KIND_STRUCT, fields: [
        Kiwi::Field.new(name: "v_enum", type_id: 0, is_array: true, value: 0),
        Kiwi::Field.new(name: "v_message", type_id: 2, is_array: false, value: 0)
      ]),

      Kiwi::Definition.new(name: "Message", kind: Kiwi::Definition::KIND_MESSAGE, fields: [
        Kiwi::Field.new(name: "v_bool", type_id: Kiwi::Field::TYPE_BOOL, is_array: false, value: 1),
        Kiwi::Field.new(name: "v_byte", type_id: Kiwi::Field::TYPE_BYTE, is_array: false, value: 2),
        Kiwi::Field.new(name: "v_int", type_id: Kiwi::Field::TYPE_INT, is_array: false, value: 3),
        Kiwi::Field.new(name: "v_uint", type_id: Kiwi::Field::TYPE_UINT, is_array: false, value: 4),
        Kiwi::Field.new(name: "v_float", type_id: Kiwi::Field::TYPE_FLOAT, is_array: false, value: 5),
        Kiwi::Field.new(name: "v_string", type_id: Kiwi::Field::TYPE_STRING, is_array: false, value: 6),
        Kiwi::Field.new(name: "v_enum", type_id: 0, is_array: false, value: 7),
        Kiwi::Field.new(name: "v_struct", type_id: 1, is_array: false, value: 8),
        Kiwi::Field.new(name: "v_message", type_id: 2, is_array: false, value: 9),

        Kiwi::Field.new(name: "a_bool", type_id: Kiwi::Field::TYPE_BOOL, is_array: true, value: 10),
        Kiwi::Field.new(name: "a_byte", type_id: Kiwi::Field::TYPE_BYTE, is_array: true, value: 11),
        Kiwi::Field.new(name: "a_int", type_id: Kiwi::Field::TYPE_INT, is_array: true, value: 12),
        Kiwi::Field.new(name: "a_uint", type_id: Kiwi::Field::TYPE_UINT, is_array: true, value: 13),
        Kiwi::Field.new(name: "a_float", type_id: Kiwi::Field::TYPE_FLOAT, is_array: true, value: 14),
        Kiwi::Field.new(name: "a_string", type_id: Kiwi::Field::TYPE_STRING, is_array: true, value: 15),
        Kiwi::Field.new(name: "a_enum", type_id: 0, is_array: true, value: 16),
        Kiwi::Field.new(name: "a_struct", type_id: 1, is_array: true, value: 17),
        Kiwi::Field.new(name: "a_message", type_id: 2, is_array: true, value: 18),
      ])
    ])
  end

  def test_encode_order
    expected_bytes = [1, 1, 3, 246, 1, 0]

    assert_equal expected_bytes, @schema.encode_message({ "v_bool" => true, "v_int" => 123 }).bytes
    assert_equal expected_bytes, @schema.encode_message({ "v_int" => 123, "v_bool" => true }).bytes
  end

  def test_from_binary
    schema_bytes = [1, 65, 66, 67, 0, 2, 1, 120, 121, 122, 0, 5, 1, 1]
    schema = Kiwi::Schema.from_binary(schema_bytes)
    definitions = schema.definitions

    assert_equal 1, definitions.length
    assert_equal "ABC", definitions.first.name
    assert_equal Kiwi::Definition::KIND_MESSAGE, definitions.first.kind
    assert_equal "xyz", definitions.first.fields.first.name
    assert_equal Kiwi::Field::TYPE_INT, definitions.first.fields.first.type_id
    assert_equal true, definitions.first.fields.first.is_array
    assert_equal 1, definitions.first.fields.first.value

    assert schema.respond_to?(:encode_abc)
    assert schema.respond_to?(:decode_abc)
  end

  def test_encode
    assert_equal([2, 100, 200, 1, 6, 240, 159, 141, 149, 0, 0],
      @schema.encode_struct({
        "v_enum" => ["FOO", "BAR"],
        "v_message" => {
          "v_string" => "🍕"
        }
      }).bytes)

    assert_equal @schema.encode_message({ "v_bool" => false }).bytes, [1, 0, 0]
    assert_equal @schema.encode_message({ "v_bool" => true }).bytes, [1, 1, 0]
    assert_equal @schema.encode_message({ "v_byte" => 255 }).bytes, [2, 255, 0]
    assert_equal @schema.encode_message({ "v_int" => -1 }).bytes, [3, 1, 0]
    assert_equal @schema.encode_message({ "v_uint" => 1 }).bytes, [4, 1, 0]
    assert_equal @schema.encode_message({ "v_float" => 0.0 }).bytes, [5, 0, 0]
    assert_equal @schema.encode_message({ "v_string" => "" }).bytes, [6, 0, 0]
    assert_equal @schema.encode_message({ "v_enum" => "FOO" }).bytes, [7, 100, 0]
    assert_equal @schema.encode_message({ "v_struct" => { "v_enum" => [], "v_message" => {} } }).bytes, [8, 0, 0, 0]
    assert_equal @schema.encode_message({ "v_message" => {} }).bytes, [9, 0, 0]

    assert_equal @schema.encode_message({ "a_struct" => [
      { "v_enum" => ["BAR"], "v_message" => {} },
      { "v_enum" => ["FOO"], "v_message" => {} }
    ] }).bytes, [17, 2, 1, 200, 1, 0, 1, 100, 0, 0]

    # Encode the same message with additional unknown field
    assert_equal @schema.encode_message({ "a_struct" => [
      { "v_enum" => ["BAR"], "v_message" => {} },
      { "v_enum" => ["FOO"], "v_message" => {} }
    ], "unkown" => "something" }).bytes, [17, 2, 1, 200, 1, 0, 1, 100, 0, 0]

    assert_equal @schema.encode_message({ "a_message" => [
      { "a_struct" => [
        { "v_enum" => ["BAR"], "v_message" => {} },
        { "v_enum" => ["FOO"], "v_message" => {} }
      ] }
    ] }).bytes, [18, 1, 17, 2, 1, 200, 1, 0, 1, 100, 0, 0, 0]
  end

  def test_decode
    assert_raises { @schema.decode_enum([0]) }

    assert_equal({ "v_enum" => ["FOO", "BAR"], "v_message" => { "v_string" => "🍕" } }, @schema.decode_struct(Kiwi::ByteBuffer.new([2, 100, 200, 1, 6, 240, 159, 141, 149, 0, 0])))
    assert_equal({ "v_bool" => false }, @schema.decode_message(Kiwi::ByteBuffer.new([1, 0, 0])))
    assert_equal({ "v_bool" => true }, @schema.decode_message(Kiwi::ByteBuffer.new([1, 1, 0])))
    assert_equal({ "v_byte" => 255 }, @schema.decode_message(Kiwi::ByteBuffer.new([2, 255, 0])))
    assert_equal({ "v_int" => -1 }, @schema.decode_message(Kiwi::ByteBuffer.new([3, 1, 0])))
    assert_equal({ "v_uint" => 1 }, @schema.decode_message(Kiwi::ByteBuffer.new([4, 1, 0])))
    assert_equal({ "v_float" => 0.0 }, @schema.decode_message(Kiwi::ByteBuffer.new([5, 0, 0])))
    assert_equal({ "v_string" => "" }, @schema.decode_message(Kiwi::ByteBuffer.new([6, 0, 0])))
    assert_equal({ "v_enum" => "FOO" }, @schema.decode_message(Kiwi::ByteBuffer.new([7, 100, 0])))
    assert_equal({ "v_struct" => { "v_enum" => [], "v_message" => {} } }, @schema.decode_message(Kiwi::ByteBuffer.new([8, 0, 0, 0])))
    assert_equal({ "v_message" => {} }, @schema.decode_message(Kiwi::ByteBuffer.new([9, 0, 0])))
  end
end
