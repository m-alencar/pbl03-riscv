//------------------------------------------------------------------------------
// Perfil de ISA do DUT que esta sendo verificado.
// Defina UM dos dois (o pacote de cada equipe ja vem com o certo):
//   RV_PROFILE_MARINA : 22 instrucoes, termina em ecall
//   RV_PROFILE_COLEGA : 19 instrucoes, termina em jal x0,0 (PC estacionado)
//------------------------------------------------------------------------------
`ifndef RISCV_PROFILE
`define RISCV_PROFILE
  `define RV_PROFILE_MARINA
`endif
