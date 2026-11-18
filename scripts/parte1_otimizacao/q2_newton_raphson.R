# Questao 2 -- Analise da Hessiana e implementacao do Newton-Raphson.
#
# (i) Autovalores da Hessiana no EMV; (ii) mapa da regiao em que a Hessiana e
# negativa-definida, com curvas de nivel de l(p, lambda); (iii) 10 iteracoes
# de Newton-Raphson a partir do metodo dos momentos; (iv) comparacao com
# optim() e com a solucao de referencia; (v) Newton-Raphson a partir de
# inicios ruins, para ilustrar a fragilidade global.
#
# Uso: Rscript scripts/parte1_otimizacao/q2_newton_raphson.R
#
# Saidas:
#   * data/processed/parte1_otimizacao/{autovalores_hessiana,newton_raphson,
#   * comparacao_nr,newton_inicios_ruins}.rds
#   * docs/figuras/parte1_otimizacao/q2_regiao_concavidade.png
#   * docs/figuras/parte1_otimizacao/q2_convergencia_nr.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)
dir_p1 <- "scripts/parte1_otimizacao"
emv_optim <- ler_resultado("parte1_otimizacao", "emv_optim", file.path(dir_p1, "q1_1_optim.R"), cfg)
emv_ref <- ler_resultado(
  "parte1_otimizacao", "emv_referencia", file.path(dir_p1, "q1_equacoes_score.R"), cfg
)

# 1. Autovalores da Hessiana no EMV --------------------------------------------
autovalores <- vapply(PERFIS, function(g) {
  e <- emv_ref[emv_ref$perfil == g, ]
  eigen(hessiana_zip(e$p, e$lambda, base$s_list[[g]]), symmetric = TRUE)$values
}, numeric(2))
print(autovalores)

# 2. Regiao de concavidade + curvas de nivel ------------------------------------
grade <- do.call(rbind, lapply(PERFIS, function(g) {
  s <- base$s_list[[g]]
  pontos <- expand.grid(
    p = seq(0.005, 0.995, length.out = 120),
    lambda = seq(0.05, 10, length.out = 120)
  )
  pontos$ll <- mapply(loglik_zip, pontos$p, pontos$lambda, MoreArgs = list(s = s))
  pontos$neg_def <- mapply(
    hessiana_negativa_definida, pontos$p, pontos$lambda,
    MoreArgs = list(s = s)
  )
  pontos$ll_rel <- pmax(pontos$ll - max(pontos$ll), -150)
  pontos$perfil <- g
  pontos
}))
grade$perfil <- factor(grade$perfil, levels = PERFIS)
emv_ref$perfil <- factor(emv_ref$perfil, levels = PERFIS)

fig_concav <- ggplot(grade, aes(lambda, p)) +
  geom_raster(aes(fill = neg_def), alpha = 0.5) +
  geom_contour(aes(z = ll_rel), bins = 15, colour = "grey30", linewidth = 0.25) +
  geom_point(data = emv_ref, colour = "red", size = 2) +
  scale_fill_manual(
    values = c(`TRUE` = "#4C78A8", `FALSE` = "grey92"),
    labels = c(`TRUE` = "negativa-definida", `FALSE` = "indefinida"), name = "Hessiana"
  ) +
  facet_wrap(~perfil) +
  labs(x = expression(lambda), y = "p") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
salvar_figura(fig_concav, "parte1_otimizacao", "q2_regiao_concavidade", altura = 3.4, cfg = cfg)

# 3. Newton-Raphson: 10 iteracoes a partir do metodo dos momentos --------------
nr <- do.call(rbind, lapply(PERFIS, function(g) {
  ini <- inicio_momentos(base$y_list[[g]])
  data.frame(perfil = g, newton_raphson_zip(base$s_list[[g]], ini[["p0"]], ini[["lambda0"]], 10))
}))
nr$perfil <- factor(nr$perfil, levels = PERFIS)
print(nr[nr$iter %in% c(0:4, 10), ], row.names = FALSE, digits = 7)

fig_conv <- ggplot(subset(nr, norma_score > 0), aes(iter, norma_score, colour = perfil)) +
  geom_line() +
  geom_point() +
  scale_y_log10() +
  scale_x_continuous(breaks = 0:10) +
  labs(x = "Iteracao", y = "Norma do score (escala log)", colour = "Perfil") +
  theme_minimal(base_size = 10)
salvar_figura(fig_conv, "parte1_otimizacao", "q2_convergencia_nr",
  largura = 6, altura = 3.2, cfg = cfg
)

# 4. Comparacao: optim() x Newton-Raphson x referencia -------------------------
final_nr <- nr[nr$iter == 10, ]
comparacao <- data.frame(
  perfil = PERFIS,
  p_optim = emv_optim$p, p_nr = final_nr$p, p_ref = emv_ref$p,
  lambda_optim = emv_optim$lambda, lambda_nr = final_nr$lambda, lambda_ref = emv_ref$lambda
)
print(comparacao, digits = 7)

# 5. Inicios ruins ----------------------------------------------------------------
inicios_ruins <- list(c(0.5, 1), c(0.1, 10), c(0.05, 0.5))
ruins <- do.call(rbind, lapply(PERFIS, function(g) {
  do.call(rbind, lapply(inicios_ruins, function(ini) {
    traj <- newton_raphson_zip(base$s_list[[g]], ini[1], ini[2], 10)
    ultimo <- traj[nrow(traj), ]
    p_ref <- emv_ref$p[emv_ref$perfil == g]
    resultado <- if (is.na(ultimo$loglik)) {
      "saiu do dominio"
    } else if (abs(ultimo$p - p_ref) < 1e-6) {
      "convergiu ao EMV"
    } else {
      "outro ponto"
    }
    data.frame(
      perfil = g, p0 = ini[1], lambda0 = ini[2], iter_final = ultimo$iter,
      p = ultimo$p, lambda = ultimo$lambda, resultado = resultado
    )
  }))
}))
print(ruins, row.names = FALSE, digits = 4)

salvar_resultado(autovalores, "parte1_otimizacao", "autovalores_hessiana", cfg)
salvar_resultado(nr, "parte1_otimizacao", "newton_raphson", cfg)
salvar_resultado(comparacao, "parte1_otimizacao", "comparacao_nr", cfg)
salvar_resultado(ruins, "parte1_otimizacao", "newton_inicios_ruins", cfg)
