Heart Disease Classification - Decision Tree & Random Forest Pipeline
This repository contains a complete machine learning pipeline built in Python using Scikit-Learn and Jupyter Notebooks. The project focuses on predicting the presence of heart disease using patient clinical data, comparing the performance, interpretability, and generalization of single Decision Trees against ensemble Random Forest models.

🛠️ Practical Workflow
Decision Tree Training & Visualization: Loaded heart.csv using Pandas, split the data into training and testing sets, and trained a baseline Decision Tree Classifier. Generated a visual map of the tree (plot_tree) to interpret the model's internal decision logic and node splits.

Overfitting Analysis & Pruning: Demonstrated the mechanics of overfitting by comparing an unconstrained tree (which memorized the training data with 100% accuracy but generalized poorly) against a depth-constrained tree (max_depth=4), proving how pruning stabilizes test accuracy.

Ensemble Learning (Random Forest): Initialized and trained a Random Forest Classifier consisting of 100 aggregated trees (n_estimators=100) to reduce model variance and improve predictive robustness over a single decision tree.

Feature Importance Extraction: Extracted the feature_importances_ attribute from the Random Forest model and generated a bar chart to rank the most critical clinical indicators (such as chest pain type or maximum heart rate) driving the model's predictions.

Cross-Validation Evaluation: Evaluated the Random Forest model's true real-world reliability using 5-Fold Cross-Validation (cross_val_score), calculating the mean accuracy and standard deviation across multiple unique train-test splits.
