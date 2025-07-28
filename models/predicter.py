# sms_predictor.py

import joblib
import os
import numpy as np
from sentence_transformers import SentenceTransformer

MODEL_PATH = "models/category_classifier.pkl"
ENCODER_PATH = "models/label_encoder.pkl"

# === Load Model and Encoder ===
if not os.path.exists(MODEL_PATH) or not os.path.exists(ENCODER_PATH):
    raise FileNotFoundError("Model or label encoder not found. Run training script first.")

print("📦 Loading model and encoder...")
clf = joblib.load(MODEL_PATH)
le = joblib.load(ENCODER_PATH)

embedder = SentenceTransformer("all-MiniLM-L6-v2")

# === Prediction Loop ===
print("\n🔮 SMS Category Predictor")
print("Type 'exit' to quit.\n")

while True:
    user_input = input("📨 Enter SMS text: ").strip()
    if user_input.lower() in ["exit", "quit"]:
        print("👋 Exiting.")
        break
    if not user_input:
        continue

    # Encode and predict
    embedding = embedder.encode([user_input])
    probs = clf.predict_proba(embedding)[0]
    top_indices = np.argsort(probs)[::-1][:3]

    print("\n🔍 Prediction Results:")
    for idx in top_indices:
        
        category = le.classes_[idx]
        confidence = probs[idx] * 100
        print(f"• {category}: {confidence:.2f}%")

    print("\n" + "-" * 40 + "\n")
