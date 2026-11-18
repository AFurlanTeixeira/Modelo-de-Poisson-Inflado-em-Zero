# Testes de `R/gibbs.R` (propriedades estatisticas, nao valores exatos).

y_teste <- c(rep(0, 60), rep(c(1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 1, 2, 3, 2, 4), 4))
s_teste <- estatisticas_suficientes(y_teste)

test_that("cadeia tem a dimensao esperada e respeita o dominio", {
  ch <- gibbs_zip(s_teste, n_iter = 500, seed = 1)
  expect_equal(dim(ch), c(500, 3))
  expect_true(all(ch[, "p"] > 0 & ch[, "p"] < 1))
  expect_true(all(ch[, "lambda"] > 0))
  expect_true(all(ch[, "soma_z"] <= s_teste$n0))
})

test_that("mesma semente reproduz a mesma cadeia", {
  expect_identical(gibbs_zip(s_teste, 200, seed = 7), gibbs_zip(s_teste, 200, seed = 7))
})

test_that("mediana a posteriori fica proxima do EMV com n grande", {
  cadeias <- gibbs_varias_cadeias(s_teste, inicios_cadeias(), n_iter = 4000, seed = 10)
  amostras <- amostras_posteriori(cadeias, burn_in = 500)
  res <- resumo_posteriori(amostras)
  emv <- emv_referencia(s_teste)
  expect_equal(res$mediana[res$param == "p"], emv[["p"]], tolerance = 0.05)
  expect_equal(res$mediana[res$param == "lambda"], emv[["lambda"]], tolerance = 0.05)
  expect_equal(nrow(amostras), 3 * 3500)
})

test_that("diagnosticos indicam convergencia", {
  cadeias <- gibbs_varias_cadeias(s_teste, inicios_cadeias(), n_iter = 3000, seed = 3)
  d <- diagnosticos_mcmc(cadeias, burn_in = 500)
  expect_true(all(d$rhat < 1.05))
  expect_true(all(d$ess > 1000))
})
