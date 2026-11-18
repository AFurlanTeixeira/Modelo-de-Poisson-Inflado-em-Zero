# Questao 6 -- Gibbs Sampler: estimativas pontuais e IC de credibilidade 95%.
#
# 3 cadeias de N_ITER_GIBBS iteracoes (padrao 20.000) a partir de inicios
# dispersos, descartando BURN_IN (padrao 2.000) de cada uma.
#
# Uso: Rscript scripts/parte3_mcmc/q6_gibbs.R
#
# Saidas:
#   * data/processed/parte3_mcmc/{cadeias,amostras_posteriori,resumo_posteriori}.rds

source("R/utils.R")
carregar_funcoes()

cfg <- config_lab()
base <- preparar_dados(cfg)
cat(sprintf(
  "Gibbs: %d cadeias x %d iteracoes, burn-in %d, seed %d\n",
  length(inicios_cadeias()), cfg$n_iter, cfg$burn_in, cfg$seed
))

tempo <- system.time({
  cadeias <- lapply(base$s_list, gibbs_varias_cadeias,
    inicios = inicios_cadeias(), n_iter = cfg$n_iter, seed = cfg$seed
  )
})
cat(sprintf("Tempo total: %.1f s\n", tempo[["elapsed"]]))

amostras <- do.call(rbind, lapply(PERFIS, function(g) {
  data.frame(perfil = g, amostras_posteriori(cadeias[[g]], cfg$burn_in))
}))
amostras$perfil <- factor(amostras$perfil, levels = PERFIS)

resumo <- do.call(rbind, lapply(PERFIS, function(g) {
  data.frame(perfil = g, resumo_posteriori(amostras[amostras$perfil == g, ]))
}))
print(resumo, digits = 4, row.names = FALSE)

salvar_resultado(cadeias, "parte3_mcmc", "cadeias", cfg)
salvar_resultado(amostras, "parte3_mcmc", "amostras_posteriori", cfg)
salvar_resultado(resumo, "parte3_mcmc", "resumo_posteriori", cfg)
