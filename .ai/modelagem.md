# Decisões de Modelagem

Decisões do modelo estatístico, no formato de ADR. As marcadas como
**enunciado** vêm de `docs/lab2.pdf`; as marcadas como **grupo** são escolhas
de implementação nossas, com a justificativa.

## ADR-001: Modelo ZIP (enunciado)

```
P(Y = 0) = p + (1 - p) e^(-λ)
P(Y = k) = (1 - p) e^(-λ) λ^k / k!,   k = 1, 2, ...
```

Representação de mistura: `Z ~ Bernoulli(p)`; se `Z = 1`, `Y = 0`
(zero estrutural); se `Z = 0`, `Y ~ Poisson(λ)`. Análise independente por
perfil de risco.

## ADR-002: Reparametrização no `optim()` (enunciado + grupo)

`θ1 = logit(p)`, `θ2 = log(λ)`. Testamos 20 pontos iniciais × {Nelder-Mead,
BFGS} e reportamos a solução de maior log-verossimilhança. Motivo: o BFGS
apresenta falsa convergência em `p ≈ 0` (o gradiente em `θ1` é
`p(1 - p) ∂ℓ/∂p → 0`), o que só se detecta comparando vários inícios.

## ADR-003: Newton-Raphson sem salvaguarda, iniciado pelos momentos (grupo)

Score e Hessiana analíticos (`R/verossimilhanca.R`). Início pelo método dos
momentos: `λ0 = ȳ + s²/ȳ − 1`, `p0 = (s²/ȳ − 1)/λ0`. Não usamos busca linear
de propósito: o relatório mostra quando o método puro funciona (perto do EMV)
e quando falha (inícios ruins saem do domínio).

## ADR-004: EM com pesos fechados (enunciado)

`w_i = p/(p + (1 − p)e^(−λ))` se `y_i = 0`, e `w_i = 0` se `y_i > 0`;
`p = Σw/n`, `λ = Σ(1 − w)y / Σ(1 − w)`. Critério de parada: incremento de ℓ
menor que `1e-12`. Propriedade usada na Parte 4: toda iteração satisfaz
`(1 − p)λ = ȳ`.

## ADR-005: Gibbs Sampler (enunciado + grupo)

Prioris do enunciado: `p ~ Beta(1, 1)` e `λ ~ Gamma(1, 0.01)` (forma, taxa).
Escolha do grupo: sortear `Σ Z_i ~ Binomial(n0, π)` em vez dos `n0`
indicadores. É equivalente em distribuição, porque só a soma entra nas
condicionais de `p` e `λ`, e é muito mais rápido. Três cadeias de 20.000
iterações a partir de inícios dispersos, burn-in de 2.000, diagnósticos com
`coda` (R-hat, ESS) e ACF.

## ADR-006: IC de Wald na escala transformada (grupo)

Para comparar com o IC de credibilidade, o IC de Wald do EMV é construído na
escala `(logit p, log λ)`, com a informação observada transformada pelo
Jacobiano `diag(p(1 − p), λ)`, e depois transformado de volta, o que garante
`p ∈ (0, 1)` e `λ > 0`.

## ADR-007: Precificação (enunciado)

`Prêmio = 250 · E[Y] + 100`, com `E[Y] = (1 − p)λ`. Para Bayes, a tabela
principal usa o plug-in das medianas (como pede o enunciado); reportamos
também a mediana a posteriori do próprio prêmio e o IC de 95%.
