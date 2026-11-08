import azure.functions as func


def build_text_response(body: str, status_code: int = 200) -> func.HttpResponse:
    return func.HttpResponse(
        body=body,
        status_code=status_code,
        mimetype="text/plain",
    )
