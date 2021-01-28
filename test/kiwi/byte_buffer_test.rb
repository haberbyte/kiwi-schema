# frozen_string_literal: true

require "test_helper"

require "kiwi"

class Kiwi::ByteBufferTest < Minitest::Test
  def test_read_var_float
    assert_raises { read_var_float([]) }
    assert_equal read_var_float([0]), 0.0
    assert_equal read_var_float([133, 242, 210, 237]).round(3), 123.456
    assert_equal read_var_float([133, 243, 210, 237]).round(3), -123.456
    assert_equal read_var_float([254, 255, 255, 255]), -3.4028234663852886e+38
    assert_equal read_var_float([254, 254, 255, 255]), 3.4028234663852886e+38
    assert_equal read_var_float([1, 1, 0, 0]), -1.1754943508222875e-38
    assert_equal read_var_float([1, 0, 0, 0]), 1.1754943508222875e-38
    assert_equal read_var_float([255, 1, 0, 0]), -Float::INFINITY
    assert_equal read_var_float([255, 0, 0, 0]), Float::INFINITY
    assert read_var_float([255, 0, 0, 128]).nan?
  end

  def test_read_string
    assert_raises { read_string([]) }
    assert_equal read_string([0]), ""
    assert_raises { read_string([97]) }
    assert_equal read_string([97, 0]), "a"
    assert_equal read_string([97, 98, 99, 0]), "abc"
    assert_equal read_string([240, 159, 141, 149, 0]), "🍕"
    assert_equal read_string([97, 237, 160, 188, 99, 0]), "a\xED\xA0\xBCc" # "a���c"
  end

  def test_write_bool
    assert_equal write_once { |bb| bb.write_bool(false) }, [0]
    assert_equal write_once { |bb| bb.write_bool(true) }, [1]
  end

  def test_write_byte
    assert_equal write_once { |bb| bb.write_byte(0) }, [0]
    assert_equal write_once { |bb| bb.write_byte(1) }, [1]
    assert_equal write_once { |bb| bb.write_byte(254) }, [254]
    assert_equal write_once { |bb| bb.write_byte(255) }, [255]
  end

  def test_write_var_int
    assert_equal write_once { |bb| bb.write_var_int(0) }, [0]
    assert_equal write_once { |bb| bb.write_var_int(-1) }, [1]
    assert_equal write_once { |bb| bb.write_var_int(1) }, [2]
    assert_equal write_once { |bb| bb.write_var_int(-2) }, [3]
    assert_equal write_once { |bb| bb.write_var_int(2) }, [4]
    assert_equal write_once { |bb| bb.write_var_int(-64) }, [127]
    assert_equal write_once { |bb| bb.write_var_int(64) }, [128, 1]
    assert_equal write_once { |bb| bb.write_var_int(128) }, [128, 2]
    assert_equal write_once { |bb| bb.write_var_int(-129) }, [129, 2]
    assert_equal write_once { |bb| bb.write_var_int(-65535) }, [253, 255, 7]
    assert_equal write_once { |bb| bb.write_var_int(65535) }, [254, 255, 7]
    assert_equal write_once { |bb| bb.write_var_int(-2147483647) }, [253, 255, 255, 255, 15]
    assert_equal write_once { |bb| bb.write_var_int(2147483647) }, [254, 255, 255, 255, 15]
    assert_equal write_once { |bb| bb.write_var_int(-2147483648) }, [255, 255, 255, 255, 15]
  end

  def test_write_var_uint
    assert_equal write_once { |bb| bb.write_var_uint(0) }, [0]
    assert_equal write_once { |bb| bb.write_var_uint(1) }, [1]
    assert_equal write_once { |bb| bb.write_var_uint(2) }, [2]
    assert_equal write_once { |bb| bb.write_var_uint(3) }, [3]
    assert_equal write_once { |bb| bb.write_var_uint(4) }, [4]
    assert_equal write_once { |bb| bb.write_var_uint(127) }, [127]
    assert_equal write_once { |bb| bb.write_var_uint(128) }, [128, 1]
    assert_equal write_once { |bb| bb.write_var_uint(256) }, [128, 2]
    assert_equal write_once { |bb| bb.write_var_uint(129) }, [129, 1]
    assert_equal write_once { |bb| bb.write_var_uint(257) }, [129, 2]
    assert_equal write_once { |bb| bb.write_var_uint(131069) }, [253, 255, 7]
    assert_equal write_once { |bb| bb.write_var_uint(131070) }, [254, 255, 7]
    assert_equal write_once { |bb| bb.write_var_uint(4294967293) }, [253, 255, 255, 255, 15]
    assert_equal write_once { |bb| bb.write_var_uint(4294967294) }, [254, 255, 255, 255, 15]
    assert_equal write_once { |bb| bb.write_var_uint(4294967295) }, [255, 255, 255, 255, 15]
  end

  def test_write_float
    assert_equal write_once { |bb| bb.write_var_float(0.0) }, [0]
    assert_equal write_once { |bb| bb.write_var_float(-0.0) }, [0]
    assert_equal write_once { |bb| bb.write_var_float(123.456) }, [133, 242, 210, 237]
    assert_equal write_once { |bb| bb.write_var_float(-123.456) }, [133, 243, 210, 237]
    assert_equal write_once { |bb| bb.write_var_float(-3.4028234663852886e+38) }, [254, 255, 255, 255]
    assert_equal write_once { |bb| bb.write_var_float(3.4028234663852886e+38) }, [254, 254, 255, 255]
    assert_equal write_once { |bb| bb.write_var_float(-1.1754943508222875e-38) }, [1, 1, 0, 0]
    assert_equal write_once { |bb| bb.write_var_float(1.1754943508222875e-38) }, [1, 0, 0, 0]
    assert_equal write_once { |bb| bb.write_var_float(-Float::INFINITY) }, [255, 1, 0, 0]
    assert_equal write_once { |bb| bb.write_var_float(Float::INFINITY) }, [255, 0, 0, 0]
    assert_equal write_once { |bb| bb.write_var_float(Float::NAN) }, [255, 0, 0, 128]
    assert_equal write_once { |bb| bb.write_var_float(1.0e-40) }, [0]
  end

  def test_write_string
    assert_equal write_once { |bb| bb.write_string("") }, [0]
    assert_equal write_once { |bb| bb.write_string("a") }, [97, 0]
    assert_equal write_once { |bb| bb.write_string("abc") }, [97, 98, 99, 0]
    assert_equal write_once { |bb| bb.write_string("🍕") }, [240, 159, 141, 149, 0]
  end

  def test_write_sequence
    bb = Kiwi::ByteBuffer.new
    bb.write_var_float(0.0)
    bb.write_var_float(123.456)
    bb.write_string("🍕")
    bb.write_var_uint(123456789)
    assert_equal bb.data, [0, 133, 242, 210, 237, 240, 159, 141, 149, 0, 149, 154, 239, 58]
  end

  private
    def byte_buffer(bytes)
      Kiwi::ByteBuffer.new(bytes)
    end

    def write_once(&block)
      bb = Kiwi::ByteBuffer.new
      yield bb
      bb.data
    end

    def read_var_float(bytes)
      byte_buffer(bytes).read_var_float
    end

    def read_string(bytes)
      byte_buffer(bytes).read_string
    end
end
