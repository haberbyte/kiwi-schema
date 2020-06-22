# frozen_string_literal: true

module Kiwi
  class Definition
    KIND_ENUM = 0
    KIND_STRUCT = 1
    KIND_MESSAGE = 2

    attr_accessor :name, :index, :kind, :fields
    attr_reader :field_value_to_index, :field_name_to_index

    def initialize(name:, kind:, fields: [])
      @name = name
      @kind = kind
      @fields = fields
      @index = 0
      @field_name_to_index = {}
      @field_value_to_index = {}

      @fields.each_with_index do |field, i|
        field_value_to_index[field.value] = i
        field_name_to_index[field.name] = i
      end
    end

    def field(name)
      if idx = field_name_to_index[name]
        fields[idx]
      else
        nil
      end
    end
  end
end
