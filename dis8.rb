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

  # Debug dump of the memory.dump_code
  def dump
    puts "Memory dump:"
    @content.each_index do |index|
      puts "%0.5d: %0.4d" % [index, @content[index]] unless @content[index].nil?
    end
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
        warn "An error ocurred while reading #{@conf}: #{e.inspect}"
      else
      end

      @code = Conf[:code]         # Hash of addresses marked as code
      @labels = Conf[:labels]     # Hash of labels {address => 'label'}
    end


    def run
      @memory.load_rim @file
      mark_code
      disasm_memory
      @memory.dump
      dump_code
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

        #DEBUG: puts ":Analyzing instruction at address %o: %s" % [addr, PDP8::Mnemo.mnemo(addr, opcode)]

        if OpCode.jmp? opcode then
          unless OpCode.indirect? opcode then
            next_addr = OpCode.compute_addr(addr, opcode) | field
            bag.store(next_addr, :code) unless @code.has_key? next_addr
            #DEBUG: puts ":IS JMP, adding %o" % [next_addr]
          end
        elsif OpCode.jms? opcode then
          next_addr = (addr+1) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          unless OpCode.indirect? opcode then
            next_addr = (OpCode.compute_addr(addr, opcode)+1) & 07777 | field
            bag.store(next_addr, :code) unless @code.has_key? next_addr
            #DEBUG: puts ":IS JMS, adding %o" % [next_addr]
          end
        elsif OpCode.conditional_skip? opcode then
          next_addr = (addr+1) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          next_addr = (addr+2) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          #DEBUG: puts ":IS Skip, adding %o" % [next_addr]
        elsif OpCode.hlt? opcode then
          #
        else
          next_addr = (addr+1) & 07777 | field
          bag.store(next_addr, :code) unless @code.has_key? next_addr
          #DEBUG: puts ":IS Normal, next %o" % [next_addr]
        end

        #DEBUG: puts "BAG.-delete: #{bag.inspect}"
        bag.delete(addr) # Remove analized instruction address from bag.
        #DEBUG: puts "BAG.end: #{bag.inspect}"
        #DEBUG: puts "CODE.end: #{@code.inspect}"
      end

    end

    # This method disassembles the whole program in memory.  During
    # disassembly it usess information gathered by mark_code method.
    def disasm_memory
      ptr = 0; field = 0
      last_ptr = nil
      while true
        adr = (field << 12) + ptr # Compute memory address
        if not @memory[adr].nil?
          if ptr-1 != last_ptr
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
          printf "%s\n", mnemo
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

      puts "\t$"          # End mark of the reconstructed source file.
    end

    # Dumping the debug hash for the debugging purposes.  Sometimes I
    # need to know what's going on.
    def dump_code
      puts "dump_code:"
      @code.each do |key,value|
        puts "%0.5o, #{value}" % key
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

  #DEBUG: puts "Disassembling file #{file}."
  dis = PDP8::Disasm.new :file => file, :conf => conf
  dis.run
end


if __FILE__ == $0
  main
end
