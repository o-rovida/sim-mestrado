rm(list = ls())
gc()
library(tidyverse)
library(DBI)
library(duckdb)

con <- dbConnect(duckdb::duckdb(), dbdir = "sim.duckdb", read_only = TRUE)

query <- "
SELECT 
    DTOBITO, DATAOBITO,
    IDADE, 
    PESO, PESONASC,
    SEXO,
    RACACOR,
    ESCMAE, INSTRMAE,
    SEMAGESTAC, SEMANGEST, GESTACAO,
    CAUSABAS,
    QTDFILVIVO, FILHVIVOS,
    QTDFILMORT, FILHMORT
FROM sim
"

df <- dbGetQuery(con, query)
dbDisconnect(con, shutdown = TRUE)

col_dtobito <- ifelse("DTOBITO" %in% names(df), "DTOBITO", "DATAOBITO")
col_peso <- ifelse("PESO" %in% names(df), "PESO", "PESONASC")
col_escmae <- ifelse("ESCMAE" %in% names(df), "ESCMAE", "INSTRMAE")
col_semagestac <- ifelse("SEMAGESTAC" %in% names(df), "SEMAGESTAC", 
                         ifelse("SEMANGEST" %in% names(df), "SEMANGEST", "GESTACAO"))
col_filhvivos <- ifelse("QTDFILVIVO" %in% names(df), "QTDFILVIVO", "FILHVIVOS")
col_filhmort <- ifelse("QTDFILMORT" %in% names(df), "QTDFILMORT", "FILHMORT")

df <- df %>%
  select(
    DTOBITO = all_of(col_dtobito),
    IDADE,
    PESO = all_of(col_peso),
    SEXO,
    RACACOR,
    ESCMAE = all_of(col_escmae),
    SEMAGESTAC = all_of(col_semagestac),
    CAUSABAS,
    FILHVIVOS = all_of(col_filhvivos),
    FILHMORT = all_of(col_filhmort)
  )

df$PESO <- suppressWarnings(as.numeric(gsub("[^0-9]", "", as.character(df$PESO))))
df$SEMAGESTAC <- suppressWarnings(as.numeric(as.character(df$SEMAGESTAC)))

# Converter DTOBITO (mantendo NA onde necessário)
if (is.character(df$DTOBITO)) {
  df$DTOBITO <- as.Date(df$DTOBITO, format = "%d%m%Y")
}

# Converter idade para dias
idade_char <- as.character(df$IDADE)
unidade <- as.numeric(substr(idade_char, 1, 1))
valor <- as.numeric(substr(idade_char, 2, 3))
dias <- rep(NA_real_, length(idade_char))
validos <- !is.na(unidade) & !is.na(valor) & unidade %in% 1:5
dias[validos & unidade == 1] <- valor[validos & unidade == 1] / (60 * 24)
dias[validos & unidade == 2] <- valor[validos & unidade == 2] / 24
dias[validos & unidade == 3] <- valor[validos & unidade == 3]
dias[validos & unidade == 4] <- valor[validos & unidade == 4] * 30.4375
dias[validos & unidade == 5] <- (100 + valor[validos & unidade == 5]) * 365.25
df$IDADE_DIAS <- dias

# Agrupar causas
causas_clean <- gsub("[^A-Z0-9]", "", toupper(as.character(df$CAUSABAS)))
letra <- substr(causas_clean, 1, 1)
codigo_num <- suppressWarnings(as.numeric(substr(causas_clean, 2, 4)))
df$CAUSA_BLOCO <- "Outros"
df$CAUSA_BLOCO[letra == "P" & codigo_num >= 0 & codigo_num <= 96] <- "Perinatal"
df$CAUSA_BLOCO[letra == "J"] <- "Respiratório"
df$CAUSA_BLOCO[letra %in% c("A", "B")] <- "Infecção/Parasita"
df$CAUSA_BLOCO[letra == "I"] <- "Cardiovascular"
df$CAUSA_BLOCO[letra == "Q"] <- "Malformações congênitas"
df$CAUSA_BLOCO[letra %in% c("C", "D") & codigo_num <= 48] <- "Neoplasia"
df$CAUSA_BLOCO[letra %in% c("V", "W", "X", "Y", "S", "T")] <- "Trauma/External"
df$CAUSA_BLOCO[letra == "R"] <- "Sintomas/causas mal definidas"
df$CAUSA_BLOCO[is.na(df$CAUSABAS)] <- NA

# Razão vivos/mortos
df$FILHVIVOS <- suppressWarnings(as.numeric(as.character(df$FILHVIVOS)))
df$FILHMORT <- suppressWarnings(as.numeric(as.character(df$FILHMORT)))
df$RAZAOVIVMORT <- log((df$FILHVIVOS + 1) / (df$FILHMORT + 1))
df$RAZAOVIVMORT[is.na(df$RAZAOVIVMORT)] <- 0

# Categóricas
df$SEXO <- factor(df$SEXO, levels = c("0", "1", "2"),
                  labels = c("Ignorado", "Masculino", "Feminino"))
df$RACACOR <- factor(df$RACACOR, levels = c("1", "2", "3", "4", "5"),
                     labels = c("Branca", "Preta", "Amarela", "Parda", "Indígena"))
df$ESCMAE <- factor(df$ESCMAE, levels = c("1", "2", "3", "4", "5", "9"),
                    labels = c("Nenhuma", "1-3 anos", "4-7 anos",
                               "8-11 anos", "12 anos ou mais", "Ignorado"))

# Filtro: manter apenas observações sem NA nas variáveis de análise
df_filtrado <- df %>%
  filter(
    !is.na(IDADE_DIAS),
    !is.na(PESO),
    !is.na(SEMAGESTAC),
    !is.na(CAUSA_BLOCO),
    !is.na(SEXO),
    !is.na(RACACOR),
    !is.na(ESCMAE)
  )

mortalidade_infantil_limpo <- df_filtrado %>%
  select(DTOBITO, IDADE, PESO, SEXO, RACACOR, ESCMAE,
         SEMAGESTAC, CAUSA_BLOCO, RAZAOVIVMORT, IDADE_DIAS)

save(mortalidade_infantil_limpo, file = "mortalidade_infantil.RData")

cat("Dataset final salvo com", nrow(mortalidade_infantil_limpo), "observações.\n")
