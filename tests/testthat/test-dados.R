# Testes de `R/dados.R`.

test_that("estatisticas suficientes contam zeros, positivos e soma", {
  s <- estatisticas_suficientes(c(0, 0, 3, 1, 0, 2))
  expect_equal(s$n, 6)
  expect_equal(s$n0, 3)
  expect_equal(s$np, 3)
  expect_equal(s$S, 6)
  expect_equal(s$C, log(6) + log(1) + log(2))
})

test_that("carregar_visitas valida colunas e tipa o perfil", {
  arquivo <- tempfile(fileext = ".csv")
  write.csv(data.frame(id = 1:3, perfil = c("alto", "baixo", "medio"), visitas = c(2, 0, 1)),
    arquivo,
    row.names = FALSE
  )
  dados <- carregar_visitas(arquivo)
  expect_s3_class(dados$perfil, "factor")
  expect_equal(levels(dados$perfil), PERFIS)

  write.csv(data.frame(id = 1, perfil = "alto"), arquivo, row.names = FALSE)
  expect_error(carregar_visitas(arquivo), "Colunas ausentes")
})

test_that("rejeita contagens negativas ou nao inteiras", {
  arquivo <- tempfile(fileext = ".csv")
  write.csv(data.frame(id = 1:2, perfil = "alto", visitas = c(1, -1)), arquivo, row.names = FALSE)
  expect_error(carregar_visitas(arquivo), "inteiros nao negativos")
})

test_that("o dataset do enunciado tem 400 clientes por perfil", {
  dados <- carregar_visitas(file.path("..", "..", "data", "raw", "visitas_medicas.csv"))
  expect_equal(as.numeric(table(dados$perfil)), c(400, 400, 400))
})
