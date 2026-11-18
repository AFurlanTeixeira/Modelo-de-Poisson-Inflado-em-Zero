#' Carregamento dos dados e estatisticas suficientes.
#'
#' Sem regra de negocio: so leitura, tipagem e validacao basica do CSV do
#' enunciado (`data/raw/visitas_medicas.csv`).

#' Carrega o CSV de visitas medicas.
#'
#' @param caminho character, caminho do CSV com colunas `id`, `perfil`,
#'   `visitas`.
#' @return data.frame com `perfil` como fator nos niveis de `PERFIS`.
carregar_visitas <- function(caminho) {
  dados <- utils::read.csv(caminho, stringsAsFactors = FALSE)
  esperadas <- c("id", "perfil", "visitas")
  faltando <- setdiff(esperadas, names(dados))
  if (length(faltando) > 0) {
    stop("Colunas ausentes no CSV: ", paste(faltando, collapse = ", "))
  }
  if (any(dados$visitas < 0) || any(dados$visitas != round(dados$visitas))) {
    stop("`visitas` deve conter apenas inteiros nao negativos.")
  }
  if (!all(dados$perfil %in% PERFIS)) {
    stop("Perfis desconhecidos: ", paste(setdiff(dados$perfil, PERFIS), collapse = ", "))
  }
  dados$perfil <- factor(dados$perfil, levels = PERFIS)
  dados
}

#' Separa o vetor de contagens por perfil.
#'
#' @param dados data.frame retornado por `carregar_visitas()`.
#' @return list nomeada (baixo, medio, alto) de vetores inteiros.
contagens_por_perfil <- function(dados) {
  split(dados$visitas, dados$perfil)
}

#' Estatisticas suficientes do modelo ZIP.
#'
#' A log-verossimilhanca depende dos dados apenas por n0 (zeros), n+ (positivos)
#' e S (soma); `C = sum(log(y!))` so entra como constante aditiva.
#'
#' @param y vetor de contagens.
#' @return list com `n`, `n0`, `np`, `S`, `C`.
estatisticas_suficientes <- function(y) {
  list(
    n = length(y), n0 = sum(y == 0), np = sum(y > 0),
    S = sum(y), C = sum(lfactorial(y))
  )
}

#' Resumo descritivo por perfil.
#'
#' @param dados data.frame retornado por `carregar_visitas()`.
#' @return data.frame com n, zeros, proporcao de zeros, media, variancia e a
#'   proporcao de zeros esperada por uma Poisson com a mesma media.
resumo_descritivo <- function(dados) {
  y_list <- contagens_por_perfil(dados)
  data.frame(
    perfil = names(y_list),
    n = vapply(y_list, length, integer(1)),
    zeros = vapply(y_list, function(y) sum(y == 0), integer(1)),
    prop_zeros = vapply(y_list, function(y) mean(y == 0), numeric(1)),
    media = vapply(y_list, mean, numeric(1)),
    variancia = vapply(y_list, stats::var, numeric(1)),
    p0_poisson = vapply(y_list, function(y) exp(-mean(y)), numeric(1)),
    maximo = vapply(y_list, max, numeric(1)),
    row.names = NULL
  )
}
