# ============================================================
# Genius em RISC-V Assembly — PBL02
# Programa completo, integrando as 9 sub-rotinas ja validadas
# isoladamente no Ripes.
#
# Convencao de registradores (fixa durante todo o programa):
#   s0  = base do seq_buffer
#   s1  = tamanho_seq
#   s2  = indice_replay
#   s3  = tamanho_max (8/16/32)
#   s4  = dificuldade (0/1/2)
#   s5  = velocidade (0=Lento/1=Rapido)
#   s6  = modo (0=Siga/1=Mando eu)
#   s7  = pontuacao
#   s8  = estado do LFSR
#   s9  = base do D-Pad (= endereco de D_PAD_0_UP; DOWN/LEFT/RIGHT
#         ficam em +0x4/+0x8/+0xc a partir dai)
#   s10 = base do Switches
#   s11 = base do LED Matrix
# ============================================================

.data
seq_buffer: .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
cores:      .word 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00

.text
main:
    li   s8, 0xA5
    li   s9, D_PAD_0_UP
    li   s10, SWITCHES_0_BASE
    li   s11, LED_MATRIX_0_BASE
    la   s0, seq_buffer

idle_wait:
    call ler_switches
    beqz a0, idle_wait

config_read:
    call calc_tamanho_max
    li   s1, 0
    li   s2, 0
    li   s7, 0
    bnez s6, nova_luz
    j    gera_seq

nova_luz:
    call ler_dpad_direcao
    beqz a0, nova_luz
    mv   a0, a1
    call guardar_luz
    j    mostra_seq

gera_seq:
    call lfsr_next
    call guardar_luz

mostra_seq:
    call exibir_sequencia
    li   s2, 0

espera_jogador:
    call ler_dpad_direcao
    beqz a0, espera_jogador

confere:
    call comparar_toque
    beqz a0, errou

acertou:
    call atualiza_placar
    addi s2, s2, 1
    bne  s2, s1, espera_jogador
    bge  s1, s3, game_over
    bnez s6, nova_luz
    j    gera_seq

errou:
    j game_over

game_over:
    mv   a0, s7
    li   a7, 1
    ecall
    j    idle_wait


lfsr_next:
    srli t0, s8, 7
    andi t0, t0, 1
    srli t1, s8, 5
    andi t1, t1, 1
    xor  t0, t0, t1
    srli t1, s8, 4
    andi t1, t1, 1
    xor  t0, t0, t1
    srli t1, s8, 3
    andi t1, t1, 1
    xor  t0, t0, t1
    slli s8, s8, 1
    or   s8, s8, t0
    andi s8, s8, 0xFF
    andi a0, s8, 0x3
    ret

guardar_luz:
    add  t0, s0, s1
    sb   a0, 0(t0)
    addi s1, s1, 1
    ret

ler_dpad_direcao:
    lw   t0, 0x0(s9)
    lw   t1, 0x4(s9)
    lw   t2, 0x8(s9)
    lw   t3, 0xc(s9)
    li   a0, 1
    beqz t0, checa_down
    li   a1, 0
    ret
checa_down:
    beqz t1, checa_left
    li   a1, 1
    ret
checa_left:
    beqz t2, checa_right
    li   a1, 2
    ret
checa_right:
    beqz t3, nenhum
    li   a1, 3
    ret
nenhum:
    li   a0, 0
    ret

ler_switches:
    lw   t0, 0x0(s10)
    andi s4, t0, 0x3
    srli t1, t0, 2
    andi s5, t1, 0x1
    srli t1, t0, 3
    andi s6, t1, 0x1
    srli t1, t0, 4
    andi a0, t1, 0x1
    ret

# NOTA: esta sub-rotina chama delay_real (call dentro de call), o que
# sobrescreve `ra`. Por isso salvamos/restauramos `ra` na pilha, senao
# o `ret` final nao volta para main, e sim para dentro do proprio loop.
exibir_sequencia:
    addi sp, sp, -4
    sw   ra, 0(sp)
    li   t6, 0
exibir_loop:
    beq  t6, s1, exibir_fim
    add  t0, s0, t6
    lb   t1, 0(t0)
    la   t2, cores
    slli t3, t1, 2
    add  t2, t2, t3
    lw   t4, 0(t2)
    slli t5, t1, 2
    add  a1, s11, t5
    sw   t4, 0(a1)
    li   a0, 2000000000
    beqz s5, exibir_espera_on
    li   a0, 1000000000
exibir_espera_on:
    call delay_real
    sw   zero, 0(a1)
    li   a0, 200000000
    call delay_real
    addi t6, t6, 1
    j    exibir_loop
exibir_fim:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

delay_real:
    li   t3, RTC_0_BASE
    lw   t0, 0(t3)
delay_real_loop:
    lw   t1, 0(t3)
    sub  t2, t1, t0
    bltu t2, a0, delay_real_loop
    ret

comparar_toque:
    add  t0, s0, s2
    lb   t1, 0(t0)
    li   a0, 0
    bne  a1, t1, comparar_fim
    li   a0, 1
comparar_fim:
    ret

atualiza_placar:
    li   t0, 1
    beqz s4, atualiza_peso_pronto
    li   t0, 2
    li   t1, 1
    beq  s4, t1, atualiza_peso_pronto
    li   t0, 3
atualiza_peso_pronto:
    beqz s5, atualiza_soma
    slli t0, t0, 1
atualiza_soma:
    add  s7, s7, t0
    ret

calc_tamanho_max:
    li   s3, 8
    beqz s4, calc_fim
    li   s3, 16
    li   t1, 1
    beq  s4, t1, calc_fim
    li   s3, 32
calc_fim:
    ret
