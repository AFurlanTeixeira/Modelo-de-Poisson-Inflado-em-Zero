#' Configuracao global do laboratorio.
#'
#' Constantes do enunciado (custo da consulta, lucro desejado, prioris) e
#' parametros de execucao lidos de variaveis de ambiente (ver `.env.example`).
#' Nada aqui depende do estado global do RNG.

# Constantes do enunciado ----------------------------------------------------
CUSTO_CONSULTA <- 250
LUCRO_DESEJADO <- 100
PERFIS <- c("baixo", "medio", "alto")

# Prioris da Parte 3: p ~ Beta(A, B) e lambda ~ Gamma(ALPHA, BETA) (taxa)
PRIORI_P_A <- 1
PRIORI_P_B <- 1
PRIORI_LAMBDA_ALPHA <- 1
PRIORI_LAMBDA_BETA <- 0.01

#' Le os parametros de execucao a partir de variaveis de ambiente.
#'
#' @return list com `data_path`, `seed`, `n_iter`, `burn_in`, `n_cadeias`,
#'   `dir_processed` e `dir_figuras`.
config_lab <- function() {
  list(
    data_path = Sys.getenv("DATA_PATH", "data/raw/visitas_medicas.csv"),
    seed = as.integer(Sys.getenv("RANDOM_SEED", 524)),
    n_iter = as.integer(Sys.getenv("N_ITER_GIBBS", 20000)),
    burn_in = as.integer(Sys.getenv("BURN_IN", 2000)),
    n_cadeias = as.integer(Sys.getenv("N_CADEIAS", 3)),
    dir_processed = Sys.getenv("DIR_PROCESSED", "data/processed"),
    dir_figuras = Sys.getenv("DIR_FIGURAS", "docs/figuras")
  )
}
