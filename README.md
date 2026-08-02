Iris Species Classification - K-Nearest Neighbors (KNN) Pipeline
This repository contains a complete machine learning pipeline built in Python using Scikit-Learn and Jupyter Notebooks. The project focuses on classifying Iris flower species based on their physical sepal and petal measurements by implementing, tuning, and visualizing a K-Nearest Neighbors algorithm.

🛠️ Practical Workflow
Data Ingestion & Normalization: Loaded Iris.csv using Pandas, encoded the categorical target labels into integers using LabelEncoder, and scaled the continuous features using Scikit-Learn's StandardScaler (z= 
(x−μ) / σ) to ensure distance-based metrics are calculated uniformly without scale bias.

Hyperparameter Tuning: Iteratively trained multiple KNN models by varying the number of neighbors (K) from 1 to 20, calculating the test accuracy for each to identify the optimal K value for the dataset.

Model Evaluation: Assessed the optimized KNN model's performance on the unseen test set and generated a Confusion Matrix heatmap to visualize true vs. predicted classifications across all three flower species.

Dimensionality Reduction: Applied Principal Component Analysis (PCA) to compress the original four-dimensional feature space down to two principal components, preserving the dataset's variance for 2D mapping.

Decision Boundary Visualization: Created a uniform mesh grid over the PCA-reduced 2D space and plotted the predicted classification territories and contour boundaries to visually interpret how the algorithm separates the classes.
