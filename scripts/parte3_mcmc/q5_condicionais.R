# Questao 5 -- Verificacao numerica das condicionais completas.
#
# A derivacao esta em docs/relatorio/secoes/03_parte3_mcmc.Rmd. Aqui
# normalizamos numericamente o nucleo de cada condicional (obtido da posteriori
# conjunta, mantendo apenas os fatores que dependem do parametro) e comparamos
# com as densidades Beta e Gamma deduzidas analiticamente.
#
# Uso: Rscript scripts/parte3_mcmc/q5_condicionais.R
#
# Saidas:
#   * data/processed/parte3_mcmc/verificacao_condicionais.rds
#   * docs/figuras/parte3_mcmc/q5_condicionais.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)

# Log da posteriori conjunta aumentada (ate constante) para z fixo
log_conjunta <- function(p, lambda, s, soma_z) {
  soma_z * log(p) + (s$n - soma_z) * log(1 - p) +
    s$S * log(lambda) - (s$n - soma_z) * lambda +
    (PRIORI_P_A - 1) * log(p) + (PRIORI_P_B - 1) * log(1 - p) +
    (PRIORI_LAMBDA_ALPHA - 1) * log(lambda) - PRIORI_LAMBDA_BETA * lambda
}

normaliza <- function(x, logdens) {
  dens <- exp(logdens - max(logdens))
  dens / sum(dens * diff(x)[1])
}

curvas <- list()
verificacao <- do.call(rbind, lapply(PERFIS, function(g) {
  s <- base$s_list[[g]]
  soma_z <- round(s$n0 / 2) # configuracao arbitraria de z
  emv <- emv_referencia(s)

  grade_p <- seq(1e-4, 1 - 1e-4, length.out = 4000)
  num_p <- normaliza(grade_p, log_conjunta(grade_p, emv[["lambda"]], s, soma_z))
  beta_p <- stats::dbeta(grade_p, PRIORI_P_A + soma_z, PRIORI_P_B + s$n - soma_z)

  grade_l <- seq(0.01, 10, length.out = 4000)
  num_l <- normaliza(grade_l, log_conjunta(emv[["p"]], grade_l, s, soma_z))
  gamma_l <- stats::dgamma(
    grade_l,
    shape = PRIORI_LAMBDA_ALPHA + s$S, rate = PRIORI_LAMBDA_BETA + s$n - soma_z
  )

  curvas[[g]] <<- rbind(
    data.frame(perfil = g, param = "p", x = grade_p, numerica = num_p, analitica = beta_p),
    data.frame(perfil = g, param = "lambda", x = grade_l, numerica = num_l, analitica = gamma_l)
  )
  data.frame(
    perfil = g, soma_z = soma_z,
    erro_max_beta = max(abs(num_p - beta_p)) / max(beta_p),
    erro_max_gamma = max(abs(num_l - gamma_l)) / max(gamma_l)
  )
}))
print(verificacao, digits = 4)

curvas <- do.call(rbind, curvas)
curvas$perfil <- factor(curvas$perfil, levels = PERFIS)
pico <- stats::ave(curvas$analitica, curvas$perfil, curvas$param, FUN = max)
curvas <- curvas[curvas$analitica > 1e-3 * pico, ]
figura <- ggplot(curvas, aes(x)) +
  geom_line(aes(y = analitica), colour = "#4C78A8", linewidth = 1.2, alpha = 0.6) +
  geom_line(aes(y = numerica), colour = "#E45756", linetype = 2) +
  facet_wrap(param ~ perfil, scales = "free", nrow = 2, labeller = labeller(.multi_line = FALSE)) +
  labs(
    x = NULL, y = "Densidade",
    title = "Nucleo normalizado (tracejado) vs. Beta/Gamma analiticas"
  ) +
  theme_minimal(base_size = 10)
salvar_figura(figura, "parte3_mcmc", "q5_condicionais", altura = 4.2, cfg = cfg)
salvar_resultado(verificacao, "parte3_mcmc", "verificacao_condicionais", cfg)
