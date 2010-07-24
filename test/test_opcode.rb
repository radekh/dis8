#!/usr/bin/env ruby
require 'test/unit'
require 'dis8'
class TestOpCode < Test::Unit::TestCase

  def test_opr?
    assert PDP8::OpCode.opr? 0b111_000_000_000
    assert PDP8::OpCode.opr? 0b111_110_000_000
  end

  def test_basic_memory_access?
    assert PDP8::OpCode.basic_memory_access? 0b000_000_000_000
    assert PDP8::OpCode.basic_memory_access? 0b011_111_111_111
  end
end
