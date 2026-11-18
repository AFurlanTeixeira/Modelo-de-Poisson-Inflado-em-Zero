#' Log-verossimilhanca, score e Hessiana do modelo ZIP.
#'
#' Ver `.ai/modelagem.md` (ADR-001). Todas as funcoes recebem as estatisticas
#' suficientes `s` de `estatisticas_suficientes()`, o que deixa cada avaliacao
#' O(1). Notacao: D = p + (1 - p) exp(-lambda) = P(Y = 0).

#' Log-verossimilhanca observada do ZIP.
#'
#' Inclui a constante `-sum(log(y!))` para que os valores reportados sejam a
#' log-verossimilhanca completa (nao afeta nenhuma maximizacao). Em p = 0
#' devolve a log-verossimilhanca da Poisson (limite do ZIP).
#'
#' @param p numeric em [0, 1).
#' @param lambda numeric > 0.
#' @param s list de estatisticas suficientes.
#' @return numeric (ou -Inf fora do dominio).
loglik_zip <- function(p, lambda, s) {
  fora_do_dominio <- !is.finite(p + lambda) || lambda <= 0 || p < 0 || p >= 1
  if (fora_do_dominio) {
    return(-Inf)
  }
  if (p == 0) {
    return(-s$n * lambda + s$S * log(lambda) - s$C)
  }
  s$n0 * log(p + (1 - p) * exp(-lambda)) + s$np * log(1 - p) -
    s$np * lambda + s$S * log(lambda) - s$C
}

#' Vetor score (gradiente) da log-verossimilhanca ZIP (Questao 1).
#'
#' U_p = n0 (1 - e^-l) / D - n+ / (1 - p)
#' U_l = -n0 (1 - p) e^-l / D + S / l - n+
#'
#' @inheritParams loglik_zip
#' @return numeric de tamanho 2: c(U_p, U_lambda).
score_zip <- function(p, lambda, s) {
  e <- exp(-lambda)
  d <- p + (1 - p) * e
  c(
    s$n0 * (1 - e) / d - s$np / (1 - p),
    -s$n0 * (1 - p) * e / d + s$S / lambda - s$np
  )
}

#' Hessiana da log-verossimilhanca ZIP (Questao 2).
#'
#' l_pp = -n0 (1 - e^-l)^2 / D^2 - n+ / (1 - p)^2   (sempre < 0)
#' l_pl = n0 e^-l / D^2                               (sempre > 0)
#' l_ll = n0 p (1 - p) e^-l / D^2 - S / l^2           (sinal indefinido)
#'
#' @inheritParams loglik_zip
#' @return matrix 2 x 2.
hessiana_zip <- function(p, lambda, s) {
  e <- exp(-lambda)
  d <- p + (1 - p) * e
  h_pp <- -s$n0 * (1 - e)^2 / d^2 - s$np / (1 - p)^2
  h_pl <- s$n0 * e / d^2
  h_ll <- s$n0 * p * (1 - p) * e / d^2 - s$S / lambda^2
  matrix(c(h_pp, h_pl, h_pl, h_ll), 2, 2)
}

#' EMV de referencia pelas equacoes de score reduzidas.
#'
#' Das condicoes de primeira ordem segue (1 - p) lambda = media(y) e
#' lambda / (1 - exp(-lambda)) = S / n+ (media da Poisson truncada em zero
#' igual a media dos positivos), uma equacao em uma variavel resolvida por
#' `uniroot()`. Solucao interior exige media dos positivos > 1.
#'
#' @param s list de estatisticas suficientes.
#' @return numeric nomeado c(p, lambda).
emv_referencia <- function(s) {
  media_pos <- s$S / s$np
  if (media_pos <= 1) {
    stop("Sem solucao interior: media das contagens positivas <= 1.")
  }
  f <- function(l) l / (1 - exp(-l)) - media_pos
  lambda <- stats::uniroot(f, c(1e-8, 1e3), tol = 1e-14)$root
  c(p = 1 - (s$S / s$n) / lambda, lambda = lambda)
}

#' Hessiana e negativa-definida?
#'
#' @inheritParams loglik_zip
#' @return logical.
hessiana_negativa_definida <- function(p, lambda, s) {
  autovalores <- eigen(hessiana_zip(p, lambda, s), symmetric = TRUE, only.values = TRUE)
  all(autovalores$values < 0)
}

#' Intervalo de Wald de 95% na escala (logit p, log lambda).
#'
#' A matriz de covariancia vem da informacao observada transformada pelo
#' Jacobiano d(p, lambda) / d(theta) = diag(p (1 - p), lambda); o intervalo e
#' construido na escala irrestrita e transformado de volta, respeitando o
#' espaco parametrico.
#'
#' @inheritParams loglik_zip
#' @param nivel numeric, nivel de confianca.
#' @return matrix 2 x 2 (linhas p e lambda; colunas li e ls).
ic_wald_zip <- function(p, lambda, s, nivel = 0.95) {
  jac <- diag(c(p * (1 - p), lambda))
  info <- -(t(jac) %*% hessiana_zip(p, lambda, s) %*% jac)
  ep <- sqrt(diag(solve(info)))
  z <- stats::qnorm(1 - (1 - nivel) / 2)
  theta <- c(stats::qlogis(p), log(lambda))
  ic <- rbind(
    p = stats::plogis(theta[1] + c(-1, 1) * z * ep[1]),
    lambda = exp(theta[2] + c(-1, 1) * z * ep[2])
  )
  colnames(ic) <- c("li", "ls")
  ic
}
