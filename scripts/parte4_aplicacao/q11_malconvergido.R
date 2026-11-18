# Questao 11 -- Impacto de estimativas mal-convergidas sobre a precificacao.
#
# Simula situacoes realistas de ma convergencia (optim() interrompido cedo,
# EM parado na 1a iteracao, Gibbs curto sem burn-in e a falsa convergencia do
# BFGS em p = 0 encontrada na Parte 1.1) e calcula o premio e o lucro
# esperado resultante para uma carteira de 400 clientes por perfil.
#
# Uso: Rscript scripts/parte4_aplicacao/q11_malconvergido.R
#
# Saidas:
#   * data/processed/parte4_aplicacao/malconvergido.rds
#   * docs/figuras/parte4_aplicacao/q11_lucro_malconvergido.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)
emv_em <- ler_resultado("parte2_em", "emv_em", "scripts/parte2_em/q4_em.R", cfg)
multi <- ler_resultado(
  "parte1_otimizacao", "optim_multiplos_inicios", "scripts/parte1_otimizacao/q1_1_optim.R", cfg
)
N_CLIENTES <- 400

casos <- do.call(rbind, lapply(PERFIS, function(g) {
  s <- base$s_list[[g]]
  em1 <- em_zip(s, p0 = 0.95, lambda0 = 0.5, max_iter = 1)
  opt <- ajustar_optim(s, 0.9, 0.5, "Nelder-Mead", maxit = 15)
  gb <- gibbs_zip(s, n_iter = 30, p0 = 0.95, lambda0 = 0.5, seed = 1)
  presos <- multi[multi$perfil == g & multi$metodo == "BFGS" & multi$p < 1e-4, ]
  out <- data.frame(
    perfil = g,
    caso = c(
      "EMV correto", "EM parado na 1a iteracao", "optim, maxit = 15",
      "Gibbs, 30 iter. sem burn-in"
    ),
    p = c(emv_em$p[emv_em$perfil == g], em1$p, opt[["p"]], stats::median(gb[, "p"])),
    lambda = c(
      emv_em$lambda[emv_em$perfil == g], em1$lambda, opt[["lambda"]],
      stats::median(gb[, "lambda"])
    )
  )
  if (nrow(presos) > 0) {
    preso <- data.frame(
      perfil = g, caso = "BFGS preso em p = 0", p = presos$p[1], lambda = presos$lambda[1]
    )
    out <- rbind(out, preso)
  }
  out$premio <- premio_anual(out$p, out$lambda)
  out$lucro_cliente <- out$premio - CUSTO_CONSULTA * mean(base$y_list[[g]])
  out$resultado_carteira <- N_CLIENTES * out$lucro_cliente
  out
}))
rownames(casos) <- NULL
print(casos, digits = 5)

casos$perfil <- factor(casos$perfil, levels = PERFIS)
figura <- ggplot(casos, aes(resultado_carteira / 1000, caso, fill = resultado_carteira < 0)) +
  geom_col() +
  geom_vline(xintercept = N_CLIENTES * LUCRO_DESEJADO / 1000, linetype = 2) +
  scale_fill_manual(values = c(`FALSE` = "#4C78A8", `TRUE` = "#E45756"), guide = "none") +
  facet_wrap(~perfil) +
  labs(x = "Resultado esperado da carteira de 400 clientes (R$ mil)", y = NULL) +
  theme_minimal(base_size = 10)
salvar_figura(figura, "parte4_aplicacao", "q11_lucro_malconvergido", altura = 3.4, cfg = cfg)
salvar_resultado(casos, "parte4_aplicacao", "malconvergido", cfg)
