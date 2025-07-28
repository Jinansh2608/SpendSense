import pandas as pd

# === Load Your Cleaned Dataset ===
INPUT_FILE = "datasets/SMS_Categorized_Cleaned_Final.xlsx"
df = pd.read_excel(INPUT_FILE)

# === Normalize Categories ===
df["Category"] = df["Category"].astype(str).str.strip().str.title()

# === Define NLP-Enhanced Reclassification Function ===
def reclassify_other(sms):
    text = sms.lower()
    
    if "cheque" in text or "chq" in text:
        if "deposited" in text:
            return "Cheque Deposit"
        elif "cleared" in text:
            return "Cheque Clearance"
        else:
            return "Cheque"
    
    if "trx" in text and "card" in text:
        return "Card Transaction"
    
    if "payment of" in text or "bill" in text:
        return "Bill Payment"
    
    if "aed" in text and "debited" in text:
        return "International Debit"
    
    if "upi" in text:
        return "Upi Transaction"
    
    return "Other"

# === Apply Only to 'Other' Category ===
mask_other = df["Category"] == "Other"
df.loc[mask_other, "Category"] = df.loc[mask_other, "SMS"].apply(reclassify_other)

# === Save Updated File ===
OUTPUT_FILE = "SMS_Categorized_Cleaned_Final_Reclassified.xlsx"
df.to_excel(OUTPUT_FILE, index=False)

print("✅ Reclassification complete!")
print(f"📁 Saved to: {OUTPUT_FILE}")

# === Optional: Show Top Classes ===
print("\n📊 Updated Category Distribution:")
print(df["Category"].value_counts().head(15))
