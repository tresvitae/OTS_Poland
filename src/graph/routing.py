"""
Logika routingu dla grafu LangGraph.

Funkcje decyzyjne:
- route_task() — kieruje do odpowiedniego zespołu
- should_review() — czy wynik wymaga QA review
"""


def route_task(state: dict) -> str:
    """
    Decyduje, do którego zespołu skierować zadanie.
    Wywoływane jako conditional edge po węźle Supervisora.

    Returns:
        Nazwa następnego węzła: "backend", "frontend", "integration", "content", "finish"
    """
    task_type = state.get("task_type", "backend")

    valid_teams = {"backend", "frontend", "integration", "content", "finish"}

    if task_type in valid_teams:
        return task_type

    # Fallback → backend
    return "backend"


def should_review(state: dict) -> str:
    """
    Decyduje, czy wygenerowany kod powinien przejść przez QA.
    Wywoływane jako conditional edge po węźle zespołu.

    Returns:
        "qa_review" — jeśli jest kod do sprawdzenia
        "finish" — jeśli nie ma kodu (np. pytanie informacyjne)
    """
    generated_code = state.get("generated_code", "")

    # Jeśli jest jakikolwiek wygenerowany kod → QA review
    if generated_code and len(generated_code.strip()) > 50:
        return "qa_review"

    return "finish"


def after_qa(state: dict) -> str:
    """
    Decyduje co robić po QA review.

    Returns:
        "finish" — jeśli PASS lub WARN
        "retry" — jeśli FAIL (ponów generowanie)
    """
    qa_result = state.get("qa_result", {})
    status = qa_result.get("status", "PASS")

    if status == "FAIL":
        return "retry"

    return "finish"
