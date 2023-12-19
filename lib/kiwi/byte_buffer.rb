# frozen_string_literal: true

module Kiwi
  class ByteBuffer
    attr_reader :data
    attr_reader :index

    alias_method :bytes, :data

    def initialize(data = [])
      @data = data
      @index = 0
    end

    def read_byte
      if index >= data.length
        raise RangeError, "Index out of bounds"
      else
        value = data[index]
        @index += 1
        value
      end
    end

    def read_byte_array
      read_bytes(read_var_uint)
    end

    def read_bytes(len)
      if index + len > data.length
        raise RangeError, "Read bytes out of bounds"
      else
        value = data[index...(index + len)]
        @index += len
        value
      end
    end

    def read_bool
      read_byte == 0x1
    end

    def read_var_int
      value = read_var_uint

      if (value & 1) != 0
        ~(value >> 1)
      else
        value >> 1
      end
    end

    def read_var_uint
      shift = 0
      result = 0

      loop do
        byte = read_byte
        result |= (byte & 127) << shift
        shift += 7

        break if (byte & 128) == 0 || shift >= 35
      end

      result
    end

    def read_var_float
      first = read_byte
      return 0.0 if first == 0
      raise RangeError, "Index out of bounds" if index + 3 > data.length
      bits = first | (data[index] << 8) | (data[index + 1] << 16) | (data[index + 2] << 24)
      bits = (bits << 23) | (bits >> 9) # Move the exponent back into place
      value = [bits].pack("L").unpack("F*")[0]
      @index += 3
      value
    end

    def read_string
      result = []

      loop do
        char = read_byte
        break if char == 0
        result << char
      end

      result.pack("C*").force_encoding("UTF-8")
    end

    def write_bool(value)
      data.push(value ? 0x1 : 0x0)
    end

    def write_byte(value)
      data.push(value & 255)
    end

    def write_byte_array(value)
      write_var_uint(value.length)
      data.push(*value)
    end

    # Write a variable-length signed 32-bit integer to the end of the buffer.
    def write_var_int(value)
      write_var_uint((value << 1) ^ (value >> 31))
    end

    def write_var_uint(value)
      loop do
        byte = value & 127
        value = value >> 7

        if value == 0
          write_byte(byte)
          return
        end

        write_byte(byte | 128)
      end
    end

    def write_var_float(value)
      bits = [value].pack("F*").unpack("L")[0]
      bits = (bits >> 23) | (bits << 9)
      bytes = [bits].pack("L").unpack("C*")

      if (bytes[0] & 255) == 0
        data.push(0)
      else
        data.push(*bytes)
      end
    end

    def write_string(value)
      data.push(*value.bytes)
      data.push(0)
    end
  end
end
