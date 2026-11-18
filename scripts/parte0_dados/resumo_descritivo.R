# Parte 0 -- Resumo descritivo dos dados por perfil.
#
# Uso (a partir da raiz do repositorio):
#   Rscript scripts/parte0_dados/resumo_descritivo.R
#
# Saidas:
#   * data/processed/parte0_dados/resumo.rds
#   * docs/figuras/parte0_dados/distribuicao_visitas.png

source("R/utils.R")
carregar_funcoes()
library(ggplot2)

cfg <- config_lab()
base <- preparar_dados(cfg)

resumo <- resumo_descritivo(base$dados)
print(resumo, digits = 3)
salvar_resultado(resumo, "parte0_dados", "resumo", cfg)

# Frequencia observada vs. esperada por uma Poisson com a mesma media
freq <- do.call(rbind, lapply(PERFIS, function(g) {
  y <- base$y_list[[g]]
  k <- 0:max(y)
  data.frame(
    perfil = g, k = k,
    observada = as.numeric(table(factor(y, levels = k))) / length(y),
    poisson = stats::dpois(k, mean(y))
  )
}))
freq$perfil <- factor(freq$perfil, levels = PERFIS)

grafico <- ggplot(freq, aes(k)) +
  geom_col(aes(y = observada), fill = "#4C78A8", alpha = 0.7) +
  geom_point(aes(y = poisson), colour = "#E45756") +
  geom_line(aes(y = poisson), colour = "#E45756") +
  facet_wrap(~perfil, scales = "free") +
  labs(
    x = "Numero de consultas no ano", y = "Proporcao",
    title = "Frequencia observada (barras) vs. Poisson com a mesma media (vermelho)"
  ) +
  theme_minimal(base_size = 10)
salvar_figura(grafico, "parte0_dados", "distribuicao_visitas", cfg = cfg)
