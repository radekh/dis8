#!/usr/bin/env ruby
require 'test/unit'
require 'dis8'
class TestOpCode < Test::Unit::TestCase

  def test_opr?
    assert PDP8::OpCode.opr? 0b111_000_000_000
    assert PDP8::OpCode.opr? 0b111_110_000_000
    # Operate Group 1, 2 and 3
    assert PDP8::OpCode.opr1? 0b111_010_000_001 # CLA IAC
    assert PDP8::OpCode.opr2? 0b111_100_001_000 # SKP
    assert PDP8::OpCode.opr3? 0b111_101_000_001 # MQA
  end

  def test_basic_memory_access?
    assert PDP8::OpCode.basic_memory_access? 0b000_000_000_000
    assert PDP8::OpCode.basic_memory_access? 0b011_111_111_111
  end

  # Detection of conditional skip instructions.
  def test_conditional_skip?
    assert PDP8::OpCode.conditional_skip? 02777 # ISZ
    assert PDP8::OpCode.conditional_skip? 07700 # CLA SMA
    assert PDP8::OpCode.conditional_skip? 07430 # SZL
    assert PDP8::OpCode.conditional_skip? 07560 # SMA SZA SNL
  end
end
