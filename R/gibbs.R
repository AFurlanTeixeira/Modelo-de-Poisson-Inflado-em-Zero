#' Gibbs Sampler com aumento de dados para o ZIP (Parte 3, Questoes 6 e 7).
#'
#' Condicionais completas (ver `.ai/modelagem.md`, ADR-004):
#'   Z_i | resto ~ Bernoulli(p / (p + (1 - p) e^-lambda)) se y_i = 0; Z_i = 0 se y_i > 0
#'   p | z ~ Beta(a + sum z, b + n - sum z)
#'   lambda | y, z ~ Gamma(alpha + S, beta + n - sum z)   (forma, taxa)
#' Como so sum(Z) entra nas condicionais de p e lambda e os Z_i dos zeros sao
#' iid dado (p, lambda), sortear sum(Z) ~ Binomial(n0, pi) e equivalente a
#' sortear os n0 indicadores e soma-los.

#' Roda uma cadeia do Gibbs Sampler.
#'
#' @param s list de estatisticas suficientes.
#' @param n_iter integer, numero de iteracoes.
#' @param p0,lambda0 numeric, valores iniciais.
#' @param seed integer ou NULL; se informado, fixa a semente da cadeia.
#' @param a,b numeric, hiperparametros da priori Beta de p.
#' @param alpha,beta numeric, hiperparametros da priori Gamma (forma, taxa).
#' @return matrix n_iter x 3 (colunas p, lambda, soma_z).
gibbs_zip <- function(s, n_iter = 20000, p0 = 0.5, lambda0 = 1, seed = NULL,
                      a = PRIORI_P_A, b = PRIORI_P_B,
                      alpha = PRIORI_LAMBDA_ALPHA, beta = PRIORI_LAMBDA_BETA) {
  if (!is.null(seed)) set.seed(seed)
  saida <- matrix(NA_real_, n_iter, 3, dimnames = list(NULL, c("p", "lambda", "soma_z")))
  p <- p0
  lambda <- lambda0
  for (t in seq_len(n_iter)) {
    prob_estrutural <- p / (p + (1 - p) * exp(-lambda))
    soma_z <- stats::rbinom(1, s$n0, prob_estrutural)
    p <- stats::rbeta(1, a + soma_z, b + s$n - soma_z)
    lambda <- stats::rgamma(1, shape = alpha + s$S, rate = beta + s$n - soma_z)
    saida[t, ] <- c(p, lambda, soma_z)
  }
  saida
}

#' Roda varias cadeias a partir de pontos iniciais dispersos.
#'
#' @param s list de estatisticas suficientes.
#' @param inicios list de vetores c(p0, lambda0), um por cadeia.
#' @param n_iter integer, iteracoes por cadeia.
#' @param seed integer, semente base (cadeia k usa seed + k).
#' @return list de matrizes (uma por cadeia).
gibbs_varias_cadeias <- function(s, inicios, n_iter, seed) {
  lapply(seq_along(inicios), function(k) {
    gibbs_zip(s, n_iter, inicios[[k]][1], inicios[[k]][2], seed = seed + k)
  })
}

#' Inicios dispersos padrao das cadeias.
#'
#' @return list de tres vetores c(p0, lambda0).
inicios_cadeias <- function() {
  list(c(0.05, 0.5), c(0.5, 3), c(0.95, 10))
}

#' Empilha as cadeias apos descartar o burn-in.
#'
#' @param cadeias list de matrizes de `gibbs_varias_cadeias()`.
#' @param burn_in integer, iteracoes iniciais descartadas de cada cadeia.
#' @return data.frame com colunas p, lambda, soma_z e cadeia.
amostras_posteriori <- function(cadeias, burn_in) {
  partes <- lapply(seq_along(cadeias), function(k) {
    x <- cadeias[[k]][-seq_len(burn_in), , drop = FALSE]
    data.frame(x, cadeia = k)
  })
  do.call(rbind, partes)
}

#' Resumo a posteriori: media, mediana e IC de credibilidade.
#'
#' @param amostras data.frame de `amostras_posteriori()`.
#' @param nivel numeric, nivel do intervalo de credibilidade.
#' @return data.frame com uma linha por parametro (p, lambda).
resumo_posteriori <- function(amostras, nivel = 0.95) {
  probs <- c((1 - nivel) / 2, 1 - (1 - nivel) / 2)
  do.call(rbind, lapply(c("p", "lambda"), function(v) {
    x <- amostras[[v]]
    q <- stats::quantile(x, probs, names = FALSE)
    data.frame(param = v, media = mean(x), mediana = stats::median(x), li = q[1], ls = q[2])
  }))
}

#' Diagnosticos de convergencia: R-hat de Gelman-Rubin, ESS e autocorrelacao.
#'
#' @param cadeias list de matrizes de `gibbs_varias_cadeias()`.
#' @param burn_in integer.
#' @return data.frame com uma linha por parametro.
diagnosticos_mcmc <- function(cadeias, burn_in) {
  lista <- coda::mcmc.list(lapply(cadeias, function(ch) {
    coda::mcmc(ch[-seq_len(burn_in), c("p", "lambda")])
  }))
  rhat <- coda::gelman.diag(lista, autoburnin = FALSE)$psrf[, 1]
  ess <- coda::effectiveSize(lista)
  acf1 <- vapply(c("p", "lambda"), function(v) {
    stats::acf(lista[[1]][, v], plot = FALSE, lag.max = 1)$acf[2]
  }, numeric(1))
  data.frame(param = c("p", "lambda"), rhat = rhat, ess = ess, acf_lag1 = acf1, row.names = NULL)
}
