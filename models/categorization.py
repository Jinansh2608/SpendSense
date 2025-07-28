import pandas as pd
import numpy as np
import os
import joblib
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.decomposition import PCA

from sentence_transformers import SentenceTransformer
from imblearn.over_sampling import SMOTE
from tqdm import tqdm

# === CONFIGURATION ===
INPUT_FILE = "datasets/SMS_Categorized_Cleaned_Final_Reclassified.xlsx"
MODEL_PATH = "models/category_classifier.pkl"
ENCODER_PATH = "models/label_encoder.pkl"

# === LOAD DATA ===
df = pd.read_excel(INPUT_FILE)
df = df[["SMS", "Category"]].dropna()

# === CLEAN CATEGORY LABELS ===
df["Category"] = df["Category"].astype(str).str.strip().str.title()

# === REMOVE RARE CLASSES (<6 samples) ===
class_counts = df["Category"].value_counts()
valid_classes = class_counts[class_counts >= 6].index
df = df[df["Category"].isin(valid_classes)]

# === LABEL ENCODING ===
X_raw = df["SMS"].astype(str).tolist()
y_raw = df["Category"].astype(str).tolist()

le = LabelEncoder()
y_encoded = le.fit_transform(y_raw)

# === EMBEDDINGS ===
print("🔄 Generating SMS embeddings for full dataset...")
embedder = SentenceTransformer("all-MiniLM-L6-v2")
X_embedded = embedder.encode(X_raw, show_progress_bar=True)

# === APPLY SMOTE (FIXED: k_neighbors=1) ===
print("🧪 Applying SMOTE to balance class distribution...")
smote = SMOTE(random_state=42, k_neighbors=1)
X_balanced, y_balanced = smote.fit_resample(X_embedded, y_encoded)

# === SPLIT TRAIN/TEST ON BALANCED DATA ===
X_train, X_test, y_train, y_test = train_test_split(
    X_balanced, y_balanced, test_size=0.2, random_state=42, stratify=y_balanced
)

# === TRAINING MODEL ===
print("🎯 Training classifier...")
clf = LogisticRegression(max_iter=1000)
clf.fit(X_train, y_train)

# === SAVE MODEL AND ENCODER ===
os.makedirs("models", exist_ok=True)
joblib.dump(clf, MODEL_PATH)
joblib.dump(le, ENCODER_PATH)

# === EVALUATION ===
y_pred = clf.predict(X_test)

print("📊 Classification Report:")
print(classification_report(
    y_test,
    y_pred,
    labels=np.arange(len(le.classes_)),
    target_names=le.classes_
))

# === VISUALIZATIONS ===

## 1. Class Distribution After SMOTE
plt.figure(figsize=(12, 6))
pd.Series(le.inverse_transform(y_balanced)).value_counts().plot(kind='bar', color='teal')
plt.title("Category Distribution After SMOTE")
plt.xlabel("Category")
plt.ylabel("Frequency")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

## 2. Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(12, 10))
sns.heatmap(cm, annot=True, fmt="d", xticklabels=le.classes_, yticklabels=le.classes_, cmap="Blues")
plt.title("Confusion Matrix")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
decision_scores = clf.decision_function(X_test)
plt.figure(figsize=(12, 6))
for i, class_label in enumerate(le.classes_):
    plt.hist(decision_scores[:, i], bins=30, alpha=0.4, label=class_label)
plt.title("Decision Function Scores per Class")
plt.xlabel("Score")
plt.ylabel("Frequency")
plt.legend(loc="upper right")
plt.tight_layout()
plt.show()
pca = PCA(n_components=2)
X_2d = pca.fit_transform(X_train)
plt.figure(figsize=(10, 6))
scatter = plt.scatter(X_2d[:, 0], X_2d[:, 1], c=y_train, cmap="tab10", alpha=0.7)
plt.title("PCA of SMS Embeddings")
plt.xlabel("PC1")
plt.ylabel("PC2")
plt.legend(*scatter.legend_elements(), title="Classes")
plt.tight_layout()
plt.show()
