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
      false                     # FIXME: not yet implemented
    end

  end

end
