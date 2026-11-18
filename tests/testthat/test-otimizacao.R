# Testes de `R/otimizacao.R` e `R/newton_raphson.R`.

y_teste <- c(rep(0, 30), c(1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 1, 2, 3, 2, 4))
s_teste <- estatisticas_suficientes(y_teste)
emv <- emv_referencia(s_teste)

test_that("optim (Nelder-Mead) chega ao EMV de referencia", {
  ajuste <- ajustar_optim(s_teste, 0.5, 1)
  expect_equal(ajuste[["p"]], emv[["p"]], tolerance = 1e-5)
  expect_equal(ajuste[["lambda"]], emv[["lambda"]], tolerance = 1e-5)
  expect_equal(ajuste[["convergencia"]], 0)
})

test_that("optim_multiplos_inicios devolve uma linha por metodo e inicio", {
  inicios <- data.frame(p0 = c(0.2, 0.7), lambda0 = c(1, 3))
  res <- optim_multiplos_inicios(s_teste, inicios)
  expect_equal(nrow(res), 4)
  expect_setequal(unique(res$metodo), c("Nelder-Mead", "BFGS"))
})

test_that("Newton-Raphson a partir dos momentos converge ao EMV", {
  ini <- inicio_momentos(y_teste)
  traj <- newton_raphson_zip(s_teste, ini[["p0"]], ini[["lambda0"]], 10)
  final <- traj[nrow(traj), ]
  expect_equal(nrow(traj), 11)
  expect_equal(final$p, emv[["p"]], tolerance = 1e-10)
  expect_equal(final$lambda, emv[["lambda"]], tolerance = 1e-10)
})

test_that("Newton-Raphson interrompe ao sair do espaco parametrico", {
  traj <- newton_raphson_zip(s_teste, 0.1, 10, 10)
  expect_lt(nrow(traj), 11)
  expect_true(is.na(traj$loglik[nrow(traj)]))
})
