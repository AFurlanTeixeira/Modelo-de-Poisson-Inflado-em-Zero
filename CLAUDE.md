# CLAUDE.md

Este arquivo orienta o Claude Code (claude.ai/code) ao trabalhar neste repositório.

## Overview

Laboratório 2 de ME524 (Unicamp, 2026): modelo de Poisson inflado em zero
(ZIP) para o número anual de consultas médicas de clientes de um plano de
saúde (`data/raw/visitas_medicas.csv`, dados simulados). Para cada perfil de
risco (`baixo`, `medio`, `alto`), o projeto estima $(p, \lambda)$ por
`optim()`, Newton-Raphson, algoritmo EM e Gibbs Sampler, compara os métodos
e usa as estimativas para calcular o valor anual a cobrar dos clientes.

Este é um projeto de análise, não um serviço: não há endpoint, banco de
dados ou deploy. A entrega é um relatório (código + texto) respondendo às
questões 1–11 do enunciado.

Docs mais profundos:
- `.ai/contexto.md`: visão geral do fluxo e índice dos demais arquivos
- `.ai/padroes-codigo.md`: padrões de R, de scripts por pergunta e de testes
- `.ai/modelagem.md`: decisões do modelo estatístico (ADRs)
- `docs/enunciado.md`: resumo do enunciado e das perguntas

## Commands

Todos a partir da raiz do repositório:

```bash
Rscript scripts/run_all.R                             # roda todas as perguntas
Rscript scripts/parte2_em/q4_em.R                     # roda uma pergunta isolada
Rscript -e 'testthat::test_dir("tests/testthat")'     # testes unitários
Rscript -e 'rmarkdown::render("docs/relatorio/relatorio.Rmd")'  # gera o PDF (requer xelatex)
```

Rodar um único arquivo de teste:
```bash
Rscript -e 'testthat::test_file("tests/testthat/test-em.R")'
```

## Architecture

### Fluxo

```
data/raw/visitas_medicas.csv
  → R/dados.R              (carrega, valida, estatísticas suficientes por perfil)
  → R/verossimilhanca.R    (log-verossimilhança, score, Hessiana, EMV de referência)
  → R/otimizacao.R         (Parte 1.1: optim() reparametrizado)
  → R/newton_raphson.R     (Parte 1.2: Newton-Raphson)
  → R/em.R                 (Parte 2: EM)
  → R/gibbs.R              (Parte 3: Gibbs Sampler + diagnósticos)
  → R/aplicacao.R          (Parte 4: E[Y] e prêmio)
```

### Scripts por pergunta

`scripts/parteN_*/qX_*.R` são executáveis isoladamente. Cada um:
1. carrega as funções de `R/` (`source("R/utils.R"); carregar_funcoes()`);
2. lê dependências de outras perguntas com `ler_resultado()`, que roda o
   script de origem se o `.rds` ainda não existir;
3. salva tabelas em `data/processed/<parte>/` (`salvar_resultado()`) e
   figuras em `docs/figuras/<parte>/` (`salvar_figura()`).

### Relatório

`docs/relatorio/relatorio.Rmd` define `root.dir` como a raiz do repositório
e inclui as seções de `docs/relatorio/secoes/` como child documents. Cada
seção executa o script da pergunta com `file = arquivo_script(...)`, o que
mostra o código na íntegra, e monta tabelas e figuras a partir dos objetos
criados. Não reimplemente lógica estatística nas seções: ela fica em `R/`.

Cuidado com nomes: os scripts rodam no mesmo ambiente do knit, então os
helpers do relatório (`incluir_figura`, `arquivo_script`, `secao`, `kab`,
`brl`) não podem ser sobrescritos por variáveis dos scripts.

## Design Decisions

Ver `.ai/modelagem.md`: reparametrização logit/log no `optim()`, inícios
pelo método dos momentos no Newton-Raphson, EM com pesos fechados,
Gibbs com amostragem de `sum(Z)` via Binomial, prioris do enunciado e
premissas da precificação.
