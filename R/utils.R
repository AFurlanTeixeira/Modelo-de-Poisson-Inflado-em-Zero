#' Utilitarios de entrada/saida e formatacao usados pelos scripts e relatorio.

#' Carrega todas as funcoes de R/ a partir da raiz do repositorio.
#'
#' @param raiz character, caminho da raiz do repositorio.
#' @return invisivel, os arquivos carregados.
carregar_funcoes <- function(raiz = ".") {
  arquivos <- list.files(file.path(raiz, "R"), pattern = "\\.R$", full.names = TRUE)
  for (arquivo in arquivos) source(arquivo)
  invisible(arquivos)
}

#' Carrega os dados e calcula contagens e estatisticas suficientes por perfil.
#'
#' @param cfg list de `config_lab()`.
#' @return list com `dados`, `y_list` e `s_list`.
preparar_dados <- function(cfg = config_lab()) {
  dados <- carregar_visitas(cfg$data_path)
  y_list <- contagens_por_perfil(dados)
  list(dados = dados, y_list = y_list, s_list = lapply(y_list, estatisticas_suficientes))
}

#' Salva um resultado intermediario em data/processed/<parte>/<nome>.rds.
#'
#' @param objeto qualquer objeto R.
#' @param parte character, subpasta (ex.: "parte1_otimizacao").
#' @param nome character, nome do arquivo sem extensao.
#' @param cfg list de `config_lab()`.
#' @return invisivel, o caminho salvo.
salvar_resultado <- function(objeto, parte, nome, cfg = config_lab()) {
  dir <- file.path(cfg$dir_processed, parte)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  caminho <- file.path(dir, paste0(nome, ".rds"))
  saveRDS(objeto, caminho)
  invisible(caminho)
}

#' Le um resultado intermediario; se nao existir, roda o script que o gera.
#'
#' Permite rodar qualquer script de pergunta isoladamente: as dependencias
#' sao recalculadas sob demanda.
#'
#' @param parte,nome ver `salvar_resultado()`.
#' @param script character, script que gera o resultado.
#' @param cfg list de `config_lab()`.
#' @return o objeto salvo.
ler_resultado <- function(parte, nome, script, cfg = config_lab()) {
  caminho <- file.path(cfg$dir_processed, parte, paste0(nome, ".rds"))
  if (!file.exists(caminho)) {
    message("Resultado ", caminho, " ausente; rodando ", script)
    source(script, local = new.env())
  }
  readRDS(caminho)
}

#' Salva um grafico ggplot em docs/figuras/<parte>/<nome>.png.
#'
#' @param grafico objeto ggplot (ou patchwork).
#' @param parte,nome ver `salvar_resultado()`.
#' @param largura,altura numeric, em polegadas.
#' @param cfg list de `config_lab()`.
#' @return invisivel, o caminho salvo.
salvar_figura <- function(grafico, parte, nome, largura = 8, altura = 3.6, cfg = config_lab()) {
  dir <- file.path(cfg$dir_figuras, parte)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  caminho <- file.path(dir, paste0(nome, ".png"))
  ggplot2::ggsave(caminho, grafico, width = largura, height = altura, dpi = 150, bg = "white")
  invisible(caminho)
}

#' Formata numeros no padrao brasileiro (virgula decimal, ponto de milhar).
#'
#' @param x numeric.
#' @param digitos integer, casas decimais.
#' @return character.
fmt_br <- function(x, digitos = 4) {
  formatC(x, format = "f", digits = digitos, big.mark = ".", decimal.mark = ",")
}
