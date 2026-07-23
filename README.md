NASA Nearest Earth Objects (NEO) - Data Science Pipeline
This repository contains a complete end-to-end data preprocessing and exploratory data analysis (EDA) pipeline built in Python using Jupyter Notebooks. The project focuses on cleaning, scaling, and preparing astronomical asteroid data to predict whether a Nearest Earth Object is potentially hazardous.

🛠️ Practical Workflow
Data Ingestion: Loaded neo.csv using Pandas with raw string formatting for Windows file paths.
Feature Reduction: Dropped arbitrary identifiers (id, name) and zero-variance columns (orbiting_body, sentry_object) to eliminate noise and prevent overfitting.
Target Encoding: Converted the boolean target variable hazardous (True/False) into binary integers (1/0).
Outlier Treatment: Identified distribution skewness using Seaborn boxplots and filtered out extreme data points across continuous features using the Interquartile Range (IQR) rule ($Q1 - 1.5 \times \text{IQR}$ to $Q3 + 1.5 \times \text{IQR}$).
Feature Scaling: Applied Scikit-Learn's StandardScaler ($z = \frac{x - \mu}{\sigma}$) to standardize continuous features to a mean of $0$ and standard deviation of $1$, leaving the binary target variable unscaled.
