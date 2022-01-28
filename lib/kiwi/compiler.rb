# frozen_string_literal: true

module Kiwi
  module Compiler
    def self.compile(schema)
      definitions = {}
      rb = []

      schema.definitions.each_with_index do |definition, index|
        definitions[index] = definition
      end

      schema.definitions.each do |definition|
        case definition.kind
        when Definition::KIND_ENUM
          rb << "#{definition.name} = {"
          definition.fields.each do |field|
            rb << "  '#{field.name}' => #{field.value},"
            rb << "  #{field.value} => '#{field.name}',"
          end
          rb << "}.freeze"
          rb << ""
        when Definition::KIND_STRUCT, Definition::KIND_MESSAGE
          rb << "def decode_#{definition.name.downcase}(bb)"
          rb << compile_decode(definition, definitions)
          rb << "end"
          rb << ""
          rb << "def encode_#{definition.name.downcase}(message, bb = Kiwi::ByteBuffer.new)"
          rb << compile_encode(definition, definitions)
          rb << "end"
          rb << ""
        else
          raise "Invalid definition kind: #{definition.kind}"
        end
      end

      rb.join("\n")
    end

    def self.compile_decode(definition, definitions)
      lines = []
      indent = "  "

      lines << "  result = {}"

      if definition.kind == Definition::KIND_MESSAGE
        lines << "  loop do"
        lines << "    case bb.read_var_uint"
        lines << "    when 0"
        lines << "      return result"
        indent = "    "
      end

      definition.fields.each do |field|
        code = ""

        case field.type_id
        when Field::TYPE_BOOL
          code = "bb.read_bool"
        when Field::TYPE_BYTE
          code = "bb.read_byte"
        when Field::TYPE_INT
          code = "bb.read_var_int"
        when Field::TYPE_UINT
          code = "bb.read_var_uint"
        when Field::TYPE_FLOAT
          code = "bb.read_var_float"
        when Field::TYPE_STRING
          code = "bb.read_string"
        else
          type = definitions[field.type]
 
          if (!type)
            raise "Invalid field type: #{field.type} for field #{field.name}"
          elsif type.kind == Definition::KIND_ENUM
            code = "#{type.name}[bb.read_var_uint]"
          else
            code = "decode_#{type.name.downcase}(bb)"
          end
        end

        if definition.kind == Definition::KIND_MESSAGE
          lines << "    when #{field.value}"
        end

        if field.is_array
          if field.type_id == Field::TYPE_BYTE
            lines << indent + "  result['#{field.name}'] = bb.read_byte_array"
          else
            lines << indent + "  length = bb.read_var_uint"
            lines << indent + "  values = result['#{field.name}'] = Array.new(length)"
            lines << indent + "  length.times { |i| values[i] = #{code} }"
          end
        else
          lines << indent + "  result['#{field.name}'] = #{code}"
        end
      end

      if definition.kind == Definition::KIND_MESSAGE
        lines << "    else"
        lines << "      raise RuntimeError, 'Attempted to parse invalid message'"
        lines << "    end"
        lines << "  end"
      else
        lines << "  return result"
      end

      lines.join("\n")
    end

    def self.compile_encode(definition, definitions)
      lines = []

      definition.fields.each do |field|
        code = ""

        case field.type_id
        when Field::TYPE_BOOL
          code = "bb.write_bool(value)"
        when Field::TYPE_BYTE
          code = "bb.write_byte(value)"
        when Field::TYPE_INT
          code = "bb.write_var_int(value)"
        when Field::TYPE_UINT
          code = "bb.write_var_uint(value)"
        when Field::TYPE_FLOAT
          code = "bb.write_var_float(value)"
        when Field::TYPE_STRING
          code = "bb.write_string(value)"
        else
          type = definitions[field.type]
 
          if (!type)
            raise "Invalid field type: #{field.type} for field #{field.name}"
          elsif type.kind == Definition::KIND_ENUM
            code = <<~CODE
              encoded = #{type.name}[value]
              raise "Invalid value for enum #{type.name}" if !encoded
              bb.write_var_uint(encoded)
            CODE
          else
            code = "encode_#{type.name.downcase}(value, bb)"
          end
        end

        lines << "  value = message['#{field.name}']"
        lines << "  if !value.nil?"

        if definition.kind == Definition::KIND_MESSAGE
          lines << "    bb.write_var_uint(#{field.value})"
        end

        if field.is_array
          if field.type_id == Field::TYPE_BYTE
            lines << "    bb.write_byte_array(value)"
          else
            lines << "    bb.write_var_uint(value.length)"
            lines << "    value.each do |value|"
            lines << "      #{code}"
            lines << "    end"
          end
        else
          lines << "    #{code}"
        end

        if definition.kind == Definition::KIND_STRUCT
          lines << "  else"
          lines << "    raise \"Missing required field: #{field.name}\""
        end

        lines << "  end"
        lines << ""
      end

      if definition.kind == Definition::KIND_MESSAGE
        lines << "  bb.write_var_uint(0)"
      end

      lines << ""
      lines << "  return bb"

      lines.join("\n")
    end
  end
end
