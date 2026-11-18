# Parte 1.1 -- EMV via optim() com reparametrizacao e multiplos pontos iniciais.
#
# Maximiza a log-verossimilhanca do ZIP na escala irrestrita
# (logit p, log lambda), a partir de uma grade de 20 pontos iniciais e com dois
# metodos (Nelder-Mead e BFGS), para verificar se as estimativas convergem
# para o mesmo valor.
#
# Uso: Rscript scripts/parte1_otimizacao/q1_1_optim.R
#
# Saidas:
#   * data/processed/parte1_otimizacao/optim_multiplos_inicios.rds
#   * data/processed/parte1_otimizacao/emv_optim.rds
#   * docs/figuras/parte1_otimizacao/q1_1_ajuste_optim.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)

# 1. Grade de pontos iniciais x metodos ---------------------------------------
multi <- do.call(rbind, lapply(PERFIS, function(g) {
  data.frame(perfil = g, optim_multiplos_inicios(base$s_list[[g]], grade_inicios()))
}))
multi$perfil <- factor(multi$perfil, levels = PERFIS)

# Solucoes distintas encontradas (arredondadas) e quantos inicios levaram a cada uma
solucoes <- aggregate(
  p0 ~ perfil + metodo + p + lambda + loglik + convergencia,
  data = transform(multi, p = round(p, 4), lambda = round(lambda, 4), loglik = round(loglik, 3)),
  FUN = length
)
names(solucoes)[names(solucoes) == "p0"] <- "n_inicios"
solucoes <- solucoes[order(solucoes$perfil, solucoes$metodo, solucoes$loglik), ]
print(solucoes, row.names = FALSE)

# 2. EMV final: melhor log-verossimilhanca entre todos os inicios -------------
emv_optim <- do.call(rbind, lapply(split(multi, multi$perfil), function(d) {
  d[which.max(d$loglik), c("perfil", "p", "lambda", "loglik")]
}))
rownames(emv_optim) <- NULL
print(emv_optim)

salvar_resultado(multi, "parte1_otimizacao", "optim_multiplos_inicios", cfg)
salvar_resultado(solucoes, "parte1_otimizacao", "optim_solucoes", cfg)
salvar_resultado(emv_optim, "parte1_otimizacao", "emv_optim", cfg)

# 3. Ajuste: frequencias observadas vs. Poisson vs. ZIP ------------------------
ajuste <- do.call(rbind, lapply(PERFIS, function(g) {
  y <- base$y_list[[g]]
  e <- emv_optim[emv_optim$perfil == g, ]
  k <- 0:max(y)
  zip <- (1 - e$p) * stats::dpois(k, e$lambda) + e$p * (k == 0)
  rbind(
    data.frame(
      perfil = g, k = k, modelo = "Observada", prob = tabulate(y + 1, length(k)) / length(y)
    ),
    data.frame(perfil = g, k = k, modelo = "Poisson", prob = stats::dpois(k, mean(y))),
    data.frame(perfil = g, k = k, modelo = "ZIP (EMV)", prob = zip)
  )
}))
ajuste$perfil <- factor(ajuste$perfil, levels = PERFIS)

grafico <- ggplot(ajuste, aes(k, prob, fill = modelo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  scale_fill_manual(
    values = c(Observada = "grey55", Poisson = "#E45756", `ZIP (EMV)` = "#4C78A8")
  ) +
  facet_wrap(~perfil, scales = "free") +
  labs(x = "Numero de consultas", y = "Probabilidade", fill = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
salvar_figura(grafico, "parte1_otimizacao", "q1_1_ajuste_optim", cfg = cfg)
