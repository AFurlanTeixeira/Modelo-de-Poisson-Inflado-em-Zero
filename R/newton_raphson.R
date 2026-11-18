#' Metodo de Newton-Raphson para o ZIP (Parte 1.2, Questao 2).
#'
#' Usa o score e a Hessiana analiticos de `R/verossimilhanca.R`. Nao ha
#' salvaguarda de passo de proposito: o objetivo do relatorio e mostrar quando
#' o metodo puro funciona (perto do EMV) e quando falha (longe dele).

#' Ponto inicial pelo metodo dos momentos.
#'
#' De E[Y] = (1 - p) lambda e Var(Y) = (1 - p) lambda (1 + p lambda) segue
#' p lambda = Var / E - 1, logo lambda0 = media + var / media - 1 e
#' p0 = (var / media - 1) / lambda0.
#'
#' @param y vetor de contagens.
#' @return numeric nomeado c(p0, lambda0).
inicio_momentos <- function(y) {
  m <- mean(y)
  v <- stats::var(y)
  lambda0 <- m + v / m - 1
  c(p0 = (v / m - 1) / lambda0, lambda0 = lambda0)
}

#' Newton-Raphson com numero fixo de iteracoes.
#'
#' theta(k+1) = theta(k) - H^-1 U. Interrompe se o ponto sair do espaco
#' parametrico (p fora de (0, 1) ou lambda <= 0).
#'
#' @param s list de estatisticas suficientes.
#' @param p0,lambda0 numeric, ponto inicial.
#' @param n_iter integer, numero de iteracoes.
#' @return data.frame com a trajetoria (iter, p, lambda, loglik, norma_score).
newton_raphson_zip <- function(s, p0, lambda0, n_iter = 10) {
  theta <- c(p0, lambda0)
  traj <- vector("list", n_iter + 1)
  traj[[1]] <- data.frame(
    iter = 0, p = p0, lambda = lambda0, loglik = loglik_zip(p0, lambda0, s),
    norma_score = sqrt(sum(score_zip(p0, lambda0, s)^2))
  )
  for (k in seq_len(n_iter)) {
    passo <- solve(hessiana_zip(theta[1], theta[2], s), score_zip(theta[1], theta[2], s))
    theta <- theta - passo
    valido <- all(is.finite(theta)) && theta[1] > 0 && theta[1] < 1 && theta[2] > 0
    traj[[k + 1]] <- data.frame(
      iter = k, p = theta[1], lambda = theta[2],
      loglik = if (valido) loglik_zip(theta[1], theta[2], s) else NA_real_,
      norma_score = if (valido) sqrt(sum(score_zip(theta[1], theta[2], s)^2)) else NA_real_
    )
    if (!valido) break
  }
  do.call(rbind, traj)
}
