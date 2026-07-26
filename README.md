Apple App Store 2026 - Data Analysis & EDA PipelineThis repository contains an end-to-end exploratory data analysis (EDA) and pattern recognition pipeline built in Python using Jupyter Notebooks. The project focuses on cleaning, visualizing, and analyzing metadata from 11,500 iOS applications to uncover structural monetization trends, storage anomalies, and user sentiment drivers.

🛠️ Practical Workflow
Data Ingestion & Engineering: Loaded apple_appstore_2026.csv using Pandas, converted raw application sizes from bytes to Megabytes (Size_MB), and parsed datetime strings to track software update lifecycles.
Distribution Visualization: Generated side-by-side Seaborn histograms and boxplots across continuous numeric features to evaluate density, identify heavy skewness, and isolate statistical anomalies.
Relationship & Correlation Analysis: Computed correlation matrices and built log-transformed (log1p) multi-feature pairplots to evaluate feature independence and uncover a positive correlation between app size and user ratings.
Pattern & Anomaly Detection: Grouped data by genre and content rating to expose structural industry trends—such as the ~73% freemium monetization rule and gaming storage dominance—while isolating extreme pricing anomalies ($999.99).
Automated Statistical Inference: Developed an interactive reporting script that dynamically calculates Interquartile Range (IQR) outlier cutoffs ($Q1 - 1.5 \times \text{IQR}$ to $Q3 + 1.5 \times \text{IQR}$), median benchmarks, and skewness coefficients.
