/*###############################################################
 #
 # Input and Output Group
 #
 ###############################################################
 #
 # NOTE: These instructions are sometimes weird to use, especially
 # when the z80 is the heart of the Amstrad CPC.
 # For instance on CPC the peripherals are in fact wired to the
 # Higher byte of the Address bus.
 # Hence when you write:
 #   OUT (C),A
 # It will in fact send the value in the Accumulator on the address
 # pointed by the register B (Higher byte of BC), even though B is
 # not explicitely given in the instruction.
 #
 # For that same reason the INI command is buggy on CPC, because
 # B would represent both the address of the peripheric and the
 # counter, which is not possible.
 #
 # IN A,(n)
 # IN r,(C)
 # IN F,(n)  or  IN (n)
 # INI
 # INIR
 # IND
 # INDR
 # OUT (n),A
 # OUT (C),r
 # OUT (C),0
 # OUTI
 # OTIR
 # OUTD
 # OTDR
 #
 ###############################################################*/

class InstrIO extends InstrWrap {
}