# Testes de `R/em.R`.

y_teste <- c(rep(0, 30), c(1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 1, 2, 3, 2, 4))
s_teste <- estatisticas_suficientes(y_teste)

test_that("pesos do passo E: zero para y > 0 e Bayes para y = 0", {
  w <- pesos_em(c(0, 2, 0, 5), 0.4, 2)
  expect_equal(w[c(2, 4)], c(0, 0))
  expect_equal(w[1], 0.4 / (0.4 + 0.6 * exp(-2)))
})

test_that("EM converge ao EMV com log-verossimilhanca monotona", {
  ajuste <- em_zip(s_teste)
  emv <- emv_referencia(s_teste)
  expect_equal(ajuste$p, emv[["p"]], tolerance = 1e-6)
  expect_equal(ajuste$lambda, emv[["lambda"]], tolerance = 1e-6)
  expect_true(all(diff(ajuste$loglik) >= -1e-10))
})

test_that("toda iteracao do EM preserva a media amostral", {
  ajuste <- em_zip(s_teste, p0 = 0.9, lambda0 = 0.5, max_iter = 1)
  expect_equal((1 - ajuste$p) * ajuste$lambda, mean(y_teste))
})
