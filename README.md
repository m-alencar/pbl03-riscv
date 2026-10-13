# Processador RISC-V de ciclo único (ISA limitada) — PBL03

Pacote para a equipe que vai verificar este processador. Autora: Marina de Oliveira Alencar (SENAI CIMATEC, QuIIN).

Base: processador de ciclo único do Capítulo 7 de Harris & Harris (*Digital Design and Computer Architecture: RISC-V Edition*), com extensões. Detalhes em `doc/relatorio_pbl03.pdf` e `doc/arquitetura_pbl03.pdf`.

## O que verificar (DUT)

O núcleo é o módulo `riscvsingle` (controller + datapath), sem memórias dentro. Para simular com memórias, use `riscv_single_top`.

### Interface de `riscvsingle`

| Porta | Direção | Largura | Significado |
| --- | --- | --- | --- |
| `clk` | entrada | 1 | clock |
| `reset` | entrada | 1 | reset assíncrono, ativo em nível alto; leva o PC a 0 |
| `PC` | saída | 32 | endereço da instrução atual |
| `Instr` | entrada | 32 | instrução em `PC` (memória de instruções, leitura combinacional) |
| `MemWrite` | saída | 1 | escrita na memória de dados |
| `ALUResult` | saída | 32 | endereço de dados (resultado da ALU) |
| `WriteData` | saída | 32 | dado a escrever na memória de dados |
| `ReadData` | entrada | 32 | dado lido da memória de dados no endereço `ALUResult` |
| `ECall` | saída | 1 | sobe quando a instrução atual é `ecall` (usado como marcador de fim de programa) |

### Interface de `riscv_single_top` (núcleo + `imem` + `dmem`)

`clk`, `reset` (entradas); `WriteData[31:0]`, `DataAdr[31:0]`, `MemWrite`, `ECall` (saídas). O programa é carregado em `imem` por `$readmemh`.

## Comportamento relevante para o teste

- **Ciclo único:** uma instrução por ciclo; o estado (PC, registradores, memória de dados) atualiza na borda de subida de `clk`.
- **Reset:** assíncrono, `PC = 0`. O banco de registradores não é zerado pelo reset; `x0` é sempre 0 (nunca escrito).
- **Memória de instruções (`imem`):** 64 KB, leitura combinacional por palavra (ignora `a[1:0]`); arquivo `.hex` com uma palavra de 32 bits por linha, em hexadecimal.
- **Memória de dados (`dmem`):** 16 KB, endereçável por byte, little-endian. Escrita síncrona; leitura combinacional. O tamanho do acesso vem de `funct3` da instrução (`000` = byte, `010` = palavra). `lb` faz extensão de sinal. Não há verificação de faixa nem de alinhamento.
- **`ecall`:** não executa chamada de sistema; apenas levanta `ECall`.
- **Fora do escopo (comportamento não especificado):** exceções, CSRs, `fence`, multiplicação/divisão, acessos desalinhados, e qualquer instrução fora da lista abaixo (por exemplo `slt`, `blt`, `bgeu`, `lh`, `lbu`, `sh`, `sra`).

## ISA implementada (22 instruções)

| Instrução | Tipo | Opcode | Função |
| --- | --- | --- | --- |
| `add`, `sub`, `and`, `or`, `xor` | R | 0110011 | operações entre registradores |
| `addi`, `andi`, `slli`, `srli` | I | 0010011 | operações com imediato |
| `lw`, `lb` | I | 0000011 | carrega palavra / byte (com extensão de sinal) |
| `sw`, `sb` | S | 0100011 | armazena palavra / byte |
| `beq`, `bne`, `bge`, `bltu` | B | 1100011 | desvios condicionais (`bge` com sinal, `bltu` sem sinal) |
| `jal` | J | 1101111 | salto com retorno |
| `jalr` | I | 1100111 | salto indireto com retorno |
| `lui` | U | 0110111 | imediato nos bits altos |
| `auipc` | U | 0010111 | PC + imediato nos bits altos |
| `ecall` | I | 1110011 | marcador de fim |

## Arquivos

- `rtl/` — código-fonte em SystemVerilog (`riscvsingle`, `controller`, `datapath`, `alu`, `regfile`, `extend`, `maindec`, `aludec`, `imem`, `dmem`, `riscv_single_top`). `genius_soc` e `genius_periph` são do SoC de teste do jogo Genius (não fazem parte do núcleo).
- `sim/` — teste de sanidade (`testbench.sv`), programa de teste (`program.hex`, gerado por `encode.py`) e testbench do Genius (`genius_tb.sv`).
- `genius/` — programa Genius (PBL02) em assembly e os `.hex` prontos (`genius.hex` = instruções, `data.hex` = dados).
- `doc/` — relatório e documento de arquitetura.

## Como rodar os testes de referência

Ambiente de origem: Windows + Git Bash + Vivado 2024.1, com o `verif-env-template` (https://github.com/nelsonafn/verif-env-template). Coloque `rtl/` e os testbenches nas pastas correspondentes do template e use uma `srclist` com os arquivos de `rtl/`.

**Teste de sanidade** (`program.hex`): ao chegar no `ecall`, deve imprimir `a0 = 3`, `x28 = 15`, `x30 = 65`, `x12 = 0x34` e terminar em 205 ns. O `program.hex` precisa estar na pasta em que o `xsim` roda.

**Genius** (`genius_tb`, com `genius.hex` e `data.hex` na pasta do `xsim`): resultado esperado `RESULTADO: 5 cenarios passaram, 0 falharam`.

## Resultados já obtidos (simulação, Vivado xsim 2024.1)

- Teste de sanidade: 4 de 4 registradores conferidos.
- Genius: 5 cenários passaram (pontuações 36, 6, 544, 3 e 3), 0 divergências.
- Elaboração no Vivado: `riscvsingle` aparece dividido em controller e datapath.

Esses testes não substituem a verificação em UVM: cobrem as classes de instrução do programa de sanidade e o conjunto do Genius, não todas as combinações de operandos, desvios e acessos à memória.

## Contato

Dúvidas sobre o projeto: Marina de Oliveira Alencar - marinaadmeng@gmail.com
