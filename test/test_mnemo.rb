#!/usr/bin/env ruby
require 'test/unit'
require 'dis8'

# Testing the Mnemo module.
class TestOpCode < Test::Unit::TestCase

  # The CLA microinstruction bit is presented in all three Operate
  # groups.  We must check all three.
  def test_cla
    assert_equal 'CLA', PDP8::Mnemo.mnemo(0b111_010_000_000)
    assert_equal 'CLA', PDP8::Mnemo.mnemo(0b111_110_000_000)
    assert_equal 'CLA', PDP8::Mnemo.mnemo(0b111_110_000_001)
  end

end
