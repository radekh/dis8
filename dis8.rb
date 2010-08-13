#!/usr/bin/env ruby
# Disassembler for PDP-8 programs.

# Extend the LOAD_PATH with the program directory.
$:.push File.dirname $0

require 'lib/dis8/memory'
require 'lib/dis8/mnemo'
require 'lib/dis8/opcode'


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
      @memory.load_bin @file
      mark_code
      disasm_memory
    end

    # This method marks all the memory cells which probably contains
    # code.
    def mark_code
      bag = @code; @code = {}

      #DEBUG: puts "Traverse bag: #{bag.inspect}"
      counter = 200             # DEBUG

      # Go through all code addresses in bag
      until bag.empty?
        counter -= 1; break if counter == 0 # DEBUG

        addr = bag.first[0]     # Take some address from bag
        if @code.has_key? addr  # Was that address already processed?
          bag.delete(addr)      # Yes
          next
        else                    # No, and its code address.
          @code.store(addr, :code)
        end

        # Parse adress and get the opcode.
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
