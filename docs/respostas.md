# Respostas — Laboratório 2

> Resultados com semente 524 (Gibbs: 3 cadeias × 20.000 iterações, burn-in
> 2.000). O código completo e reprodutível está em
> [`relatorio/relatorio.Rmd`](relatorio/relatorio.Rmd) (renderiza para
> [`relatorio.pdf`](relatorio/relatorio.pdf), com derivações e gráficos);
> aqui ficam só os números e a interpretação. As perguntas completas estão em
> [`enunciado.md`](enunciado.md).

## 1.1 EMV via `optim()`

| Perfil | $\hat p$ | $\hat\lambda$ | $\ell(\hat p, \hat\lambda)$ |
|---|---:|---:|---:|
| baixo | 0,56442 | 1,68739 | −457,88 |
| medio | 0,28222 | 3,01275 | −743,09 |
| alto | 0,08111 | 4,96793 | −908,78 |

O Nelder-Mead convergiu para a mesma solução nos 20 pontos iniciais. O BFGS
apresentou **falsa convergência** em $p\approx 0$, $\lambda = \bar y$ (4/20
inícios no perfil médio, 9/20 no alto), reportando `convergence = 0` em um
ponto com $\ell$ até 51 unidades menor. Causa: na escala logit,
$\partial\ell/\partial\theta_1 = p(1-p)\,\partial\ell/\partial p \to 0$.

## Q1. Equações de score

$U_p = \dfrac{n_0(1-e^{-\lambda})}{p+(1-p)e^{-\lambda}} - \dfrac{n_+}{1-p}$ e
$U_\lambda = -\dfrac{n_0(1-p)e^{-\lambda}}{p+(1-p)e^{-\lambda}} + \dfrac{S}{\lambda} - n_+$.

Igualando a zero: $\hat p + (1-\hat p)e^{-\hat\lambda} = n_0/n$,
$(1-\hat p)\hat\lambda = \bar y$ e $\hat\lambda/(1-e^{-\hat\lambda}) = \bar y_+$
(equação de uma variável, resolvida com `uniroot()` como referência).

## Q2. Hessiana e Newton-Raphson

$\ell_{pp}<0$ sempre, $\ell_{p\lambda} = n_0e^{-\lambda}/D^2 > 0$ e
$\ell_{\lambda\lambda} = n_0p(1-p)e^{-\lambda}/D^2 - S/\lambda^2$ tem sinal
indefinido, então $\ell$ não é globalmente côncava. **Viável localmente**: a
partir do método dos momentos, converge quadraticamente em 3–4 iterações e
coincide com `optim()` e com a referência até a 6ª casa. A partir de inícios
ruins o passo sai do domínio (8 de 9 casos testados).

## Q3. Passos E e M

$w_i = 0$ se $y_i > 0$; $w_i = p/(p + (1-p)e^{-\lambda})$ se $y_i = 0$.
$p^{(t+1)}$ é a proporção esperada de zeros estruturais; $\lambda^{(t+1)}$ é a
média das contagens ponderada pela probabilidade de pertencer ao grupo
Poisson. Toda iteração satisfaz $(1-p^{(t)})\lambda^{(t)} = \bar y$.

## Q4. EM

Convergência monótona ao mesmo EMV em 29 (baixo), 12 (médio) e 8 (alto)
iterações, com taxa linear (mais lenta onde há mais zeros ambíguos). Robusto
a 9 pontos iniciais (amplitude das soluções < $10^{-6}$).

## Q5. Condicionais completas

$Z_i\mid\cdot\sim\text{Bernoulli}\big(p/(p+(1-p)e^{-\lambda})\big)$ para
$y_i = 0$: é a probabilidade de um zero observado ser estrutural (o mesmo
$w_i$ do EM). $p\mid z\sim\text{Beta}(1+\sum z_i, 1+n-\sum z_i)$ e
$\lambda\mid y,z\sim\text{Gamma}(1+S, 0{,}01+n-\sum z_i)$.

## Q6. Gibbs Sampler

| Perfil | $p$: mediana [IC 95%] | $\lambda$: mediana [IC 95%] |
|---|---:|---:|
| baixo | 0,5637 [0,4981; 0,6235] | 1,6891 [1,4566; 1,9463] |
| medio | 0,2829 [0,2358; 0,3327] | 3,0144 [2,7994; 3,2381] |
| alto | 0,0825 [0,0571; 0,1134] | 4,9691 [4,7389; 5,2048] |

## Q7. Diagnóstico

Cadeias com inícios dispersos se sobrepõem em poucas iterações; $\hat R = 1{,}00$
e tamanho efetivo entre ~19 mil e ~51 mil. A autocorrelação de lag 1 é maior no
perfil baixo (~0,39) e quase nula no alto. Sem sinais de falta de convergência.

## Q8. Comparação final

Coerentes: `optim()`, Newton-Raphson e EM dão o mesmo EMV; as medianas a
posteriori diferem dele em uma pequena fração do erro-padrão, e os ICs de
credibilidade praticamente coincidem com os de Wald. Com $n = 400$ e prioris
vagas, a verossimilhança domina.

## Q9. Valor esperado

$E[Y] = p\cdot 0 + (1-p)\lambda = (1-p)\lambda$ (lei da esperança total).
Também $\operatorname{Var}(Y) = (1-p)\lambda(1+p\lambda)$. Ambas conferidas por
Monte Carlo com $10^6$ clientes simulados.

## Q10. Valor anual a cobrar (R\$)

| Perfil | optim | Newton-Raphson | EM | Bayes (plug-in) | Bayes: mediana do prêmio [IC 95%] |
|---|---:|---:|---:|---:|---:|
| baixo | 283,75 | 283,75 | 283,75 | 284,23 | 284,03 [256,33; 315,36] |
| medio | 640,62 | 640,63 | 640,62 | 640,43 | 639,84 [591,96; 689,95] |
| alto | 1.241,25 | 1.241,25 | 1.241,25 | 1.239,76 | 1.238,89 [1.176,72; 1.300,80] |

## Q11. Análise

Os métodos convergidos não diferem: no EMV, $(1-\hat p)\hat\lambda = \bar y$,
logo o prêmio é sempre $250\bar y + 100$. Já um método mal-convergido pode
ser desastroso: com o `optim()` interrompido em 15 iterações, o prêmio do
perfil alto cai para R\$ 1.041,68 e o resultado esperado da carteira de 400
clientes vira **−R\$ 39,8 mil** (em vez de +R\$ 40 mil). O EM parado na 1ª
iteração e o BFGS preso em $p=0$ acertam o prêmio com parâmetros errados: a
precificação pela média não detecta o erro, mas a variância (reservas
técnicas) e a proporção de não-usuários ficariam erradas.
