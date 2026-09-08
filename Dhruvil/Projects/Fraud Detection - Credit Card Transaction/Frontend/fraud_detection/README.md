# 🛡️ SentinelFD — Credit Card Fraud Detection

An intelligent fraud detection platform that analyses credit card transactions in real time using a three-model ML ensemble. Built with **Flutter**, **Flask**, and **PostgreSQL**.

---

## What it does

SentinelFD allows financial analysts to submit credit card transactions — one at a time or in bulk — and instantly receive a fraud verdict backed by three independent ML models. Every prediction is logged, reviewable, and tied to the analyst who ran it.

---

## Features

- 🔐 **Authentication** — Register and login with role-based access (Admin / Analyst / Viewer)
- 🔍 **Single Transaction Scan** — Enter transaction details manually and get an instant fraud verdict with confidence score
- 📁 **Batch CSV Upload** — Upload thousands of transactions at once with a live progress indicator and downloadable results
- 🤖 **3-Model Ensemble** — Isolation Forest, Local Outlier Factor, and XGBoost each cast a vote; the majority decides the final verdict
- 📊 **Analytics Dashboard** — View AUC score, confusion matrix, ROC curve, and live fraud statistics across all users
- 👤 **User Profile** — Personal scan history, batch upload history, activity summary, and session management
- 🗄️ **Full Audit Trail** — Every prediction, login, and review action is permanently logged in PostgreSQL

---

## How it works

1. A transaction is submitted via the Flutter app — either through a manual form or a CSV file upload
2. The Flask backend receives the data and passes it through a preprocessing pipeline (StandardScaler normalization)
3. Three models analyse the transaction independently:
   - **Isolation Forest** flags statistical anomalies based on how easily the transaction is isolated from others
   - **Local Outlier Factor** detects outliers by comparing the transaction's density to its nearest neighbours
   - **XGBoost** predicts a fraud probability score using patterns learned from 284,807 labelled transactions
4. The ensemble takes a **majority vote** — if 2 or more models flag the transaction, it is marked `FRAUD`
5. The result is saved to PostgreSQL and returned to Flutter, where the verdict, per-model breakdown, and fraud score are displayed

---

## Dataset

Built on the [Kaggle Credit Card Fraud Detection dataset](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) — 284,807 real European cardholder transactions with a 0.17% fraud rate. SMOTE oversampling is applied during training to handle the severe class imbalance.

---

## Author

**Dhruvil Bhatt** — B.Sc. IT, CHARUSAT University (2026)  
bhattdhruvil2005@gmail.com
