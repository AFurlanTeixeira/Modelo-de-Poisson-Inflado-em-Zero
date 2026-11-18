# Testes de `R/verossimilhanca.R`.

y_teste <- c(rep(0, 30), c(1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 1, 2, 3, 2, 4))
s_teste <- estatisticas_suficientes(y_teste)

test_that("loglik coincide com a soma dos logs da fmp do ZIP", {
  p <- 0.3
  l <- 2.2
  fmp <- ifelse(y_teste == 0, p + (1 - p) * exp(-l), (1 - p) * dpois(y_teste, l))
  expect_equal(loglik_zip(p, l, s_teste), sum(log(fmp)))
})

test_that("loglik em p = 0 e a Poisson e fora do dominio e -Inf", {
  expect_equal(loglik_zip(0, 2, s_teste), sum(dpois(y_teste, 2, log = TRUE)))
  expect_equal(loglik_zip(1, 2, s_teste), -Inf)
  expect_equal(loglik_zip(0.5, -1, s_teste), -Inf)
})

test_that("score analitico coincide com o gradiente numerico", {
  h <- 1e-6
  p <- 0.35
  l <- 2.7
  num <- c(
    (loglik_zip(p + h, l, s_teste) - loglik_zip(p - h, l, s_teste)) / (2 * h),
    (loglik_zip(p, l + h, s_teste) - loglik_zip(p, l - h, s_teste)) / (2 * h)
  )
  expect_equal(score_zip(p, l, s_teste), num, tolerance = 1e-6)
})

test_that("Hessiana analitica coincide com a derivada numerica do score", {
  h <- 1e-6
  p <- 0.35
  l <- 2.7
  num <- cbind(
    (score_zip(p + h, l, s_teste) - score_zip(p - h, l, s_teste)) / (2 * h),
    (score_zip(p, l + h, s_teste) - score_zip(p, l - h, s_teste)) / (2 * h)
  )
  expect_equal(hessiana_zip(p, l, s_teste), num, tolerance = 1e-5, ignore_attr = TRUE)
})

test_that("EMV de referencia anula o score e preserva a media", {
  emv <- emv_referencia(s_teste)
  expect_lt(max(abs(score_zip(emv[["p"]], emv[["lambda"]], s_teste))), 1e-8)
  expect_equal((1 - emv[["p"]]) * emv[["lambda"]], mean(y_teste))
  expect_true(hessiana_negativa_definida(emv[["p"]], emv[["lambda"]], s_teste))
})

test_that("IC de Wald contem o EMV e respeita o espaco parametrico", {
  emv <- emv_referencia(s_teste)
  ic <- ic_wald_zip(emv[["p"]], emv[["lambda"]], s_teste)
  expect_true(ic["p", "li"] > 0 && ic["p", "ls"] < 1)
  expect_true(ic["p", "li"] < emv[["p"]] && emv[["p"]] < ic["p", "ls"])
  expect_true(ic["lambda", "li"] < emv[["lambda"]] && emv[["lambda"]] < ic["lambda", "ls"])
})
