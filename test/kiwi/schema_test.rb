# frozen_string_literal: true

require "test_helper"

require "kiwi"

class Kiwi::SchemaTest < Minitest::Test
  def setup
    @schema = Kiwi::Schema.new(defs: [
      Kiwi::Definition.new(name: "Enum", kind: Kiwi::Definition::KIND_ENUM, fields: [
        Kiwi::Field.new(name: "FOO", type_id: 0, is_array: false, value: 100),
        Kiwi::Field.new(name: "BAR", type_id: 0, is_array: false, value: 200)
      ]),

      Kiwi::Definition.new(name: "Struct", kind: Kiwi::Definition::KIND_STRUCT, fields: [
        Kiwi::Field.new(name: "v_enum", type_id: 0, is_array: true, value: 0),
        Kiwi::Field.new(name: "v_message", type_id: 2, is_array: false, value: 0)
      ]),

      Kiwi::Definition.new(name: "Message", kind: Kiwi::Definition::KIND_MESSAGE, fields: [
        Kiwi::Field.new(name: "v_enum", type_id: 0, is_array: true, value: 0),
        Kiwi::Field.new(name: "v_message", type_id: 2, is_array: false, value: 0),
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

  def test_from_binary
    schema_bytes = [1, 65, 66, 67, 0, 2, 1, 120, 121, 122, 0, 5, 1, 1]
    schema = Kiwi::Schema.from_binary(schema_bytes)
    definitions = schema.definitions

    assert_equal definitions.length, 1
    assert_equal definitions.first.name, "ABC"
    assert_equal definitions.first.kind, Kiwi::Definition::KIND_MESSAGE
    assert_equal definitions.first.fields.first.name, "xyz"
    assert_equal definitions.first.fields.first.type_id, Kiwi::Field::TYPE_INT
    assert_equal definitions.first.fields.first.is_array, true
    assert_equal definitions.first.fields.first.value, 1

    assert schema.respond_to?(:encode_abc)
    assert schema.respond_to?(:decode_abc)
  end

  def test_encode
    assert_equal @schema.encode(0, "FOO"), [100]
    assert_equal @schema.encode(0, "BAR"), [200, 1]
    assert_equal @schema.encode(Kiwi::Field::TYPE_BOOL, false), [0]
    assert_equal @schema.encode(Kiwi::Field::TYPE_BOOL, true), [1]
    assert_equal @schema.encode(Kiwi::Field::TYPE_BOOL, nil), [0]
    assert_equal @schema.encode(Kiwi::Field::TYPE_BYTE, 255), [255]
    assert_equal @schema.encode(Kiwi::Field::TYPE_INT, -1), [1]
    assert_equal @schema.encode(Kiwi::Field::TYPE_UINT, 1), [1]
    assert_equal @schema.encode(Kiwi::Field::TYPE_FLOAT, 0.5), [126, 0, 0, 0]
    assert_equal @schema.encode(Kiwi::Field::TYPE_STRING, "🍕"), [240, 159, 141, 149, 0]

    assert_equal @schema.encode(1, {
      "v_enum" => ["FOO", "BAR"],
      "v_message" => {
        "v_string" => "🍕"
      }
    }), [2, 100, 200, 1, 6, 240, 159, 141, 149, 0, 0]

    assert_equal @schema.encode(2, { "v_bool" => false }), [1, 0, 0]
    assert_equal @schema.encode(2, { "v_bool" => true }), [1, 1, 0]
    assert_equal @schema.encode(2, { "v_byte" => 255 }), [2, 255, 0]
    assert_equal @schema.encode(2, { "v_int" => -1 }), [3, 1, 0]
    assert_equal @schema.encode(2, { "v_uint" => 1 }), [4, 1, 0]
    assert_equal @schema.encode(2, { "v_float" => 0.0 }), [5, 0, 0]
    assert_equal @schema.encode(2, { "v_string" => "" }), [6, 0, 0]
    assert_equal @schema.encode(2, { "v_enum" => "FOO" }), [7, 100, 0]
    assert_equal @schema.encode(2, { "v_struct" => { "v_enum" => [], "v_message" => {} } }), [8, 0, 0, 0]
    assert_equal @schema.encode(2, { "v_message" => {} }), [9, 0, 0]

    assert_equal @schema.encode(2, { "a_struct" => [
      { "v_enum" => ["BAR"], "v_message" => {} },
      { "v_enum" => ["FOO"], "v_message" => {} }
    ] }), [17, 2, 1, 200, 1, 0, 1, 100, 0, 0]

    # Encode the same message with additional unknown field
    assert_equal @schema.encode(2, { "a_struct" => [
      { "v_enum" => ["BAR"], "v_message" => {} },
      { "v_enum" => ["FOO"], "v_message" => {} }
    ], "unkown" => "something" }), [17, 2, 1, 200, 1, 0, 1, 100, 0, 0]

    assert_equal @schema.encode(2, { "a_message" => [
      { "a_struct" => [
        { "v_enum" => ["BAR"], "v_message" => {} },
        { "v_enum" => ["FOO"], "v_message" => {} }
      ] }
    ] }), [18, 1, 17, 2, 1, 200, 1, 0, 1, 100, 0, 0, 0]
  end

  def test_decode
    assert_raises { @schema.decode(0, [0]) }
    assert_equal @schema.decode(0, [100]), "FOO"
    assert_equal @schema.decode(0, [200, 1]), "BAR"
    assert_equal @schema.decode(Kiwi::Field::TYPE_BOOL, [0]), false
    assert_equal @schema.decode(Kiwi::Field::TYPE_BOOL, [1]), true
    assert_equal @schema.decode(Kiwi::Field::TYPE_BOOL, [2]), false # maybe expect error?
    assert_equal @schema.decode(Kiwi::Field::TYPE_BYTE, [255]), 255
    assert_equal @schema.decode(Kiwi::Field::TYPE_INT, [1]), -1
    assert_equal @schema.decode(Kiwi::Field::TYPE_UINT, [1]), 1
    assert_equal @schema.decode(Kiwi::Field::TYPE_FLOAT, [126, 0, 0, 0]), 0.5
    assert_equal @schema.decode(Kiwi::Field::TYPE_STRING, [240, 159, 141, 149, 0]), "🍕"

    assert_equal @schema.decode(1, [2, 100, 200, 1, 6, 240, 159, 141, 149, 0, 0]), {
      "v_enum" => ["FOO", "BAR"],
      "v_message" => {
        "v_string" => "🍕"
      }
    }

    assert_equal @schema.decode(2, [1, 0, 0]), { "v_bool" => false }
    assert_equal @schema.decode(2, [1, 1, 0]), { "v_bool" => true }
    assert_equal @schema.decode(2, [2, 255, 0]), { "v_byte" => 255 }
    assert_equal @schema.decode(2, [3, 1, 0]), { "v_int" => -1 }
    assert_equal @schema.decode(2, [4, 1, 0]), { "v_uint" => 1 }
    assert_equal @schema.decode(2, [5, 0, 0]), { "v_float" => 0.0 }
    assert_equal @schema.decode(2, [6, 0, 0]), { "v_string" => "" }
    assert_equal @schema.decode(2, [7, 100, 0]), { "v_enum" => "FOO" }
    assert_equal @schema.decode(2, [8, 0, 0, 0]), { "v_struct" => { "v_enum" => [], "v_message" => {} } }
    assert_equal @schema.decode(2, [9, 0, 0]), { "v_message" => {} }
  end
end
