# Questao 7 -- Diagnostico de convergencia das cadeias.
#
# Trajetorias (inicio das cadeias e pos burn-in com media acumulada), R-hat de
# Gelman-Rubin, tamanho efetivo de amostra e autocorrelacao de lag 1.
#
# Uso: Rscript scripts/parte3_mcmc/q7_diagnostico.R
#
# Saidas:
#   * data/processed/parte3_mcmc/diagnosticos.rds
#   * docs/figuras/parte3_mcmc/q7_trajetorias_inicio.png
#   * docs/figuras/parte3_mcmc/q7_trajetorias_pos_burnin.png
#   * docs/figuras/parte3_mcmc/q7_autocorrelacao.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
cadeias <- ler_resultado("parte3_mcmc", "cadeias", "scripts/parte3_mcmc/q6_gibbs.R", cfg)

# 1. Tabela de diagnosticos -----------------------------------------------------
diagnosticos <- do.call(rbind, lapply(PERFIS, function(g) {
  data.frame(perfil = g, diagnosticos_mcmc(cadeias[[g]], cfg$burn_in))
}))
print(diagnosticos, digits = 4, row.names = FALSE)

# 2. Trajetorias ----------------------------------------------------------------
traj <- do.call(rbind, lapply(PERFIS, function(g) {
  do.call(rbind, lapply(seq_along(cadeias[[g]]), function(k) {
    ch <- cadeias[[g]][[k]]
    iter <- seq_len(nrow(ch))
    rbind(
      data.frame(perfil = g, cadeia = k, iter = iter, param = "p", valor = ch[, "p"]),
      data.frame(perfil = g, cadeia = k, iter = iter, param = "lambda", valor = ch[, "lambda"])
    )
  }))
}))
traj$perfil <- factor(traj$perfil, levels = PERFIS)
traj$cadeia <- factor(traj$cadeia)

fig_inicio <- ggplot(subset(traj, iter <= 3000), aes(iter, valor, colour = cadeia)) +
  geom_line(linewidth = 0.2, alpha = 0.8) +
  geom_vline(xintercept = cfg$burn_in, linetype = 2) +
  facet_grid(param ~ perfil, scales = "free_y") +
  labs(x = "Iteracao", y = NULL, colour = "Cadeia") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
salvar_figura(fig_inicio, "parte3_mcmc", "q7_trajetorias_inicio", altura = 5, cfg = cfg)

pos <- subset(traj, cadeia == "1" & iter > cfg$burn_in)
media_acumulada <- function(x) cumsum(x) / seq_along(x)
pos$media_acum <- stats::ave(pos$valor, pos$perfil, pos$param, FUN = media_acumulada)
fig_pos <- ggplot(pos, aes(iter, valor)) +
  geom_line(linewidth = 0.1, colour = "#4C78A8", alpha = 0.7) +
  geom_line(aes(y = media_acum), colour = "black") +
  facet_grid(param ~ perfil, scales = "free_y") +
  labs(x = "Iteracao", y = NULL) +
  theme_minimal(base_size = 10)
salvar_figura(fig_pos, "parte3_mcmc", "q7_trajetorias_pos_burnin", altura = 4.2, cfg = cfg)

# 3. Autocorrelacao (cadeia 1, pos burn-in) -----------------------------------
acf_df <- do.call(rbind, lapply(PERFIS, function(g) {
  ch <- cadeias[[g]][[1]][-seq_len(cfg$burn_in), ]
  do.call(rbind, lapply(c("p", "lambda"), function(v) {
    a <- stats::acf(ch[, v], lag.max = 30, plot = FALSE)
    data.frame(perfil = g, param = v, lag = a$lag[, 1, 1], acf = a$acf[, 1, 1])
  }))
}))
acf_df$perfil <- factor(acf_df$perfil, levels = PERFIS)
fig_acf <- ggplot(acf_df, aes(lag, acf)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_segment(aes(xend = lag, yend = 0), colour = "#4C78A8") +
  facet_grid(param ~ perfil) +
  labs(x = "Defasagem", y = "Autocorrelacao") +
  theme_minimal(base_size = 10)
salvar_figura(fig_acf, "parte3_mcmc", "q7_autocorrelacao", altura = 3.8, cfg = cfg)

salvar_resultado(diagnosticos, "parte3_mcmc", "diagnosticos", cfg)
