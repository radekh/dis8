#!/usr/bin/env ruby
# Disassembler for PDP-8 programs.

require 'lib/dis8/mnemo'
require 'lib/dis8/opcode'

# This is memory blok.
class Memory
  def initialize
    @content = Array.new(0100000)
  end

  # Memory cell modifier (writter)
  def []= address, value
    @content[address] = value
  end

  # Memory cell accessor (reader)
  def [] address
    @content[address]
  end

  # Load the given RIM file into @ram.
  def load_rim file
    loader = RIMLoader.new file
    loader.load @content
  end
end

# BIN/RIM paper tape loader.
class RIMLoader
  def initialize filename
    @filename = filename
  end

  def load memory
    byte = 0; word = 0; origin = 0; field = 0
    File.open @filename do |f|
      # Skip till LEADER mark (0b 1000 000)
      byte = 0200
      while byte == 0200
        byte = f.readchar
      end

      # In 'endless' loop we interpret data on the paper tape.
      while true
        #DEBUG:puts ":BYTE=#{byte}, #{byte >> 6}"
        case byte >> 6
        when 0b00               # DATA
          word = (byte << 6) | f.readchar
          #DEBUG:puts ":WORD=#{word}"
          #puts "#{(field << 12) + origin}: #{word}"
          #DEBUG:printf "%0.5o: %0.4o\n", (field << 12) + origin, word
          memory[(field << 12) + origin] = word
          origin = (origin +1) & 07777
        when 0b01               # ORIGIN
          origin = ((byte & 0b00_111_111) << 6) | f.readchar
          #DEBUG:printf ":ORIGIN = %0.4o\n", origin
        when 0b10               # TRAILER
          #DEBUG:printf ":TRAILER found %0.3o\n", byte
          break
        when 0b11               # FIELD SETTING
          #DEBUG:puts ":SET FIELD #{(byte & 070) >>3}"
          field = (byte & 070) >>3
        end
        byte = f.readchar
      end
    end
  end
end



# This class encapsulates all the procedures and functions working
# with OpCode.
class PDP8OpCode

  # Create new instance of OpCode from given machine word.
  def initialize opcode
    @opcode = opcode
  end

  # Is this opcode from OPR?
  def opr?
    (@opcode & 07000) == 07000
  end

  def opr1?
    (@opcode & 0b111_100_000_000) == 0b111_000_000_000
  end

  def opr2?
    (@opcode & 0b111_100_000_001) == 0b111_100_000_000
  end

  def opr3?
    (@opcode & 0b111_100_000_001) == 0b111_100_000_001
  end

  def skip?
    if opr2?
      @opcode & 0b000_001_111_000
    else
      false
    end
  end
end

# The PDP8 modules and classes are organized in the main PDP8 module.
# This is new program infrastructure and all code will be migrated
# there.
module PDP8

  # Functions which provide different kinds of informations about
  # given OpCode.  These are in its own separate module to don't
  # polish Disasm class.
  module OpCode

    # Bassic memory access instructions are four (AND, TAD, ISZ, and
    # DCA) with opcodes from 0000 to 3777.
    #
    # FIXME: find a better name
    def self.basic_memory_access? opcode
      0 <= opcode && opcode <= 03777
    end

    # There are eight basic instruction and/or instruction classes.
    # OPR class whose opcode begins with 7 is one of these.
    def self.opr? opcode
      opcode & 07000 == 07000
    end

    # Operate group 1 microinstruction is identified by 0 in bit 3.
    def self.opr1? opcode
      opcode & 07400 == 07000
    end

  end

  class Disasm

    def initialize params
      @memory = Memory.new
      @name = params[:name]
      @file = params[:file] || @name+'.bin'
      @conf = params[:conf] || @name+'.dis'
      load_config @conf
    end


    def load_config file
      # url=http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/86660
      begin
        eval File.new(@conf).read
      rescue ScriptError => e
        warn("An error ocurred while reading #{@conf}: ", e)
      else
      end

      @code = Conf[:code]         # Hash of addresses marked as code
      @labels = Conf[:labels]     # Hash of labels {address => 'label'}
    end


    def run
      @memory.load_rim @file
      mark_code
      disasm_memory
    end

    # This method marks all the memory cells which probably contains
    # code.
    def mark_code
      bag = @code.clone
      # Go through all bag
      puts "Traverse bag: #{bag.inspect}"

      until bag.empty?
        adr = bag.first[0]      # Take some address from bag
        opcode = @memory[adr]
        #DEBUG: puts "INSPECTING: %o at address %o (%d)" % [opcode, adr, adr]
        if regular_instruction? opcode # If its regular, mark next address.
          #DEBUG: puts ":IS REGULAR, adding %o (%d)" % [adr+1, adr+1]
          bag.store(adr+1, :code)
          @code.store(adr+1, :code)
          #DEBUG: puts "BAG.next: #{bag.inspect}"
        end

        #DEBUG: puts "BAG.-delete: #{bag.inspect}"
        bag.delete(adr)
        #DEBUG: puts "BAG.end: #{bag.inspect}"
        #DEBUG: puts "CODE.end: #{@code.inspect}"
      end

    end

    def disasm_memory
      ptr = 0; field = 0
      last_ptr = nil
      while true
        adr = (field << 12) + ptr # Compute memory address
        if not @memory[adr].nil?
          if ptr-1 != last_ptr
            printf "\n"
            printf "\t*%o\n", ptr
          end

          # Is this address labeled?
          label = @labels[adr]    # String or Nil
          if label.nil?
            printf "\t"
          else
            printf "%s,\t", label
          end

          # Is this word code?
          if @code.has_key? adr
            #mnemo = get_mnemo @memory[adr]
            mnemo = Mnemo.mnemo @memory[adr]
          else
            mnemo = "DW %d" % @memory[adr]
          end
          printf "%s\t\t/%0.4o\n", mnemo, @memory[adr]
          last_ptr = ptr
        end

        break if ptr == 07777 && field == 7
        # Advance pointers
        ptr += 1
        if ptr > 07777
          ptr &= 07777
          field += 1
        end
      end
    end

    # Check if the given opcode is regular instruction which do not change PC.
    def regular_instruction? opcode
      oc = PDP8OpCode.new opcode
      if (opcode & 04000) == 0    # is AND,TAD,DCA,ISZ?
        true
      elsif oc.opr?
        if oc.opr1?
          true
        end
      end
    end
  end

end


# For the simplicity we recognize only one parameter, the name of the
# bin file.
def main
  name = ARGV[0]
  file = name + ".bin"
  conf = name + ".dis"

  puts "Disassembling file #{file}."
  dis = PDP8::Disasm.new :file => file, :conf => conf
  dis.run
end


if __FILE__ == $0
  main
end
