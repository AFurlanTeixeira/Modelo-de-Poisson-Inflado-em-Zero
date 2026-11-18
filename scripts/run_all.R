#!/usr/bin/env Rscript
# Roda todos os scripts das perguntas, na ordem do enunciado.
#
# Exemplo (a partir da raiz do repositorio):
#   Rscript scripts/run_all.R
#   Rscript scripts/run_all.R --seed 524 --n-iter 20000 --burn-in 2000
#
# Flags sobrescrevem as variaveis de ambiente (ver `.env.example`). Os
# resultados vao para data/processed/ e as figuras para docs/figuras/.

args <- commandArgs(trailingOnly = TRUE)
flags <- c("--seed" = "RANDOM_SEED", "--n-iter" = "N_ITER_GIBBS", "--burn-in" = "BURN_IN")
for (flag in names(flags)) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) {
    do.call(Sys.setenv, stats::setNames(list(args[pos + 1]), flags[[flag]]))
  }
}

scripts <- c(
  "scripts/parte0_dados/resumo_descritivo.R",
  "scripts/parte1_otimizacao/q1_1_optim.R",
  "scripts/parte1_otimizacao/q1_equacoes_score.R",
  "scripts/parte1_otimizacao/q2_newton_raphson.R",
  "scripts/parte2_em/q3_derivacao_em.R",
  "scripts/parte2_em/q4_em.R",
  "scripts/parte3_mcmc/q5_condicionais.R",
  "scripts/parte3_mcmc/q6_gibbs.R",
  "scripts/parte3_mcmc/q7_diagnostico.R",
  "scripts/parte3_mcmc/q8_comparacao.R",
  "scripts/parte4_aplicacao/q9_valor_esperado.R",
  "scripts/parte4_aplicacao/q10_premio.R",
  "scripts/parte4_aplicacao/q11_malconvergido.R"
)

for (script in scripts) {
  cat("\n================", script, "================\n")
  source(script, local = new.env(), echo = FALSE)
}
cat("\nConcluido. Resultados em data/processed/ e figuras em docs/figuras/.\n")
