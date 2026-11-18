# Padrões de Código

## R (`R/`)

- Documentar toda função com roxygen2, incluindo tipos (`#' @param s list de estatisticas suficientes`, `#' @return numeric`).
- Comentários roxygen2 curtos explicando entrada, saída e a fórmula aplicada, e o "porquê" quando houver uma escolha de modelagem.
- `snake_case` para funções e variáveis, `SNAKE_CASE` para constantes; um arquivo `.R` por responsabilidade.
- Funções puras: recebem dados e retornam objetos novos, sem efeitos colaterais (quem escreve em disco são os scripts, via `salvar_resultado()` / `salvar_figura()`).
- As funções de verossimilhança recebem as **estatísticas suficientes** (`estatisticas_suficientes()`), não o vetor de dados, para que cada avaliação seja O(1).
- Base R dentro de `R/` (sem avaliação não padrão do `dplyr`), para manter as funções simples de testar e de usar no `lintr`.

## Scripts (`scripts/`)

- Um script por pergunta do enunciado, em `scripts/parteN_<tema>/qX_<assunto>.R`.
- Cabeçalho padrão: o que a pergunta pede, o comando para rodar e a lista de saídas (`.rds` e `.png`).
- Sempre rodar a partir da raiz do repositório; caminhos relativos à raiz.
- Dependências entre perguntas apenas via `ler_resultado()`. Nunca copiar código de outro script.
- Nas questões de derivação (Q1, Q3, Q5, Q9), o script faz uma verificação numérica do resultado derivado no relatório.

## Aleatoriedade e reprodutibilidade

- Toda função que sorteia recebe `seed` explicitamente (ex.: `gibbs_zip(..., seed = )`); nunca depender do estado global do RNG sem registrar a semente.
- A semente vem de `RANDOM_SEED` (padrão 524) via `config_lab()` e é impressa no relatório.

## Testes

- Testes em `tests/testthat/`, espelhando os módulos de `R/` (`test-*.R`).
- Funções determinísticas (score, Hessiana, EM): comparar com valores calculados à mão ou com derivadas numéricas.
- Funções estocásticas (Gibbs): testar propriedades (domínio, reprodutibilidade com a mesma semente, mediana próxima do EMV com n grande, $\hat R < 1{,}05$), não valores exatos.

## O que evitar

- Números mágicos: custo da consulta, lucro, hiperparâmetros das prioris etc. ficam nomeados em `R/config.R`.
- Loops onde a operação vetorizada resolve. Exceção: as iterações sequenciais de Newton-Raphson, EM e Gibbs, que são intrinsecamente sequenciais.
- Nomes de variáveis nos scripts que colidam com os helpers do relatório (`incluir_figura`, `arquivo_script`, `secao`, `kab`, `brl`).
