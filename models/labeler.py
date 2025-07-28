import pandas as pd
from transformers import pipeline
from tqdm import tqdm

# === CONFIGURATION ===
INPUT_FILE = "datasets/Extracted_SMS.xlsx"           # Input Excel file
OUTPUT_FILE = "datasets/labeled_SMS_free.xlsx"       # Output Excel file

# === SPENDING CATEGORY LABELS (NO MODE, JUST PURPOSE) ===
labels = [
    "Food & Dining",
    "Travel & Transport",
    "Entertainment",
    "Shopping",
    "Utilities & Bills",
    "Health & Medical",
    "Education",
    "Fuel",
    "Insurance",
    "Rent",
    "Loan EMI",
    "Investment",
    "Government or Tax",
    "Salary Income",
    "Refund or Cashback",
    "Cash Withdrawal",
    "Account Service",
    "Other"
]

# === LOAD FIRST 10 SMS FROM FILE ===
df = pd.read_excel(INPUT_FILE)
sms_col = df.columns[0]
df = df.dropna(subset=[sms_col]).reset_index(drop=True)  # Remove blank rows
df = df.iloc[:10]  # ⬅️ Only use first 10 for testing
sms_list = df[sms_col].astype(str).tolist()

# === LOAD HUGGING FACE ZERO-SHOT CLASSIFIER ===
print("🔍 Loading Hugging Face zero-shot classification model...")
classifier = pipeline("zero-shot-classification", model="facebook/bart-large-mnli")

# === LABEL EACH SMS ===
predicted_labels = []
print("🏷️  Predicting categories for each SMS...")
for sms in tqdm(sms_list):
    try:
        result = classifier(sms, labels, multi_label=False)
        category = result['labels'][0]
    except Exception as e:
        print("❌ Error:", e)
        category = "Unknown"
    predicted_labels.append(category)

# === ASSIGN & SAVE LABELED OUTPUT ===
df["category"] = predicted_labels
df.to_excel(OUTPUT_FILE, index=False)
print(f"✅ Labeled SMS data saved to: {OUTPUT_FILE}")
