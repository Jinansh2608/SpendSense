from flask import Flask, request, jsonify
import requests
import time
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Hugging Face API setup
HF_API_URL = os.getenv("HF_API_URL", "https://api-inference.huggingface.co/models/facebook/bart-large-mnli")
HF_API_KEY = os.getenv("HF_API_KEY")
HEADERS = {"Authorization": f"Bearer {HF_API_KEY}"}

CATEGORIES = ["UPI", "ATM", "Bank Transfer", "Credit Card", "Loan"]

def classify_sms(text):
    payload = {
        "inputs": text,
        "parameters": {
            "candidate_labels": CATEGORIES
        }
    }

    for attempt in range(5):  # Retry up to 5 times
        response = requests.post(HF_API_URL, headers=HEADERS, json=payload)

        # Handle non-JSON response
        try:
            result = response.json()
        except:
            return {"category": "Unknown", "confidence": 0}

        # Debugging: print raw response
        print(f"Attempt {attempt+1} - Raw Response:", result)

        # If labels are returned
        if 'labels' in result:
            top_category = result['labels'][0]
            confidence = result['scores'][0]
            return {"category": top_category, "confidence": confidence}

        # If model is loading or rate-limited
        if "loading" in result.get("error", "").lower() or "currently loading" in result.get("error", "").lower():
            time.sleep(3)
            continue

        # If unauthorized
        if "unauthorized" in result.get("error", "").lower():
            return {"category": "API Key Error", "confidence": 0}

        # If another error, break
        break

    return {"category": "Unknown", "confidence": 0}


@app.route('/classify', methods=['POST'])
def classify():
    data = request.json
    sms_list = data.get("messages", [])
    results = []

    for sms in sms_list:
        classification = classify_sms(sms)
        results.append({"message": sms, **classification})

    return jsonify(results)


if __name__ == '__main__':
    app.run(debug=True)
