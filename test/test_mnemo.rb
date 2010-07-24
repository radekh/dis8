#!/usr/bin/env ruby
require 'test/unit'
require 'dis8'

# Testing the Mnemo module.
class TestOpCode < Test::Unit::TestCase

  # The CLA microinstruction bit is presented in all three Operate
  # groups.  We must check all three.
  def test_cla
    assert_equal 'CLA', PDP8::Mnemo.mnemo(0, 0b111_010_000_000)
    assert_equal 'CLA', PDP8::Mnemo.mnemo(0, 0b111_110_000_000)
    assert_equal 'CLA', PDP8::Mnemo.mnemo(0, 0b111_110_000_001)
  end

  # Test the decoding mnemonic of RIF and acompaniing instructions
  # CIF, RDF, ...
  def test_rif_and_company
    assert_equal 'CDF 0' ,  PDP8::Mnemo.mnemo(0, 06201) # First
    assert_equal 'CDF 70' , PDP8::Mnemo.mnemo(0, 06271) # Last
    assert_equal 'CIF 0' ,  PDP8::Mnemo.mnemo(0, 06202) # First
    assert_equal 'CIF 70' , PDP8::Mnemo.mnemo(0, 06272) # Last

    assert_equal 'RDF' , PDP8::Mnemo.mnemo(0, 06214)
    assert_equal 'RIF' , PDP8::Mnemo.mnemo(0, 06224)
  end

  def test_tad
    assert_equal 'TAD 0074', PDP8::Mnemo.mnemo(0400, 01074)
    assert_equal 'TAD 0474', PDP8::Mnemo.mnemo(0400, 01274)
    assert_equal 'TAD I 0074', PDP8::Mnemo.mnemo(0400, 01474)
    assert_equal 'TAD I 0474', PDP8::Mnemo.mnemo(0400, 01674)
  end


  def test_compute_addr
    assert_equal 074,  PDP8::Mnemo.compute_addr(0400, 01074)
    assert_equal 0474, PDP8::Mnemo.compute_addr(0401, 01274)
  end

  def test_addr_modifiers
    assert_equal '', PDP8::Mnemo.addr_modifier(0b000_01_0_000_000)
    assert_equal ' I', PDP8::Mnemo.addr_modifier(0b000_11_0_000_000)
  end
end
