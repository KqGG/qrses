# Dependencies
- Working linux machine
- GCC
- FASM
- Any shell ( Preferably BASH )
# Build
You can build the library along with the debug/exemplary program by running `build.sh`.  
This project consists of only one source file, so you can also build it by running:  
`fasm src/core.asm bld/qrses.o`
# Usage
Simply link it with some C code using your favourite linker ( Not tested with anything other than the GNU one ).  
# Disclaimers
1. None of this is really documented, I mean the source has comments but otherwise you're on your own.
2. Uses raw Linux systemcalls, so it wont work on any other operating systems.
3. No color support (yet), and the whole thing is still in development.
