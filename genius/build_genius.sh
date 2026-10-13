#!/bin/bash
# Monta o Genius para o nosso nucleo (so precisa rodar se alterar o .s)
set -e
AS="riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -mno-relax"
SYM="--defsym LED_MATRIX_0_BASE=0xF0000000 --defsym SWITCHES_0_BASE=0xF0000100 --defsym D_PAD_0_UP=0xF0000200 --defsym RTC_0_BASE=0xF0000300"
$AS crt0.s -o crt0.o
$AS $SYM genius_pbl02.s -o genius.o
riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x0 -Tdata=0x2000 -o genius.elf crt0.o genius.o
riscv64-unknown-elf-objcopy -O binary -j .text genius.elf text.bin
riscv64-unknown-elf-objcopy -O binary -j .data genius.elf data.bin
python3 -I make_hex.py
riscv64-unknown-elf-objdump -d -M no-aliases genius.elf > genius.dis
riscv64-unknown-elf-nm genius.elf | sort > genius.sym
