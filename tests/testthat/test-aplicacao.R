# Testes de `R/aplicacao.R`.

test_that("esperanca e variancia do ZIP seguem as formulas fechadas", {
  expect_equal(esperanca_zip(0.25, 4), 3)
  expect_equal(variancia_zip(0.25, 4), 3 * (1 + 1))
  expect_equal(esperanca_zip(0, 2), 2)
  expect_equal(variancia_zip(0, 2), 2)
})

test_that("premio = custo * E[Y] + lucro", {
  expect_equal(premio_anual(0.5, 2), CUSTO_CONSULTA * 1 + LUCRO_DESEJADO)
  expect_equal(premio_anual(c(0, 1 - 1e-12), c(1, 1)), c(350, 100), tolerance = 1e-8)
})

test_that("premio no EMV depende so da media amostral", {
  y <- c(rep(0, 30), c(1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 1, 2, 3, 2, 4))
  emv <- emv_referencia(estatisticas_suficientes(y))
  expect_equal(premio_anual(emv[["p"]], emv[["lambda"]]), CUSTO_CONSULTA * mean(y) + LUCRO_DESEJADO)
})
