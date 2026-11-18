# Questao 10 -- Valor anual a cobrar por perfil e por metodo de estimacao.
#
# Premio = 250 * (1 - p) * lambda + 100, com (p, lambda) estimados por optim(),
# Newton-Raphson, EM e Bayes (plug-in das medianas). Para o Bayesiano tambem
# reportamos a mediana a posteriori do proprio premio e seu IC de 95%.
#
# Uso: Rscript scripts/parte4_aplicacao/q10_premio.R
#
# Saidas:
#   * data/processed/parte4_aplicacao/premios.rds
#   * docs/figuras/parte4_aplicacao/q10_premios.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)
dir_p1 <- "scripts/parte1_otimizacao"
script_gibbs <- "scripts/parte3_mcmc/q6_gibbs.R"
emv_optim <- ler_resultado("parte1_otimizacao", "emv_optim", file.path(dir_p1, "q1_1_optim.R"), cfg)
nr <- ler_resultado(
  "parte1_otimizacao", "newton_raphson", file.path(dir_p1, "q2_newton_raphson.R"), cfg
)
emv_em <- ler_resultado("parte2_em", "emv_em", "scripts/parte2_em/q4_em.R", cfg)
resumo_post <- ler_resultado("parte3_mcmc", "resumo_posteriori", script_gibbs, cfg)
amostras <- ler_resultado("parte3_mcmc", "amostras_posteriori", script_gibbs, cfg)

nr_final <- nr[nr$iter == max(nr$iter), ]
mediana <- function(g, v) resumo_post$mediana[resumo_post$perfil == g & resumo_post$param == v]
premio_de <- function(tab, g) premio_anual(tab$p[tab$perfil == g], tab$lambda[tab$perfil == g])

premios <- do.call(rbind, lapply(PERFIS, function(g) {
  pr_post <- premio_anual(amostras$p[amostras$perfil == g], amostras$lambda[amostras$perfil == g])
  q <- stats::quantile(pr_post, c(0.025, 0.975), names = FALSE)
  data.frame(
    perfil = g,
    media_amostral = mean(base$y_list[[g]]),
    optim = premio_de(emv_optim, g),
    newton_raphson = premio_de(nr_final, g),
    em = premio_de(emv_em, g),
    bayes_plugin = premio_anual(mediana(g, "p"), mediana(g, "lambda")),
    bayes_mediana_premio = stats::median(pr_post),
    bayes_li = q[1], bayes_ls = q[2]
  )
}))
print(premios, digits = 6, row.names = FALSE)

longo <- rbind(
  data.frame(perfil = premios$perfil, metodo = "optim()", premio = premios$optim),
  data.frame(perfil = premios$perfil, metodo = "Newton-Raphson", premio = premios$newton_raphson),
  data.frame(perfil = premios$perfil, metodo = "EM", premio = premios$em),
  data.frame(perfil = premios$perfil, metodo = "Bayes (plug-in)", premio = premios$bayes_plugin)
)
longo$perfil <- factor(longo$perfil, levels = PERFIS)
ic <- data.frame(
  perfil = factor(premios$perfil, levels = PERFIS), li = premios$bayes_li, ls = premios$bayes_ls
)

figura <- ggplot(longo, aes(perfil, premio, colour = metodo)) +
  geom_errorbar(
    data = ic, aes(x = perfil, ymin = li, ymax = ls),
    inherit.aes = FALSE, width = 0.25, colour = "grey50"
  ) +
  geom_point(position = position_dodge(width = 0.5), size = 2.5) +
  labs(
    x = "Perfil", y = "Premio anual (R$)", colour = "Metodo",
    caption = "Barras: IC de credibilidade de 95% do premio (Bayes)"
  ) +
  theme_minimal(base_size = 10)
salvar_figura(figura, "parte4_aplicacao", "q10_premios", largura = 7, altura = 3.6, cfg = cfg)
salvar_resultado(premios, "parte4_aplicacao", "premios", cfg)
