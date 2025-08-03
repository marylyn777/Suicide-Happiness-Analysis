# LIBRARIES ----
library(dplyr)
library(ggplot2)
library(readr)
library(lmtest)
library(sandwich)
library(ggrepel)
library(reshape2)
library(cluster)

# LOAD DATASETS ----
happiness <- read.csv("/Users/mariakalianova/Downloads/archive (3)/world-happiness-report-2021.csv")
suicide_raw <- read.csv("/Users/mariakalianova/Downloads/who_suicide_statistics 2.csv")
country_map <- read.csv("/Users/mariakalianova/Downloads/country_name_mapping.csv")

# CLEANING ----

# Clean happiness data
happiness_clean <- happiness %>%
  select(
    Country = Country.name,
    HappinessScore = Ladder.score,
    GDPperCapita = Logged.GDP.per.capita,
    SocialSupport = Social.support,
    LifeExpectancy = Healthy.life.expectancy,
    Freedom = Freedom.to.make.life.choices
  ) %>%
  left_join(country_map, by = c("Country" = "happiness_name")) %>%
  mutate(Country_fixed = ifelse(is.na(suicide_name), Country, suicide_name))

# Clean suicide data
suicide_clean <- suicide_raw %>%
  filter(!is.na(suicides_no), !is.na(population)) %>%
  group_by(country, year) %>%
  summarise(
    total_suicides = sum(suicides_no),
    total_population = sum(population),
    .groups = "drop"
  ) %>%
  mutate(SuicideRate = (total_suicides / total_population) * 100000) %>%
  group_by(country) %>%
  arrange(desc(year)) %>%
  slice_head(n = 5) %>%
  summarise(SuicideRate = mean(SuicideRate, na.rm = TRUE), .groups = "drop") %>%
  rename(Country = country)

# Combine datasets
merged_data <- inner_join(
  happiness_clean %>%
    select(-Country, -suicide_name) %>%
    rename(Country = Country_fixed),
  suicide_clean,
  by = "Country"
)

# Export cleaned dataset
write.csv(merged_data, "/Users/mariakalianova/Downloads/table_works.csv", row.names = FALSE)

# CORRELATION HEATMAP ----
cor_data <- merged_data %>% 
  select(HappinessScore, GDPperCapita, SocialSupport, LifeExpectancy, Freedom, SuicideRate)

cor_matrix <- cor(cor_data, use = "complete.obs")
cor_df <- melt(cor_matrix)

ggplot(cor_df, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(value, 2)), size = 4) +
  scale_fill_gradient2(low = "#B2182B", high = "#2166AC", mid = "white", midpoint = 0) +
  theme_minimal(base_size = 14) +
  labs(title = "Correlation Matrix: Suicide vs Well-being Indicators", x = "", y = "", fill = "Correlation")

# MULTIPLE LINEAR REGRESSION ----
model <- lm(SuicideRate ~ HappinessScore + GDPperCapita + SocialSupport + LifeExpectancy + Freedom,
            data = merged_data)

summary(model)

# Diagnostics
plot(model$fitted.values, resid(model),
     main = "Linearity and Homoscedasticity",
     xlab = "Fitted Values", ylab = "Residuals")
abline(h = 0, col = "purple")

qqnorm(resid(model))
qqline(resid(model), col = "purple")

# Robust standard errors
coeftest(model, vcov = vcovHC(model, type = "HC1"))

# SCATTER PLOT WITH REGRESSION LINE ----
ggplot(merged_data, aes(x = HappinessScore, y = SuicideRate)) +
  geom_point(aes(color = GDPperCapita), size = 3, alpha = 0.8) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linewidth = 1) +
  geom_text_repel(data = merged_data %>% 
                    filter(SuicideRate > quantile(SuicideRate, 0.95) | 
                             SuicideRate < quantile(SuicideRate, 0.05)),
                  aes(label = Country),
                  size = 3.5, color = "gray20", max.overlaps = 10) +
  scale_color_gradientn(colors = c("#e0f3f8", "#abd9e9", "#74add1", "#4575b4"), name = "GDP per Capita") +
  theme_minimal(base_size = 14) +
  labs(title = "Happiness vs Suicide Rate", x = "Happiness Score", y = "Suicide Rate")

# OUTLIER ANALYSIS ----
merged_data$residual <- resid(model)
merged_data$resid_direction <- ifelse(merged_data$residual > 0, "Higher than expected", "Lower than expected")

extreme <- merged_data %>%
  filter(abs(residual) > quantile(abs(residual), 0.95))

ggplot(merged_data, aes(x = HappinessScore, y = residual, color = resid_direction)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_point(size = 3, alpha = 0.8) +
  geom_text_repel(data = extreme, aes(label = Country), size = 3.5, color = "black") +
  scale_color_manual(values = c("Higher than expected" = "#000099", 
                                "Lower than expected" = "#9999ff")) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Countries with Unexpected Suicide Rates (Residuals)",
    x = "Happiness Score",
    y = "Residual (Actual - Predicted Suicide Rate)",
    color = "Direction"
  )

# CLUSTERING ----
cluster_vars <- merged_data %>%
  select(HappinessScore, SuicideRate, GDPperCapita, SocialSupport, LifeExpectancy, Freedom)

scaled <- scale(cluster_vars)

set.seed(123)
kmeans_result <- kmeans(scaled, centers = 3)
merged_data$cluster <- as.factor(kmeans_result$cluster)

ggplot(merged_data, aes(x = HappinessScore, y = SuicideRate, color = cluster)) +
  geom_point(size = 3) +
  scale_color_manual(values = c("1" = "#cc0099", "2" = "#2929a3", "3" = "#008000"), name = "Cluster") +
  theme_minimal(base_size = 14) +
  labs(title = "Country Clusters: Suicide vs Happiness", x = "Happiness", y = "Suicide Rate")


