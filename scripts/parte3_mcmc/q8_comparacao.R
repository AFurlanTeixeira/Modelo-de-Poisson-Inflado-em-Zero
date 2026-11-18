# Questao 8 -- Comparacao final: Bayes (mediana e IC credibilidade) x EMV.
#
# Uso: Rscript scripts/parte3_mcmc/q8_comparacao.R
#
# Saidas:
#   * data/processed/parte3_mcmc/comparacao_metodos.rds
#   * docs/figuras/parte3_mcmc/q8_posteriori_vs_emv.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)
script_optim <- "scripts/parte1_otimizacao/q1_1_optim.R"
script_gibbs <- "scripts/parte3_mcmc/q6_gibbs.R"
emv_optim <- ler_resultado("parte1_otimizacao", "emv_optim", script_optim, cfg)
emv_em <- ler_resultado("parte2_em", "emv_em", "scripts/parte2_em/q4_em.R", cfg)
resumo_post <- ler_resultado("parte3_mcmc", "resumo_posteriori", script_gibbs, cfg)
amostras <- ler_resultado("parte3_mcmc", "amostras_posteriori", script_gibbs, cfg)

comparacao <- do.call(rbind, lapply(PERFIS, function(g) {
  o <- emv_optim[emv_optim$perfil == g, ]
  e <- emv_em[emv_em$perfil == g, ]
  ic <- ic_wald_zip(e$p, e$lambda, base$s_list[[g]])
  b <- resumo_post[resumo_post$perfil == g, ]
  rbind(
    data.frame(
      perfil = g, metodo = "optim()", param = c("p", "lambda"),
      estimativa = c(o$p, o$lambda), li = NA, ls = NA
    ),
    data.frame(
      perfil = g, metodo = "EM (IC de Wald)", param = c("p", "lambda"),
      estimativa = c(e$p, e$lambda), li = ic[, "li"], ls = ic[, "ls"]
    ),
    data.frame(
      perfil = g, metodo = "Bayes (mediana, IC cred.)", param = b$param,
      estimativa = b$mediana, li = b$li, ls = b$ls
    )
  )
}))
rownames(comparacao) <- NULL
print(comparacao, digits = 4)

wald <- subset(comparacao, metodo == "EM (IC de Wald)")
wald$perfil <- factor(wald$perfil, levels = PERFIS)
dens <- rbind(
  data.frame(perfil = amostras$perfil, param = "p", valor = amostras$p),
  data.frame(perfil = amostras$perfil, param = "lambda", valor = amostras$lambda)
)
figura <- ggplot(dens, aes(valor)) +
  geom_density(fill = "#4C78A8", alpha = 0.35, colour = "#4C78A8") +
  geom_vline(data = wald, aes(xintercept = estimativa), colour = "red") +
  geom_vline(data = wald, aes(xintercept = li), colour = "red", linetype = 2) +
  geom_vline(data = wald, aes(xintercept = ls), colour = "red", linetype = 2) +
  facet_wrap(param ~ perfil, scales = "free", nrow = 2, labeller = labeller(.multi_line = FALSE)) +
  labs(x = NULL, y = "Densidade") +
  theme_minimal(base_size = 10)
salvar_figura(figura, "parte3_mcmc", "q8_posteriori_vs_emv", altura = 3.8, cfg = cfg)
salvar_resultado(comparacao, "parte3_mcmc", "comparacao_metodos", cfg)
