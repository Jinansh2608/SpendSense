from flask import jsonify, request
from werkzeug.exceptions import HTTPException

def register_error_handlers(app):
    @app.errorhandler(HTTPException)
    def handle_exception(e):
        """Return JSON instead of HTML for HTTP errors."""
        response = e.get_response()
        response.data = jsonify({
            "status": "error",
            "code": e.code,
            "name": e.name,
            "description": e.description,
        })
        response.content_type = "application/json"
        return response

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({
            "status": "error",
            "message": f"The requested URL {request.url} was not found on the server."
        }), 404

    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({
            "status": "error",
            "message": "The browser (or proxy) sent a request that this server could not understand."
        }), 400

    @app.errorhandler(405)
    def method_not_allowed(error):
        return jsonify({
            "status": "error",
            "message": f"The method {request.method} is not allowed for the requested URL."
        }), 405

    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({
            "status": "error",
            "message": "The server encountered an internal error and was unable to complete your request."
        }), 500
