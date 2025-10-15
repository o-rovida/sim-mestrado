rm(list = ls())
if(!is.null(dev.list())) dev.off()
cat("\014")
library(tidyverse)

cat("\n", rep("=", 80), "\n", sep = "")
cat("  PREDIÇÃO DE DIAS DE SOBREVIVÊNCIA INFANTIL\n")
cat(rep("=", 80), "\n\n", sep = "")

# ==============================================================================
# CARREGAMENTO
# ==============================================================================

load("mortalidade_infantil.RData")
df <- mortalidade_infantil_limpo

cat("Observações:", nrow(df), "| Variáveis:", ncol(df), "\n\n")

# ==============================================================================
# CONVERSÃO DE IDADE PARA DIAS CONTÍNUOS
# ==============================================================================

converter_idade_para_dias <- function(idade_str) {
  if(is.na(idade_str) || nchar(as.character(idade_str)) != 3) return(NA)
  idade_str <- as.character(idade_str)
  unidade <- as.numeric(substr(idade_str, 1, 1))
  valor <- as.numeric(substr(idade_str, 2, 3))
  if(is.na(unidade) || is.na(valor) || unidade == 9) return(NA)
  dias <- switch(as.character(unidade),
                 "1" = valor / (60 * 24),
                 "2" = valor / 24,
                 "3" = valor,
                 "4" = valor * 30.4375,
                 "5" = (100 + valor) * 365.25,
                 NA)
  return(dias)
}

df$IDADE_DIAS_CONTINUO <- sapply(df$IDADE, converter_idade_para_dias)

cat("Conversão: ", sum(!is.na(df$IDADE_DIAS_CONTINUO)), " valores (", 
    round(100*sum(!is.na(df$IDADE_DIAS_CONTINUO))/nrow(df),1), "%)\n")
cat("Range: [", round(min(df$IDADE_DIAS_CONTINUO, na.rm=T),2), ", ", 
    round(max(df$IDADE_DIAS_CONTINUO, na.rm=T),2), "] dias\n\n")

# ==============================================================================
# PREPARAÇÃO DOS DADOS
# ==============================================================================

df_clean <- df %>%
  select(IDADE_DIAS_CONTINUO, RAZAOVIVMORT, PESO, SEMAGESTAC, 
         CAUSA_BLOCO, SEXO, RACACOR) %>%
  na.omit() %>%
  mutate(across(c(IDADE_DIAS_CONTINUO, PESO, SEMAGESTAC, RAZAOVIVMORT), as.numeric)) %>%
  filter(IDADE_DIAS_CONTINUO <= 365)

cat("Observações finais:", nrow(df_clean), "(", 
    round(100*nrow(df_clean)/nrow(df),1), "%)\n")
cat("Valores únicos IDADE_DIAS:", length(unique(df_clean$IDADE_DIAS_CONTINUO)), "\n\n")

# ==============================================================================
# ESTATÍSTICAS DESCRITIVAS
# ==============================================================================

cat("IDADE_DIAS (variável alvo):\n")
cat(sprintf("  Média: %7.2f | Mediana: %7.2f | DP: %6.2f dias\n", 
            mean(df_clean$IDADE_DIAS_CONTINUO),
            median(df_clean$IDADE_DIAS_CONTINUO),
            sd(df_clean$IDADE_DIAS_CONTINUO)))

cat("\nDistribuição por período:\n")
print(table(cut(df_clean$IDADE_DIAS_CONTINUO, 
                breaks = c(0, 1, 7, 28, 365),
                labels = c("<1 dia", "1-7 dias", "7-28 dias", "28-365 dias"))))
cat("\n")

# ==============================================================================
# CORRELAÇÕES
# ==============================================================================

cor_peso <- cor.test(df_clean$PESO, df_clean$IDADE_DIAS_CONTINUO)
cor_sema <- cor.test(df_clean$SEMAGESTAC, df_clean$IDADE_DIAS_CONTINUO)
cor_razao <- cor.test(df_clean$RAZAOVIVMORT, df_clean$IDADE_DIAS_CONTINUO)

cat(sprintf("%-15s  r = %6.3f  (p %s)\n", "PESO:", cor_peso$estimate, 
            format.pval(cor_peso$p.value, digits=2)))
cat(sprintf("%-15s  r = %6.3f  (p %s)\n", "SEMAGESTAC:", cor_sema$estimate, 
            format.pval(cor_sema$p.value, digits=2)))
cat(sprintf("%-15s  r = %6.3f  (p %s)\n\n", "RAZAOVIVMORT:", cor_razao$estimate, 
            format.pval(cor_razao$p.value, digits=2)))

# ==============================================================================
# DIVISÃO TREINO/TESTE (80/20)
# ==============================================================================

set.seed(123)
indices_treino <- sample(1:nrow(df_clean), size = 0.8 * nrow(df_clean))
dados_treino <- df_clean[indices_treino, ]
dados_teste <- df_clean[-indices_treino, ]

cat("Treino: ", nrow(dados_treino), " | Teste: ", nrow(dados_teste), "\n\n")

# ==============================================================================
# MODELO DE REGRESSÃO
# ==============================================================================

cat("Fórmula: IDADE_DIAS ~ PESO + SEMAGESTAC + RAZAOVIVMORT +\n")
cat("                       CAUSA_BLOCO + SEXO + RACACOR\n\n")

modelo <- lm(IDADE_DIAS_CONTINUO ~ PESO + SEMAGESTAC + RAZAOVIVMORT + 
               CAUSA_BLOCO + SEXO + RACACOR,
             data = dados_treino)

# ==============================================================================
# COEFICIENTES E P-VALORES
# ==============================================================================

coef_summary <- summary(modelo)$coefficients
coef_df <- data.frame(
  Variavel = rownames(coef_summary),
  Coef = coef_summary[, "Estimate"],
  EP = coef_summary[, "Std. Error"],
  T = coef_summary[, "t value"],
  P = coef_summary[, "Pr(>|t|)"],
  Sig = ifelse(coef_summary[, "Pr(>|t|)"] < 0.001, "***", 
               ifelse(coef_summary[, "Pr(>|t|)"] < 0.01, "**",
                      ifelse(coef_summary[, "Pr(>|t|)"] < 0.05, "*", "")))
)

cat(sprintf("%-40s %10s %10s %8s %10s %4s\n", 
            "Variável", "Coef", "EP", "T", "P-valor", ""))
cat(rep("-", 85), "\n", sep = "")

for(i in 1:nrow(coef_df)) {
  cat(sprintf("%-40s %10.6f %10.6f %8.2f %10.2e %4s\n",
              substr(coef_df$Variavel[i], 1, 40),
              coef_df$Coef[i], coef_df$EP[i], coef_df$T[i], 
              coef_df$P[i], coef_df$Sig[i]))
}

cat("\nLegenda: *** p<0.001  ** p<0.01  * p<0.05\n\n")

# ==============================================================================
# DESEMPENHO NO TESTE
# ==============================================================================

pred_teste <- predict(modelo, newdata = dados_teste)

if(any(is.na(pred_teste))) {
  indices_validos <- !is.na(pred_teste)
  pred_teste <- pred_teste[indices_validos]
  dados_teste <- dados_teste[indices_validos, ]
}

residuos <- dados_teste$IDADE_DIAS_CONTINUO - pred_teste
rmse <- sqrt(mean(residuos^2))
ss_res <- sum(residuos^2)
ss_tot <- sum((dados_teste$IDADE_DIAS_CONTINUO - mean(dados_teste$IDADE_DIAS_CONTINUO))^2)
r2_teste <- 1 - (ss_res / ss_tot)
r2_treino <- summary(modelo)$r.squared
r2_adj <- summary(modelo)$adj.r.squared

cat("ERRO DE PREVISÃO:\n")
cat(sprintf("  RMSE: %6.2f dias\n\n", rmse))

cat("PODER EXPLICATIVO:\n")
cat(sprintf("  R² (treino): %.4f  (%.1f%%)\n", r2_treino, r2_treino*100))
cat(sprintf("  R² (teste):  %.4f  (%.1f%%)\n", r2_teste, r2_teste*100))
cat(sprintf("  R² ajustado: %.4f\n\n", r2_adj))

# ==============================================================================
# GRÁFICO: REAL VS PREVISTO
# ==============================================================================

par(mfrow = c(1, 1))

plot(dados_teste$IDADE_DIAS_CONTINUO, pred_teste,
     xlab = "Dias de Sobrevivência Real", 
     ylab = "Dias de Sobrevivência Previsto",
     main = "Valores Reais vs Previstos",
     pch = 16, col = rgb(0, 0, 1, 0.2),
     xlim = range(dados_teste$IDADE_DIAS_CONTINUO),
     ylim = range(pred_teste))

abline(lm(pred_teste ~ dados_teste$IDADE_DIAS_CONTINUO), col = "blue", lwd = 2)
grid()