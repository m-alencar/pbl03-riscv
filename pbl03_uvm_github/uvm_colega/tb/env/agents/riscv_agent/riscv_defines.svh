`ifndef RISCV_DEFINES
`define RISCV_DEFINES

  `include "riscv_profile.svh"

  // Tamanho das memorias do modelo (mesmos valores da interface)
  `define RV_IMEM_WORDS   4096
  `define RV_DMEM_BYTES   4096

  // Programas aleatorios
  `define RV_DATA_BASE    512     // x31 = 0x200: base dos loads/stores do corpo
  `define RV_DUMP_OFFSET  512     // epilogo despeja x0..x29 em x31 + 512 + 4*i
  `define RV_MIN_BODY     20
  `define RV_MAX_BODY     100
  `define NO_OF_PROGRAMS  50

`endif
