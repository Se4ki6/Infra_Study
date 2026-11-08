import azure.functions as func

from src.handlers.hello import build_hello_message
from src.services.response_builder import build_text_response


def orchestrate_hello(req: func.HttpRequest) -> func.HttpResponse:
    requested_name = req.params.get("name")
    message = build_hello_message(requested_name)
    return build_text_response(message)
