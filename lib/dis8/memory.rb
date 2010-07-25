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
    def load_rim filename
      byte = 0; word = 0; origin = 0; field = 0
      File.open filename do |f|
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
            @content[(field << 12) + origin] = word
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

    # Debug dump of the memory.dump_code
    def dump
      puts "Memory dump:"
      @content.each_index do |index|
        puts "%0.5d: %0.4o" % [index, @content[index]] unless @content[index].nil?
      end
    end
  end
end
