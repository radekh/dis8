#!/usr/bin/env ruby
# Disassembler for PDP-8 programs.

# Extend the LOAD_PATH with the program directory.
$:.push File.dirname $0

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
      bag = @code; @code = {}

      #DEBUG: puts "Traverse bag: #{bag.inspect}"
      counter = 100             # DEBUG

      # Go through all code addresses in bag
      until bag.empty?
        counter -= 1; break if counter == 0 # DEBUG

        addr = bag.first[0]     # Take some address from bag
        if @code.has_key? addr  # Was that address processed?
          bag.delete(addr)
          next
        else                    # This is code.
          @code.store(addr, :code)
        end

        field = addr & 070000
        a     = addr & 007777
        opcode = @memory[addr]

        #DENUG:
        puts ":Analyzing instruction at address %o: %s" % [addr, PDP8::Mnemo.mnemo(addr, opcode)]
        if OpCode.jmp? opcode then
          unless OpCode.indirect? opcode then
            next_addr = OpCode.compute_addr(addr, opcode) | field
            bag.store(next_addr, :code) unless @code.has_key? next_addr
            puts ":IS JMP, adding %o" % [next_addr]
          end
        elsif OpCode.jms? opcode then
          next_addr = (addr+1) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          unless OpCode.indirect? opcode then
            next_addr = (OpCode.compute_addr(addr, opcode)+1) & 07777 | field
            bag.store(next_addr, :code) unless @code.has_key? next_addr
            puts ":IS JMS, adding %o" % [next_addr]
          end
        elsif OpCode.skip_class? opcode then
          next_addr = (addr+1) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          next_addr = (addr+2) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          puts ":IS Skip, adding %o" % [next_addr]
        elsif OpCode.hlt? opcode then
          #
        else
          next_addr = (addr+1) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          puts ":IS Normal, next %o" % [next_addr]
        end

        #DEBUG: puts "BAG.-delete: #{bag.inspect}"
        bag.delete(addr) # Remove analized instruction address from bag.
        puts "BAG.end: #{bag.inspect}"
        #DEBUG:
        puts "CODE.end: #{@code.inspect}"
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
            mnemo = Mnemo.mnemo adr, @memory[adr]
          else
            mnemo = "DW %0.4o" % @memory[adr]
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
