# Relato de verificação: `mul` é executado como `add`

Para a equipe do repositório `Penelu/RISC_V-PBL`. De: Marina de Oliveira Alencar (SENAI CIMATEC, QuIIN), PBL03, Frente 2.

## Resumo

O README promete que qualquer instrução fora das 19 listadas é ignorada (não escreve registrador nem memória). Isso não vale para instruções tipo R com `funct7` diferente de zero e bit 30 em zero. O `mul` (`funct7 = 0000001`, `funct3 = 000`) é executado como `add`.

## Como foi encontrado

Teste `riscv_illegal_test` do ambiente UVM (pasta `uvm_colega/`): 15 programas, um por instrução fora das 19. Resultado: 14 passam e 1 falha (`mul`). No programa do `mul`, o DUT escreve na memória o valor da soma onde o modelo de referência esperava que a instrução fosse ignorada.

## Causa

`rtl/cpu/control.sv`, bloco `OP_REG`: o decodificador usa só o bit 30 da instrução (`funct7_5`):

```systemverilog
OP_REG: begin
    alu_src = 1'b0;
    if (!funct7_5) begin                 // sub is not supported
        case (funct3)
            F3_ADD: begin alu_op = ALU_ADD; reg_write = 1'b1; end
            F3_AND: begin alu_op = ALU_AND; reg_write = 1'b1; end
            F3_XOR: begin alu_op = ALU_XOR; reg_write = 1'b1; end
            default: ;
        endcase
    end
end
```

O bit 30 distingue `add` de `sub`, mas o `mul` tem `funct7 = 0000001`: o bit 30 é 0, o filtro deixa passar e o `funct3` escolhe `add`. O mesmo vale para qualquer `funct7` não nulo com bit 30 em zero e `funct3` igual a `000`, `111` ou `100` (por exemplo, `div` vira `xor`).

## Reprodução mínima

```
addi x1,x0,6
addi x2,x0,7
addi x3,x0,0
addi x4,x0,0
mul  x3,x1,x2      # esperado: x3 continua 0   | obtido: x3 = 13
div  x4,x1,x2      # esperado: x4 continua 0   | obtido: x4 = 1  (6 xor 7)
```

## Correção sugerida (uma linha)

Em `rtl/cpu/cpu.sv`, rejeitar qualquer `funct7` não nulo (arquivo `cpu_funct7.patch`):

```diff
-    assign funct7_5 = instr[30];
+    assign funct7_5 = |instr[31:25];  // any funct7 != 0 (sub, srai, mul...) is rejected
```

## Confirmação

Com o patch aplicado ao RTL do colega, o `riscv_illegal_test` no xsim 2024.1 passou de FAILED (1 erro, `mul`) para **PASSED**: 15 programas, 0 falhos, 975 ciclos comparados, 0 erros. Em Icarus Verilog, com o mesmo modelo de referência, o `mul` e o `div` passam a ser ignorados (x3 e x4 ficam em 0) e 60 programas aleatórios válidos continuam sem divergência.

## O que passou

Nos programas válidos, o processador coincide com o modelo de referência: 4 programas dirigidos e 1050 aleatórios (5 sementes × 200 programas, mais 50 com a semente padrão), cobertura funcional de 100%.
