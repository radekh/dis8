#!/usr/bin/env ruby
# File: lib/dis8/mnemo.rb
# Copyright (c) 2010 by Radek Hnilica

module PDP8

  # This module bundles all the functions form getting mnemonic code
  # to given instruction word.
  module Mnemo

    # The main public method of the module Mnemo.  This is the one and
    # only method which may be called from outside of the module
    # Mnemo.
    def self.mnemo addr, opcode
      # The PDP8 has an eight basic instruction or class of
      # instructions.  These are distinguished by the first three bits
      # of opcode word.

      case opcode >> 9
      when 0: 'AND%s %0.4o' % [addr_modifier(opcode), compute_addr(addr, opcode)]
      when 1: 'TAD%s %0.4o' % [addr_modifier(opcode), compute_addr(addr, opcode)]
      when 2: 'ISZ%s %0.4o' % [addr_modifier(opcode), compute_addr(addr, opcode)]
      when 3: 'DCA%s %0.4o' % [addr_modifier(opcode), compute_addr(addr, opcode)]
      when 4: 'JMS%s %0.4o' % [addr_modifier(opcode), compute_addr(addr, opcode)]
      when 5: 'JMP%s %0.4o' % [addr_modifier(opcode), compute_addr(addr, opcode)]
      when 6: iot opcode
      when 7: opr opcode
      end
    end
    
    private      # !!! All other methods are private to the module !!!

    def self.addr_modifier opcode
      if opcode & 00400 == 00400 then ' I'
      else ''
      end
    end

    def self.compute_addr addr, opcode
      OpCode.compute_addr addr, opcode
    end

    # Decoding Operate class instruction 111 xxx xxx xxx.
    def self.opr opcode
      if OpCode.opr1? opcode
        opr1 opcode 
      elsif OpCode.opr2? opcode
        opr2 opcode
      elsif OpCode.opr3? opcode
        opr3 opcode
      end
    end

    # Decoding Operate Group 1 instruction class to get all instruction names
    # in it.  We have to follow the decoding sequence which is
    # * CLA, CLL
    # * CMA, CML
    # * IAC
    # * Rotate
    def self.opr1 opcode
      m = ''                    # We begin with blank mnemo
      m += ' CLA' if opcode & 0200 == 0200
      m += ' CLL' if opcode & 0100 == 0100
      m += ' CMA' if opcode & 0040 == 0040
      m += ' CML' if opcode & 0020 == 0020
      m += ' IAC' if opcode & 0001 == 0001
      m += ' '+rotate(opcode) if opcode & 0016 != 0
      m = 'NOP' if m.empty?
      m.strip                  # Return
    end

    # Decoding Rotate microinstruction in Operate Group 1.
    def rotate opcode
      [ '', 'BSW', 'RAL', 'RTL', 'RAR', 'RTR', 'err', 'err' ][(opcode >> 1) &07]
    end

    def self.opr2 opcode
      # We begin with blank and add mnemo for each decode microinstruction.
      m = ''
      m += ' CLA' if opcode & 0200 == 0200
      m += ' '+skip(opcode) if opcode & 0170
      m += ' OSR' if opcode & 0004 == 0004
      m += ' HLT' if opcode & 0002 == 0002
      m = 'NOP' if m.empty?
      m.strip                  # Return
    end

    def self.skip opcode
      mnemo = ''
      if (opcode & 010) == 0
        mnemo += ' SMA' if opcode & 0100 == 0100
        mnemo += ' SZA' if opcode & 0040 == 0040
        mnemo += ' SNL' if opcode & 0020 == 0020
      else
        mnemo += ' SPA' if opcode & 0100 == 0100
        mnemo += ' SNA' if opcode & 0040 == 0040
        mnemo += ' SZL' if opcode & 0020 == 0020
      end
      mnemo
    end

    def self.opr3 opcode
      # We begin with blank and add mnemo for each decode microinstruction.
      m = ''
      m += ' CLA' if opcode & 0200 == 0200
      m += ' MQA' if opcode & 0100 == 0100
      m += ' SCA' if opcode & 0040 == 0040
      m += ' MQL' if opcode & 0020 == 0020
      m += ' '+eae(opcode) if opcode & 0016 != 0
      m = 'NOP' if m.empty?
      m.strip                  # Return
    end

    def self.eae opcode
      ' EAE'
    end


    # Old Method
    #
    # FIXME:
    def get_oper opcode
      if (opcode & 0400) == 0
      elsif (opcode & 0401) == 0400
        mnemo = ''
      elsif (opcode & 0401) == 0401
      end
    end

    # Decoding IOT class instruction 110 xxx xxx xxx to get the
    # propper mnemonic.
    def self.iot opcode
      if opcode & 06200 == 06200
        mmu opcode
      else
        'IOT %0.4o' % opcode
      end
    end

    # Decoding MMU opcodes from 06200 to 06277.
    def self.mmu opcode
      if    opcode == 06214 then 'RDF'
      elsif opcode == 06224 then 'RIF'
      elsif opcode & 06207 == 06201 then 'CDF %o' % [opcode & 070]
      elsif opcode & 06207 == 06202 then 'CIF %o' % [opcode & 070]
      else
        'IOT %0.4o' % opcode
      end
    end
  end

end
