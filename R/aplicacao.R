#' Aplicacao pratica: valor esperado e premio anual (Parte 4).

#' Valor esperado do ZIP (Questao 9).
#'
#' Pela lei da esperanca total: E[Y] = p * 0 + (1 - p) * lambda.
#'
#' @param p,lambda numeric (vetorizado).
#' @return numeric.
esperanca_zip <- function(p, lambda) {
  (1 - p) * lambda
}

#' Variancia do ZIP.
#'
#' Pela lei da variancia total: Var(Y) = (1 - p) lambda (1 + p lambda).
#'
#' @param p,lambda numeric (vetorizado).
#' @return numeric.
variancia_zip <- function(p, lambda) {
  (1 - p) * lambda * (1 + p * lambda)
}

#' Valor anual a cobrar por cliente (Questao 10).
#'
#' Premio = CUSTO_CONSULTA * E[Y] + LUCRO_DESEJADO.
#'
#' @param p,lambda numeric (vetorizado).
#' @param custo numeric, custo por consulta.
#' @param lucro numeric, lucro medio desejado por cliente.
#' @return numeric.
premio_anual <- function(p, lambda, custo = CUSTO_CONSULTA, lucro = LUCRO_DESEJADO) {
  custo * esperanca_zip(p, lambda) + lucro
}
