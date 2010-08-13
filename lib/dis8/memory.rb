#!/usr/bin/env ruby
# File: lib/dis8/memory.rb
# Copyright (c) 2010 by Radek Hnilica


module PDP8

  # Class implementing PDP8 memory block for the purpose of
  # disassembler.  The memory has the maximum size of 32k words
  # divided into 8 fields each having 4k words.  Words are 12 bits in
  # size.

  class Memory

    # Create and initialize the memory.  Memory has size 32k Words, in
    # octal its 100000 words.  All these words have initial value of
    # *nil*.
    def initialize
      @content = Array.new(0100000)
    end

    # The memory writter.  Method which is used for writing to memory.
    def []= address, value
      @content[address] = value
    end

    # The memory reader.  Method used for reading of the memory.
    def [] address
      @content[address]
    end

    # The PDP-8 binary files are in few formats.  One of them is BIN
    # paper tape format.  This format is described in
    # http://www.hnilica.cz/radek/book/electronic/pdp8.bin.html
    def load_bin filename
      hibyte = 0                # Upper, actual byte, under read head.
      lobyte = 0                # Lower byte of the word.
      word = 0                  # Readed word.
      origin = 0                # Origin, memory pointer (0o OOOO)
      field = 0                 # Actual field in form (0o F0000)
      checksum = 0

      File.open filename do |f|

        # Tape must begin with LEADER marks (0b 1000 000).  We must
        # skip all these, and read first byte before entering the main
        # reading loop.
        hibyte = 0200
        hibyte = f.readchar while hibyte == 0200

        # In 'endless' loop we interpret data on the paper tape.
        while true

          # We look into the byte and decide what is on the tape now.
          case hibyte >> 6

          when 0b00 # DATA, next byte contains lower 6 bits of the word.
            lobyte = f.readchar
            word = (hibyte << 6) | lobyte
            sum = lobyte + hibyte
            # Read the next byte because we need to know if it's
            # TRAILER or not.
            hibyte = f.readchar
            if hibyte != 0200 then
              @content[field | origin] = word
              origin = (origin +1) & 07777 # Advance origin by one.
              checksum += sum
            end
            next

          when 0b01 # ORIGIN, next byte contains lower 6 bits of origin.
            lobyte = f.readchar
            origin = ((hibyte & 0o77) << 6) | lobyte
            checksum += hibyte + lobyte

          when 0b10             # TRAILER marks the end of tape.
            # Last word written to memory is checksum.  We must check
            # it and remove from memory.
            checksum &= 07777
            if checksum != word then
              puts "BIN loader checksum error: computer=%0.4o, on tape=%0.4o" % [checksum, word]
              exit
            end
            break

          when 0b11    # FIELD SETTING byte contains the filed number.
            field = (hibyte & 070) << 9
          end

          hibyte = f.readchar     # Read the next byte.
        end
      end

    end

    # Debug dump of the memory.dump_code
    def dump
      puts "Memory dump:"
      @content.each_index do |index|
        puts "%0.5d: %0.4o" % [index, @content[index]] unless @content[index].nil?
      end
    end
  end
end
