#!/usr/bin/env ruby
require 'test/unit'
require 'dis8'
class TestOpCode < Test::Unit::TestCase

  def test_opr?
    assert PDP8::OpCode.opr? 0b111_000_000_000
    assert PDP8::OpCode.opr? 0b111_110_000_000
  end
end
