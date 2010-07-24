#!/usr/bin/env ruby

module PDP8
  # This module bundles all the functions form getting mnemonic code
  # to given instruction word.
  module Mnemo

    # The main public method of the module Mnemo.  This is the one and
    # only method which may be called from outside of the module
    # Mnemo.
    def self.mnemo opcode
      # The PDP8 has an eight basic instruction or class of
      # instructions.  These are distinguished by the first three bits
      # of opcode word.

      case opcode >> 9
      when 7: opr opcode
      else
        '%0.4o' % opcode          # FIXME: not yet implemented
      end
    end
    
    private      # !!! All other methods are private to the module !!!

    # Old method.
    #
    # FIXME: remove
    def get_mnemo opcode
      case opcode >> 9
      when 0
        "AND %s %o\t/ %o" % [get_flags(opcode), opcode, opcode]
      when 1
        "TAD %s %o\t/ %o" % [get_flags(opcode), opcode, opcode]
      when 2
        "ISZ %s %o\t/ %o" % [get_flags(opcode), opcode, opcode]
      when 3
        "DCA %s %o\t/ %o" % [get_flags(opcode), opcode, opcode]
      when 4
        "JMS %s %o\t/ %o" % [get_flags(opcode), opcode, opcode]
      when 5
        "JMP %s %o\t/ %o" % [get_flags(opcode), opcode, opcode]
      when 7
        "%s\t/%o" % [get_oper(opcode), opcode]
      else
        sprintf "%o", opcode
      end
    end

    # Old Method
    #
    # FIXME:
    def get_flags opcode
      flags = ""
      flags += 'I' if opcode & 00400
      flags += 'Z' if (opcode & 00200) == 0
    end

    # Old Method
    #
    # FIXME:
    def get_rotate opcode
      [ '', 'BSW', 'RAL', 'RTL', 'RAR', 'RTR', 'err', 'err' ][(opcode >> 1) &07]
    end

    # Old Method
    #
    # FIXME:
    def decode_skip opcode
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

    # Old Method
    #
    # FIXME:
    def decode_eae opcode
      ' EAE'
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

    # Decoding Operate1 instruction class to get all instruction names
    # in it.
    def self.opr1 opcode
      m = ''                    # We begin with blank mnemo
      m += ' CLA' if opcode & 0200 == 0200
      m.lstrip                  # Return
    end

    def self.opr2 opcode
      # We begin with blank and add mnemo for each decode microinstruction.
      m = ''
      m += ' CLA' if opcode & 0200 == 0200
      m.lstrip                  # Return
    end

    def self.opr3 opcode
      # We begin with blank and add mnemo for each decode microinstruction.
      m = ''
      m += ' CLA' if opcode & 0200 == 0200
      m.lstrip                  # Return
    end

    # Old Method
    #
    # FIXME:
    def get_oper opcode
      if (opcode & 0400) == 0
        mnemo = ''
        mnemo += ' CLA' if opcode & 0200 == 0200
        mnemo += ' CLL' if opcode & 0100 == 0100
        mnemo += ' CMA' if opcode & 0040 == 0040
        mnemo += ' CML' if opcode & 0020 == 0020
        mnemo += ' '+get_rotate(opcode) if opcode & 0016
        mnemo += ' IAC' if opcode & 0001 == 0001
        mnemo = 'NOP' if mnemo.empty?
        mnemo.lstrip
      elsif (opcode & 0401) == 0400
        mnemo = ''
        mnemo += ' '+decode_skip(opcode) if opcode & 0170
        mnemo += ' CLA' if opcode & 0200 == 0200
        mnemo += ' OSR' if opcode & 0004 == 0004
        mnemo += ' HLT' if opcode & 0002 == 0002
        mnemo = 'NOP' if mnemo.empty?
        mnemo.lstrip
      elsif (opcode & 0401) == 0401
        mnemo = ''
        mnemo += ' CLA' if opcode & 0200 == 0200
        mnemo += ' MQA' if opcode & 0100 == 0100
        mnemo += ' SCA' if opcode & 0040 == 0040
        mnemo += ' MQL' if opcode & 0020 == 0020
        mnemo += ' '+decode_eae(opcode) if opcode & 0016
        mnemo = 'NOP' if mnemo.empty?
        mnemo.lstrip
      end
    end

  end

end
