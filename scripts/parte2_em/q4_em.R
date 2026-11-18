# Questao 4 -- Implementacao do algoritmo EM e grafico de convergencia.
#
# Uso: Rscript scripts/parte2_em/q4_em.R
#
# Saidas:
#   * data/processed/parte2_em/{ajustes_em,emv_em,em_multiplos_inicios}.rds
#   * docs/figuras/parte2_em/q4_convergencia_em.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)

# 1. EM a partir de p0 = 0.5, lambda0 = media(y), tolerancia 1e-12 em l ------
ajustes <- lapply(base$s_list, em_zip)

emv_em <- data.frame(
  perfil = PERFIS,
  p = vapply(ajustes, `[[`, numeric(1), "p"),
  lambda = vapply(ajustes, `[[`, numeric(1), "lambda"),
  loglik = vapply(ajustes, function(a) a$loglik[length(a$loglik)], numeric(1)),
  iter = vapply(ajustes, `[[`, integer(1), "iter"),
  monotona = vapply(ajustes, function(a) all(diff(a$loglik) >= -1e-10), logical(1)),
  row.names = NULL
)
print(emv_em, digits = 7)

# 2. Grafico da log-verossimilhanca observada ao longo das iteracoes ----------
traj <- do.call(rbind, lapply(PERFIS, function(g) {
  ll <- ajustes[[g]]$loglik
  data.frame(perfil = g, iter = seq_along(ll) - 1, loglik = ll, distancia = max(ll) - ll)
}))
traj$perfil <- factor(traj$perfil, levels = PERFIS)

fig_ll <- ggplot(traj, aes(iter, loglik, colour = perfil)) +
  geom_line() +
  geom_point(size = 0.6) +
  facet_wrap(~perfil, scales = "free") +
  labs(x = "Iteracao", y = "Log-verossimilhanca observada") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none")
fig_dist <- ggplot(subset(traj, distancia > 0), aes(iter, distancia, colour = perfil)) +
  geom_line() +
  scale_y_log10() +
  labs(x = "Iteracao", y = "l* - l(t) (escala log)", colour = NULL) +
  theme_minimal(base_size = 10)
figura <- patchwork::wrap_plots(fig_ll, fig_dist, widths = c(2.2, 1))
salvar_figura(figura, "parte2_em", "q4_convergencia_em", altura = 3.3, cfg = cfg)

# 3. Robustez ao ponto inicial --------------------------------------------------
inicios <- expand.grid(perfil = PERFIS, p0 = c(0.01, 0.5, 0.99), lambda0 = c(0.3, 3, 10))
inicios$perfil <- as.character(inicios$perfil)
res <- t(mapply(function(g, p0, l0) {
  a <- em_zip(base$s_list[[g]], p0, l0)
  c(p = a$p, lambda = a$lambda, iter = a$iter)
}, inicios$perfil, inicios$p0, inicios$lambda0))
multi <- data.frame(inicios, res, row.names = NULL)
robustez <- do.call(rbind, lapply(PERFIS, function(g) {
  d <- multi[multi$perfil == g, ]
  data.frame(
    perfil = g, amplitude_p = diff(range(d$p)), amplitude_lambda = diff(range(d$lambda)),
    iter_min = min(d$iter), iter_max = max(d$iter)
  )
}))
print(robustez, digits = 4)

salvar_resultado(ajustes, "parte2_em", "ajustes_em", cfg)
salvar_resultado(emv_em, "parte2_em", "emv_em", cfg)
salvar_resultado(robustez, "parte2_em", "em_multiplos_inicios", cfg)
