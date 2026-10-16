# PBL03 (Entrega 3): processador RISC-V de ISA limitada e verificação em UVM

Marina de Oliveira Alencar, SENAI CIMATEC, Programa QuIIN.

## Conteúdo

| Pasta | O que é |
| --- | --- |
| `uvm_colega/` | Ambiente UVM aplicado ao processador da outra equipe (`Penelu/RISC_V-PBL`, 19 instruções) |
| `uvm_marina/` | O mesmo ambiente aplicado ao processador desta equipe (22 instruções), com o RTL |
| `bug_report/` | Relato do defeito encontrado (`mul` executado como `add`) e o patch de uma linha |
| `doc/` | Relatório do PBL03 (PDF) |

## Ambiente UVM

Montado a partir do [verif-env-template](https://github.com/nelsonafn/verif-env-template) e do [tutorial UVM do ChipVerify](https://chipverify.com/tutorials/uvm). Componentes: sequencer, driver, monitor, agent, modelo de referência (ISS), scoreboard, cobertura funcional e três testes (`riscv_basic_test`, `riscv_random_test`, `riscv_illegal_test`). O mesmo código serve aos dois processadores por meio de um perfil (macros `RV_PROFILE_MARINA` e `RV_PROFILE_COLEGA`).

## Como rodar (Windows, Git Bash, Vivado 2024.1)

`uvm_colega/` precisa do RTL do colega em `../pbl03_colega/rtl/cpu/` (ver `srclist/riscv_colega_dut.srclist`). Dentro da pasta do ambiente, com o `setup_env.sh` do `verif-env-template`:

```bash
source setup_env.sh
cmake -S . -B build -G "Unix Makefiles" -DTOP_NAME=riscv_colega_tb_top -DTEST_NAME=riscv_basic_test
make SHELL="$(which bash)" elaborate
cd build
cmd //c 'xsim top_sim -R -testplusarg "UVM_TESTNAME=riscv_basic_test"'
cmd //c 'xsim top_sim -R -testplusarg "UVM_TESTNAME=riscv_random_test" -testplusarg "NUM_PROGS=200" -sv_seed 1'
cmd //c 'xsim top_sim -R -testplusarg "UVM_TESTNAME=riscv_illegal_test"'
```

`make sim` não funciona neste ambiente; chame o `xsim` de dentro de `build`. O resultado aparece no fim: `SB_SUMMARY` e o banner PASSED ou FAILED.

## Resultados no processador do colega

| Teste | Programas | Ciclos | Resultado |
| --- | ---: | ---: | --- |
| `riscv_basic_test` | 4 | 53 | PASSED (cobertura 66,79%) |
| `riscv_random_test` (padrão) | 50 | 6886 | PASSED |
| `riscv_random_test` (5 sementes × 200) | 1000 | 138347 | PASSED (cobertura 100,00%) |
| `riscv_illegal_test` | 15 | 950 | FAILED: `mul` executado como `add` |

Detalhes do defeito em `bug_report/RELATO_mul_executado_como_add.md`.

## Limitações

- O ISS foi escrito por esta equipe; um erro de interpretação pode estar nos dois lados.
- A confirmação do defeito por mutação foi feita em Icarus Verilog; falta repetir no xsim com o UVM.
- Chaves e botões do processador do colega ficam em zero; essa parte não é exercitada.
