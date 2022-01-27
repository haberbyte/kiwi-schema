# frozen_string_literal: true

module Kiwi
  class Field
    TYPE_BOOL = -1
    TYPE_BYTE = -2
    TYPE_INT = -3
    TYPE_UINT = -4
    TYPE_FLOAT = -5
    TYPE_STRING = -6

    attr_reader :name, :type_id, :is_array, :value

    def initialize(name:, type_id:, is_array:, value:)
      @name = name
      @type_id = type_id
      @is_array = is_array
      @value = value
    end

    def type
      @type_id
    end
  end
end
