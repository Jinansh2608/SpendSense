from flask import Flask
from flask_cors import CORS

# Import blueprints
from categorizer_API import prediction_bp, records_bp, health_bp
from bills import bills_bp
from categories import categories_bp
from budgets import budgets_bp

app = Flask(__name__)
CORS(app)

# Register blueprints
app.register_blueprint(prediction_bp, url_prefix='/api')
app.register_blueprint(records_bp, url_prefix='/api')
app.register_blueprint(health_bp, url_prefix='/api')
app.register_blueprint(bills_bp, url_prefix='/api')
app.register_blueprint(categories_bp, url_prefix='/api')
app.register_blueprint(budgets_bp, url_prefix='/api')

if __name__ == "__main__":
    # Run on all network interfaces (LAN access)
    app.run(host="0.0.0.0", port=5000, debug=True)
