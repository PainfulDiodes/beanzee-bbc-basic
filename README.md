# BBCZ80 for BeanZee

This is a fork of [R.T.Russell's BBCZ80](https://www.bbcbasic.co.uk/bbcbasic/z80basic.html) adapted to build with z88dk's assembler (z88dk-z80asm). See: [Building BBC BASIC Z80 with z88dk](./building-BBCZ80.md).

It is embedded within the [Marvin](https://github.com/PainfulDiodes/marvin) firmware for use on [BeanZee](https://github.com/PainfulDiodes/BeanZee), [BeanBoard](https://github.com/PainfulDiodes/BeanBoard) and BeanDeck.

# Divergence

Differences from the RT Russell source:

* .Z80 files are converted to .asm files changing assembler directives and expressions to be compatible with z88dk toolchain
* MAIN_SM_DISP.asm is an alternative to MAIN.asm with shorter messages for compatibility with smaller output devices

## [RT Russell BBCZ80](https://github.com/rtrussell/BBCZ80)

BBC BASIC (Z80) v5 is an implementation of the BBC BASIC programming language for the Z80 CPU.
It is largely compatible with Acorn's ARM BASIC V but with a few language extensions based on
features of 'BBC BASIC for Windows' and 'BBC BASIC for SDL 2.0'.  These extensions include the
EXIT statement, the address-of operator (^) and byte (unsigned 8-bit) variables and arrays
(& suffix character). [more...](https://github.com/rtrussell/BBCZ80)
