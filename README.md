# Happiness Paradox - When Well-being Doesn't Mean Mental Health

Project Overview:
This project explores a central paradox in global well-being data: do countries with higher happiness and prosperity really experience lower suicide rates? 
Using publicly available data from the World Happiness Report and WHO suicide statistics, we analyzed whether traditional indicators like GDP, happiness scores, social support, life expectancy, and freedom predict mental health outcomes.

Data Sources:
1) World Happiness Report
2) WHO Suicide Rate Dataset (via Kaggle)
Final dataset: 77 countries × 6 aligned variables

Methods Used:
1) Data cleaning and preprocessing (dplyr)
2) Exploratory analysis (correlation matrix, scatter plots)
3) Multiple Linear Regression (with full assumption checks)
4) Residual analysis (to detect outliers)
5) K-means clustering on standardized variables to identify hidden country groupings

Key Findings:
1) Happiness score and GDP do not significantly predict suicide rates (r = 0.13 and 0.08).
2) Only Social Support was statistically significant (p < 0.001), but its effect was positive, which was counterintuitive.
3) Countries like Lithuania, Slovenia, and Belarus showed high suicide rates despite high happiness — revealing deep mismatches.
4) Clustering revealed 3 distinct country types: Low-suicide, mid-happiness (possible underreporting); High-suicide, mid-to-high happiness (statistical outliers); Stable, high-happiness, mid-suicide countries.

Conclusion:
This project questions the assumption that prosperity and self-reported happiness are reliable proxies for mental health. Through regression, clustering, and critical assumption testing, we uncovered countries that break the well-being narrative — proving that what's measured as “happiness” may hide deeper psychological realities.
