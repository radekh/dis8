#!/usr/bin/env ruby
require 'test/unit'
require 'dis8'

class TC_Memory < Test::Unit::TestCase
  
  def test_rw
    memory = Memory.new
    memory[0] = 15
    assert_equal 15, memory[0]
  end

  def test_rim_loader
    memory = Memory.new
    memory.load_rim 'simple.rim'
    assert_equal 02525, memory[070]
    assert_equal 07000, memory[0]
    assert_equal 07402, memory[1]
  end
end



class TestAll
  def TestAll.suite
    suite = Test::Unit::TestSuite.new
    Object.constants.sort.each do |k|
      next if /^TC_/ !~ k
      constant = Object.const_get k
      if constant.kind_of?(Class) && constant.superclass == Test::Unit::TestCase
        suite << constant.suite
      end
    end
    suite
  end
end

if __FILE__ == $0
  require 'test/unit/ui/console/testrunner'
  Test::Unit::UI::Console::TestRunner.run(TestAll)
end
