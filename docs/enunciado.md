# Enunciado — Laboratório 2 (resumo)

> Enunciado completo em [`lab2.pdf`](lab2.pdf).

## Contexto

Dados **simulados** de um plano de saúde: número de consultas médicas de
cada cliente em um ano. Uma parcela dos clientes nunca consulta (zeros
estruturais); os demais consultam um número aleatório de vezes. Há três
perfis de risco (`baixo`, `medio`, `alto`), e **a análise deve ser feita de
forma independente para cada perfil**.

## Modelo ZIP

$$P(Y_i=0) = p + (1-p)e^{-\lambda}, \qquad P(Y_i=k) = (1-p)\frac{e^{-\lambda}\lambda^k}{k!},\ k\ge 1$$

$$\ell(p,\lambda) = \sum_{y_i=0}\log\big(p+(1-p)e^{-\lambda}\big) + \sum_{y_i>0}\big[\log(1-p) - \lambda + y_i\log\lambda\big]$$

## Parte 1 — Otimização numérica

- **1.1** EMV via `optim()` (minimizar −ℓ), com reparametrização sem restrições; testar pontos iniciais diferentes.
- **Q1** Derivar as equações de score $\partial\ell/\partial p$ e $\partial\ell/\partial\lambda$.
- **Q2** Calcular as segundas derivadas, analisar a Hessiana e discutir a viabilidade do Newton-Raphson; se viável, implementar 10 iterações e comparar com `optim()`.

## Parte 2 — Algoritmo EM

- **Q3** Derivar os passos E e M a partir de $\ell_c$; expressão de $w_i$ para $y_i=0$ e $y_i>0$; intuição.
- **Q4** Implementar o EM; gráfico da log-verossimilhança observada ao longo das iterações.

## Parte 3 — Inferência Bayesiana via MCMC

Prioris: $p\sim\text{Beta}(1,1)$ e $\lambda\sim\text{Gamma}(1, 0{,}01)$.

- **Q5** Derivar as condicionais completas (Bernoulli, Beta, Gamma) e interpretar a probabilidade de $Z_i$.
- **Q6** Implementar o Gibbs Sampler (≥ 10.000 iterações, burn-in 2.000); estimativas pontuais e IC de credibilidade de 95%.
- **Q7** Trajetórias das cadeias e comentário sobre a convergência.
- **Q8** Comparar Bayes (mediana e IC) com o EMV do EM e do `optim()`.

## Parte 4 — Aplicação prática

Custo por consulta: R\$ 250,00. Lucro médio desejado: R\$ 100,00 por cliente por ano.

- **Q9** Derivar $E[Y]$ pela representação de mistura.
- **Q10** Valor anual a cobrar por perfil, com as estimativas de cada método, em tabela.
- **Q11** Os valores diferem entre métodos? O que acontece com as finanças se o método estiver mal-convergido?

## Avaliação

- Derivações (Q1, Q3, Q5, Q9): clareza, precisão e profundidade.
- Implementação (Q2, Q4, Q6): precisão, eficiência e reprodutibilidade.
- Análises (Q7, Q8, Q10, Q11): qualidade dos gráficos, diagnósticos e comparação entre métodos.
- Clareza do texto: explicações autocontidas.
