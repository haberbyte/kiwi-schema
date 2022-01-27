# frozen_string_literal: true

module Kiwi
  class Schema
    def self.from_binary(bytes)
      defs = []
      bb = ByteBuffer.new(bytes)
      definition_count = bb.read_var_uint

      (0...definition_count).each do
        type_name = bb.read_string
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

        defs << Definition.new(name: type_name, kind: kind, fields: fields)
      end

      Kiwi::Schema.new(defs)
    end

    def initialize(definitions)
      @definitions = definitions
      instance_eval Compiler.compile(self)
    end

    def definitions
      @definitions
    end
  end
end
