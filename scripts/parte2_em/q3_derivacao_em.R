# Questao 3 -- Verificacao numerica dos passos E e M.
#
# A derivacao esta em docs/relatorio/secoes/02_parte2_em.Rmd. Aqui checamos que
# (i) os pesos w_i do passo E coincidem com P(Z_i = 1 | y_i) calculada pela
# definicao (Bayes) e (ii) as atualizacoes fechadas do passo M maximizam a
# funcao Q (comparando com optim() aplicado a Q) e (iii) toda iteracao do EM
# satisfaz (1 - p) lambda = media(y).
#
# Uso: Rscript scripts/parte2_em/q3_derivacao_em.R
#
# Saidas:
#   * data/processed/parte2_em/verificacao_passos_em.rds

source("R/utils.R")
carregar_funcoes()

cfg <- config_lab()
base <- preparar_dados(cfg)

# Ponto arbitrario (p_t, lambda_t) para um passo do EM
p_t <- 0.4
lambda_t <- 2.5

funcao_q <- function(par, y, w) {
  p <- par[1]
  l <- par[2]
  sum(w * log(p) + (1 - w) * log(1 - p)) + sum((1 - w) * (-l + y * log(l)))
}

verificacao <- do.call(rbind, lapply(PERFIS, function(g) {
  y <- base$y_list[[g]]
  # (i) Passo E pela definicao: P(Z=1, Y=y) / P(Y=y)
  conj_z1 <- p_t * (y == 0)
  conj_z0 <- (1 - p_t) * stats::dpois(y, lambda_t)
  w_bayes <- conj_z1 / (conj_z1 + conj_z0)
  w <- pesos_em(y, p_t, lambda_t)

  # (ii) Passo M fechado x maximizacao numerica de Q
  p_fechado <- mean(w)
  lambda_fechado <- sum((1 - w) * y) / sum(1 - w)
  num <- stats::optim(
    c(0.5, 1), function(par) -funcao_q(par, y, w),
    method = "L-BFGS-B", lower = c(1e-6, 1e-6), upper = c(1 - 1e-6, 100)
  )$par

  # (iii) Media preservada apos um passo
  data.frame(
    perfil = g,
    erro_passo_e = max(abs(w - w_bayes)),
    p_fechado = p_fechado, p_numerico = num[1],
    lambda_fechado = lambda_fechado, lambda_numerico = num[2],
    media_apos_passo = (1 - p_fechado) * lambda_fechado,
    media_amostral = mean(y)
  )
}))
print(verificacao, digits = 6)
salvar_resultado(verificacao, "parte2_em", "verificacao_passos_em", cfg)
