# Contexto do Projeto

## Visão Geral

Laboratório 2 de ME524: modelo de Poisson inflado em zero (ZIP) aplicado ao
número de consultas médicas por cliente de um plano de saúde, com análise
independente para os perfis de risco `baixo`, `medio` e `alto`. Ver
`docs/enunciado.md` para o enunciado resumido e `README.md` para como rodar o
projeto.

## Stack

- R ≥ 4.3
- `stats` (base) para `optim()`, `uniroot()` e geradores aleatórios
- `coda` para diagnósticos de MCMC (Gelman-Rubin, tamanho efetivo)
- `ggplot2` + `patchwork` para os gráficos
- `rmarkdown` / `knitr` + xelatex para o relatório em PDF
- `testthat` para testes e `lintr` para lint

## Fluxo Principal

```
CSV → estatísticas suficientes por perfil
  → optim() (logit p, log λ) e Newton-Raphson  [Parte 1]
  → algoritmo EM                               [Parte 2]
  → Gibbs Sampler + diagnósticos               [Parte 3]
  → E[Y], prêmio, impacto de má convergência   [Parte 4]
```

## Índice de Documentos

| Arquivo | Conteúdo |
|---|---|
| [.ai/padroes-codigo.md](padroes-codigo.md) | Padrões de código R, scripts e testes |
| [.ai/modelagem.md](modelagem.md) | Decisões do modelo estatístico (ADRs) |
| [docs/enunciado.md](../docs/enunciado.md) | Resumo do enunciado e das perguntas a responder |
| [docs/respostas.md](../docs/respostas.md) | Respostas resumidas do grupo |
| [docs/relatorio/relatorio.Rmd](../docs/relatorio/relatorio.Rmd) | Relatório executável (código + texto) |
