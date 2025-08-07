from flask import Flask, request, jsonify
from flask_cors import CORS
from sentence_transformers import SentenceTransformer
import joblib

app = Flask(__name__)
CORS(app)  # Enable CORS

# Load model and encoder
classifier = joblib.load("models/category_classifier.pkl")
label_encoder = joblib.load("models/label_encoder.pkl")
sentence_model = SentenceTransformer("all-MiniLM-L6-v2")

@app.route("/predict-bulk", methods=["POST"])
def predict_bulk():
    data = request.get_json()

    if not data or "messages" not in data:
        return jsonify({"error": "Missing 'messages' field"}), 400

    messages = data["messages"]
    if not isinstance(messages, list):
        return jsonify({"error": "'messages' must be a list"}), 400

    try:
        embeddings = sentence_model.encode(messages)
        predictions = classifier.predict(embeddings)
        categories = label_encoder.inverse_transform(predictions)

        result = [
            {"sms": sms, "category": category}
            for sms, category in zip(messages, categories)
        ]

        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/", methods=["GET"])
def home():
    return "✅ Server is running!"

if __name__ == "__main__":
    # Run on all interfaces so physical device can access it
    app.run(host="0.0.0.0", port=5000, debug=True)
