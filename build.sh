#!/bin/sh

rm -f ./bld/* ./obj/*

set -e
bldfail() {
	echo
	echo "Build failed"
	exit 1
}

echo "[TASK #1] Build 'qrses'"
echo

start=$(date +%s%N)

echo "[FASM]  src/core.asm  bld/qrses.o"
fasm src/core.asm bld/qrses.o > /dev/null || bldfail

end=$(date +%s%N)
elapsed=$(( (end - start) / 1000000 ))

echo
echo "[TASK #1] Finished in ${elapsed} ms"
echo "[TASK #2] Build 'qrses debug'"
echo

start=$(date +%s%N)

echo "[FASM]  dbg/entry.asm  obj/dbg_entry.o"
fasm dbg/entry.asm obj/dbg_entry.o > /dev/null || bldfail

echo "[FASM]  dbg/sys.asm    obj/dbg_sys.o"
fasm dbg/sys.asm obj/dbg_sys.o > /dev/null || bldfail

echo "[GCC]   dbg/main.c     obj/dbg_main.o"
gcc dbg/main.c -Os -nostdlib -static -s -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables -fomit-frame-pointer -fno-pic -fno-pie -Wl,--build-id=none -Wl,--gc-sections -Wl,-n -c -o obj/dbg_main.o > /dev/null || bldfail

echo "[LD]    *              bld/debug"
ld -e _entry obj/dbg_entry.o bld/qrses.o obj/dbg_sys.o obj/dbg_main.o -o bld/debug > /dev/null || bldfail

end=$(date +%s%N)
elapsed=$(( (end - start) / 1000000 ))

echo
echo "[TASK #2] Finished in ${elapsed} ms"
echo "No tasks left to run."
