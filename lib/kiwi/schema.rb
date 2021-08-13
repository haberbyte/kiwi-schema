# frozen_string_literal: true

module Kiwi
  class Schema
    def self.from_binary(bytes)
      defs = []
      bb = ByteBuffer.new(bytes)
      definition_count = bb.read_var_uint

      (0...definition_count).each do
        definition_name = bb.read_string
        kind = bb.read_byte
        field_count = bb.read_var_uint
        fields = []

        (0...(field_count)).each do |field|
          name = bb.read_string
          type_id = bb.read_var_int
          is_array = bb.read_bool
          value = bb.read_var_uint
          fields << Field.new(name: name, type_id: type_id, is_array: is_array, value: value)
        end

        defs << Definition.new(name: definition_name, kind: kind, fields: fields)
      end

      Kiwi::Schema.new(defs: defs)
    end

    def initialize(defs: [])
      @defs = defs
      @def_name_to_index = {}

      @defs.each_with_index do |definition, i|
        definition.index = i
        @def_name_to_index[definition.name] = i

        if definition.kind == Definition::KIND_MESSAGE
          define_singleton_method(:"encode_#{definition.name.downcase}") do |message|
            encode(definition.index, message)
          end

          define_singleton_method(:"decode_#{definition.name.downcase}") do |bytes|
            decode(definition.index, bytes)
          end
        end
      end
    end

    def decode(type_id, bytes)
      decode_bb(type_id, ByteBuffer.new(bytes))
    end

    def encode(type_id, value)
      bb = ByteBuffer.new
      encode_bb(type_id, value, bb)
      bb.data
    end

    def definitions
      @defs
    end

    private

      attr_reader :defs, :def_name_to_index

      def decode_bb(type_id, byte_buffer)
        case type_id
        when Field::TYPE_BOOL
          byte_buffer.read_bool
        when Field::TYPE_BYTE
          byte_buffer.read_byte
        when Field::TYPE_INT
          byte_buffer.read_var_int
        when Field::TYPE_UINT
          byte_buffer.read_var_uint
        when Field::TYPE_FLOAT
          byte_buffer.read_var_float
        when Field::TYPE_STRING
          byte_buffer.read_string
        else
          definition = defs[type_id]

          case definition.kind
          when Definition::KIND_ENUM
            if index = definition.field_value_to_index[byte_buffer.read_var_uint]
              definition.fields[index].name
            else
              raise RuntimeError
            end
          when Definition::KIND_STRUCT
            fields = {}
            definition.fields.each do |field|
              fields[field.name] = decode_field(field, byte_buffer)
            end
            fields
          when Definition::KIND_MESSAGE
            fields = {}
            loop do
              value = byte_buffer.read_var_uint
              return fields if value == 0

              if index = definition.field_value_to_index[value]
                field = definition.fields[index]
                fields[field.name] = decode_field(field, byte_buffer)
              else
                raise RuntimeError
              end
            end
          end
        end
      end

      def decode_field(field, byte_buffer)
        if field.is_array
          len = byte_buffer.read_var_uint
          array = []
          (0...len).each do
            array << decode_bb(field.type_id, byte_buffer)
          end
          array
        else
          decode_bb(field.type_id, byte_buffer)
        end
      end

      def encode_bb(type_id, value, byte_buffer)
        case type_id
        when Field::TYPE_BOOL
          byte_buffer.write_bool(value)
        when Field::TYPE_BYTE
          byte_buffer.write_byte(value)
        when Field::TYPE_INT
          byte_buffer.write_var_int(value)
        when Field::TYPE_UINT
          byte_buffer.write_var_uint(value)
        when Field::TYPE_FLOAT
          byte_buffer.write_var_float(value)
        when Field::TYPE_STRING
          byte_buffer.write_string(value)
        else
          definition = defs[type_id]

          case definition.kind
          when Definition::KIND_ENUM
            enum = definition.field(value)
            byte_buffer.write_var_uint(enum.value)
          when Definition::KIND_STRUCT
            definition.fields.each do |field|
              if !(field_value = value[field.name]).nil?
                encode_value(field, field_value, byte_buffer)
              else
                raise ArgumentError, "missing required field #{field.name}"
              end
            end
          when Definition::KIND_MESSAGE
            definition.fields.each do |field|
              if !(field_value = value[field.name]).nil?
                byte_buffer.write_var_uint(field.value)
                encode_value(field, field_value, byte_buffer)
              end
            end
            byte_buffer.write_byte(0)
          end
        end
      end

      def encode_value(field, value, byte_buffer)
        if field.is_array
          byte_buffer.write_var_uint(value.length)
          value.each { |v| encode_bb(field.type_id, v, byte_buffer) }
        else
          encode_bb(field.type_id, value, byte_buffer)
        end
      end
  end
end
