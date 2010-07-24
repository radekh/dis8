#!/usr/bin/env ruby

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

    # Operate group 2 microinstruction is identified by 1 in bit 3 and
    # 0 in bit 11.
    def self.opr2? opcode
      opcode & 07401 == 07400
    end

    # Operate group 3 microinstruction is identified by 1 in bit 3 and
    # 1 in bit 11.
    def self.opr3? opcode
      opcode & 07401 == 07401
    end

    # Does the instruction modify pc in any way?  This is to detect
    # jump and skip instruction opcodes.
    def self.modify_pc? opcode
      true                     # FIXME: not yet implemented
    end

    def self.jmp? opcode
      opcode & 07000 == 05000
    end

    def self.jms? opcode
      opcode & 07000 == 04000
    end

    def self.isz? opcode
      opcode & 07000 == 02000
    end

    # Compute target address of instruction.
    def self.compute_addr addr,opcode
      if opcode & 0200 == 0200 then  # CP or ZP
        addr & 07600 | opcode & 0177 # Current Page
      else
        opcode & 0177           # Zero Page
      end
    end

    def self.indirect? opcode
      opcode & 04000 == 04000
    end

    def self.hlt? opcode
      opcode & 07402 == 07402
    end

    # Is this instruction from conditional skip class?  This is hard
    # to detect because of IOT instructions with skip ability.  For
    # the simplicity wi detect standard conditional skip instructions
    # like ISZ, SMA, SZA, SNL, SPA, SNA and SNL.  The conditional skip
    # instructions from IOT will be added one by one as found in
    # documentation of peripheral devices or in programs.
    def self.conditional_skip? opcode
      if isz?(opcode) then true
      elsif opr2?(opcode) && (opcode & 00170 != 0) then true
      #elsif 
      end
    end
  end

end
