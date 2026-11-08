def build_hello_message(name: str | None) -> str:
    if name:
        return f"Hello {name}"

    return "Hello World"
