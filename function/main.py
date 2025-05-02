import flask
import functions_framework
import os

@functions_framework.http
def hello_world_http(request: flask.Request) -> flask.Response:
    """
    Google Cloud Function that responds to HTTP GET requests with a structured JSON message.

    Returns:
        flask.Response: JSON response with developer, environment, and message.
    """
    if request.method == 'GET':
        environment = os.getenv("ENVIRONMENT", "unknown")
        response_data = {
            "developer": "Brayam Ruiz",
            "env": environment,
            "message": "Hello World!"
        }
        return flask.jsonify(response_data)
    else:
        return flask.abort(405, description="Method Not Allowed")

