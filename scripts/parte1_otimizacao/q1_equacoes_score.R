# Questao 1 -- Verificacao numerica das equacoes de score.
#
# A derivacao esta em docs/relatorio/secoes/01_parte1_otimizacao.Rmd. Aqui
# checamos que (i) o score analitico coincide com o gradiente numerico,
# (ii) o score se anula no EMV de referencia (solucao das equacoes reduzidas
# via uniroot) e (iii) valem as identidades D(EMV) = n0 / n e
# (1 - p) lambda = media(y).
#
# Uso: Rscript scripts/parte1_otimizacao/q1_equacoes_score.R
#
# Saidas:
#   * data/processed/parte1_otimizacao/emv_referencia.rds
#   * data/processed/parte1_otimizacao/verificacao_score.rds

source("R/utils.R")
carregar_funcoes()

cfg <- config_lab()
base <- preparar_dados(cfg)

gradiente_numerico <- function(p, lambda, s, h = 1e-6) {
  c(
    (loglik_zip(p + h, lambda, s) - loglik_zip(p - h, lambda, s)) / (2 * h),
    (loglik_zip(p, lambda + h, s) - loglik_zip(p, lambda - h, s)) / (2 * h)
  )
}

ref <- t(vapply(base$s_list, emv_referencia, numeric(2)))

verificacao <- do.call(rbind, lapply(PERFIS, function(g) {
  s <- base$s_list[[g]]
  p <- ref[g, "p"]
  l <- ref[g, "lambda"]
  ponto_teste <- c(0.3, 2) # ponto arbitrario para comparar score analitico x numerico
  data.frame(
    perfil = g,
    erro_score_vs_numerico = max(abs(
      score_zip(ponto_teste[1], ponto_teste[2], s) -
        gradiente_numerico(ponto_teste[1], ponto_teste[2], s)
    )),
    norma_score_no_emv = sqrt(sum(score_zip(p, l, s)^2)),
    d_emv = p + (1 - p) * exp(-l),
    n0_sobre_n = s$n0 / s$n,
    media_zip = (1 - p) * l,
    media_amostral = s$S / s$n
  )
}))
print(verificacao, digits = 6)

emv_ref <- data.frame(perfil = PERFIS, p = ref[, "p"], lambda = ref[, "lambda"], row.names = NULL)
salvar_resultado(emv_ref, "parte1_otimizacao", "emv_referencia", cfg)
salvar_resultado(verificacao, "parte1_otimizacao", "verificacao_score", cfg)
