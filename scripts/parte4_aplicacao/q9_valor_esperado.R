# Questao 9 -- Verificacao por Monte Carlo de E[Y] = (1 - p) lambda.
#
# A derivacao esta em docs/relatorio/secoes/04_parte4_aplicacao.Rmd. Aqui
# simulamos o ZIP pela representacao de mistura (Z ~ Bernoulli(p); Y = 0 se
# Z = 1, Y ~ Poisson(lambda) se Z = 0) com os EMV de cada perfil e comparamos a
# media e a variancia simuladas com as formulas fechadas.
#
# Uso: Rscript scripts/parte4_aplicacao/q9_valor_esperado.R
#
# Saidas:
#   * data/processed/parte4_aplicacao/verificacao_esperanca.rds

source("R/utils.R")
carregar_funcoes()

cfg <- config_lab()
emv_em <- ler_resultado("parte2_em", "emv_em", "scripts/parte2_em/q4_em.R", cfg)

n_mc <- 1e6
set.seed(cfg$seed)
verificacao <- do.call(rbind, lapply(PERFIS, function(g) {
  e <- emv_em[emv_em$perfil == g, ]
  z <- stats::rbinom(n_mc, 1, e$p)
  y <- ifelse(z == 1, 0, stats::rpois(n_mc, e$lambda))
  data.frame(
    perfil = g,
    media_mc = mean(y), erro_mc = stats::sd(y) / sqrt(n_mc),
    esperanca_formula = esperanca_zip(e$p, e$lambda),
    variancia_mc = stats::var(y), variancia_formula = variancia_zip(e$p, e$lambda)
  )
}))
print(verificacao, digits = 5)
salvar_resultado(verificacao, "parte4_aplicacao", "verificacao_esperanca", cfg)
