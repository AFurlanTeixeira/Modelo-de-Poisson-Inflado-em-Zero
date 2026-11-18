#' Estimacao por maxima verossimilhanca via optim() (Parte 1.1).
#'
#' Reparametrizacao sem restricoes: theta1 = logit(p), theta2 = log(lambda).
#' Pela invariancia do EMV, basta transformar de volta ao final.

#' Negativo da log-verossimilhanca na escala irrestrita.
#'
#' @param theta numeric c(logit(p), log(lambda)).
#' @param s list de estatisticas suficientes.
#' @return numeric.
negloglik_theta <- function(theta, s) {
  -loglik_zip(stats::plogis(theta[1]), exp(theta[2]), s)
}

#' Ajusta o ZIP via optim() a partir de um ponto inicial.
#'
#' @param s list de estatisticas suficientes.
#' @param p0,lambda0 numeric, ponto inicial na escala original.
#' @param metodo character, metodo do optim() ("Nelder-Mead", "BFGS", ...).
#' @param maxit integer, numero maximo de iteracoes.
#' @return numeric nomeado c(p, lambda, loglik, convergencia, n_avaliacoes).
ajustar_optim <- function(s, p0, lambda0, metodo = "Nelder-Mead", maxit = 5000) {
  ajuste <- stats::optim(
    c(stats::qlogis(p0), log(lambda0)), negloglik_theta,
    s = s, method = metodo, control = list(maxit = maxit, reltol = 1e-12)
  )
  c(
    p = stats::plogis(ajuste$par[1]), lambda = exp(ajuste$par[2]),
    loglik = -ajuste$value, convergencia = ajuste$convergence,
    n_avaliacoes = unname(ajuste$counts[1])
  )
}

#' Roda optim() a partir de uma grade de pontos iniciais e metodos.
#'
#' @param s list de estatisticas suficientes.
#' @param inicios data.frame com colunas `p0` e `lambda0`.
#' @param metodos character, metodos do optim() a comparar.
#' @return data.frame com uma linha por (metodo, ponto inicial).
optim_multiplos_inicios <- function(s, inicios, metodos = c("Nelder-Mead", "BFGS")) {
  linhas <- lapply(metodos, function(m) {
    res <- t(mapply(
      function(p0, l0) ajustar_optim(s, p0, l0, m),
      inicios$p0, inicios$lambda0
    ))
    data.frame(metodo = m, inicios, res, row.names = NULL)
  })
  do.call(rbind, linhas)
}

#' Grade padrao de pontos iniciais usada no relatorio.
#'
#' @return data.frame com 20 combinacoes de `p0` e `lambda0`.
grade_inicios <- function() {
  expand.grid(p0 = c(0.05, 0.2, 0.5, 0.8, 0.95), lambda0 = c(0.5, 1, 3, 8))
}
