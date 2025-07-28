import pandas as pd
import numpy as np

# === CONFIGURATION ===
INPUT_FILE = "datasets/Extracted_SMS_Labeled.xlsx"
OUTPUT_FILE = "datasets/Extracted_SMS_Cleaned.xlsx"

# === LOAD DATA ===
df = pd.read_excel(INPUT_FILE)

# === BASIC CLEANING ===

# 1. Drop rows where SMS or Category is missing
df.dropna(subset=[df.columns[0], 'Category'], inplace=True)

# 2. Rename columns for consistency
df.columns = ['SMS', 'Category']

# 3. Strip extra spaces and lowercase SMS text
df['SMS'] = df['SMS'].astype(str).str.strip().str.lower()

# 4. Standardize Category values (strip + title case)
df['Category'] = df['Category'].astype(str).str.strip().str.title()

# 5. Drop duplicate SMS messages
df.drop_duplicates(subset='SMS', inplace=True)

# 6. Optional: remove very short or spammy messages (e.g., <10 chars)
df = df[df['SMS'].str.len() > 10]

# 7. Optional: remove generic “Unknown” categories
df = df[df['Category'] != 'Unknown']

# === SAVE CLEANED DATA ===
df.reset_index(drop=True, inplace=True)
df.to_excel(OUTPUT_FILE, index=False)

print(f"✅ Cleaned dataset saved to: {OUTPUT_FILE}")
print(f"📊 Rows after cleaning: {len(df)}")
print(f"📚 Categories: {df['Category'].unique()}")
