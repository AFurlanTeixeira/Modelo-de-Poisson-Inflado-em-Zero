#' Algoritmo EM para o ZIP (Parte 2, Questao 4).
#'
#' Passo E: w_i = P(Z_i = 1 | y_i) = p / (p + (1 - p) e^-lambda) se y_i = 0 e
#' w_i = 0 se y_i > 0. Passo M: p = sum(w) / n e
#' lambda = sum((1 - w) y) / sum(1 - w). Como w_i y_i = 0, ambos dependem so do
#' peso comum w dos zeros: p = n0 w / n e lambda = S / (n - n0 w).

#' Pesos do passo E para cada observacao.
#'
#' @param y vetor de contagens.
#' @param p,lambda numeric, parametros atuais.
#' @return numeric, w_i para cada observacao.
pesos_em <- function(y, p, lambda) {
  ifelse(y == 0, p / (p + (1 - p) * exp(-lambda)), 0)
}

#' Ajusta o ZIP pelo algoritmo EM.
#'
#' @param s list de estatisticas suficientes.
#' @param p0 numeric, ponto inicial de p.
#' @param lambda0 numeric, ponto inicial de lambda (padrao: media amostral).
#' @param tol numeric, tolerancia no incremento da log-verossimilhanca.
#' @param max_iter integer, numero maximo de iteracoes.
#' @return list com `p`, `lambda`, `loglik` (trajetoria, incluindo o inicio)
#'   e `iter`.
em_zip <- function(s, p0 = 0.5, lambda0 = s$S / s$n, tol = 1e-12, max_iter = 10000) {
  p <- p0
  lambda <- lambda0
  ll <- numeric(max_iter + 1)
  ll[1] <- loglik_zip(p, lambda, s)
  for (t in seq_len(max_iter)) {
    w <- p / (p + (1 - p) * exp(-lambda)) # passo E (peso comum dos zeros)
    p <- s$n0 * w / s$n # passo M
    lambda <- s$S / (s$n - s$n0 * w)
    ll[t + 1] <- loglik_zip(p, lambda, s)
    if (abs(ll[t + 1] - ll[t]) < tol) break
  }
  list(p = p, lambda = lambda, loglik = ll[seq_len(t + 1)], iter = t)
}
