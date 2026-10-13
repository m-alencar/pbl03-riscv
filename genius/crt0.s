# crt0.s — inicializacao minima (o Ripes faz isso sozinho; no nosso SoC
# precisamos setar o ponteiro de pilha antes de entrar no main).
# sp = 0x3FF0 (topo da memoria de dados de 16 KB, alinhado)
.text
.globl _start
_start:
    lui  sp, 0x4        # sp = 0x00004000
    addi sp, sp, -16    # sp = 0x00003FF0
# (cai direto no main, que e a primeira instrucao do genius_pbl02.s)
