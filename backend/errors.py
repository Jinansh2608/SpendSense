from flask import jsonify

def register_error_handlers(app):
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"status": "error", "message": "Bad request"}), 400

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"status": "error", "message": "Not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(error):
        return jsonify({"status": "error", "message": "Method not allowed"}), 405

    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({"status": "error", "message": "Internal server error"}), 500
