"""
QA/Reviewer Agent — kontrola jakości wygenerowanego kodu.

Sprawdza kod Lua/PHP/XML pod kątem:
- Nieskończonych pętli
- Bugów klonowania (cloning bug, duplikacja złota)
- Niezgodności z protokołem TFS 1.4.2/1.5 (nie Canary!)
- Nieprawidłowych storage keys, action IDs, item IDs
- Race conditions i exploity

Zwraca: PASS / WARN / FAIL + lista problemów.
"""

from langchain_core.messages import HumanMessage, SystemMessage

from src.config.settings import get_llm
from src.prompts.qa_prompt import QA_SYSTEM_PROMPT


def create_qa_agent():
    """Tworzy agenta QA/Reviewer."""
    llm = get_llm()

    def qa_node(state: dict) -> dict:
        """
        Węzeł QA w grafie LangGraph.
        Czyta wygenerowany kod i szuka błędów.
        """
        messages = state.get("messages", [])
        generated_code = state.get("generated_code", "")

        # Buduj wiadomość z kodem do recenzji
        review_request = (
            f"Przejrzyj poniższy wygenerowany kod i szukaj błędów:\n\n"
            f"```\n{generated_code}\n```\n\n"
            f"Sprawdź zgodność z TFS 1.4.2 (protokół 10.98). "
            f"Szukaj: nieskończonych pętli, cloning bugów, exploitów, "
            f"niezgodności z API TFS 1.4. Zwróć wynik: PASS / WARN / FAIL."
        )

        response = llm.invoke([
            SystemMessage(content=QA_SYSTEM_PROMPT),
            HumanMessage(content=review_request),
        ])

        # Parsuj wynik QA
        qa_result = _parse_qa_result(response.content)

        return {
            "messages": messages + [response],
            "qa_result": qa_result,
        }

    return qa_node


def _parse_qa_result(response_text: str) -> dict:
    """
    Parsuje odpowiedź QA i wyciąga wynik.

    Returns:
        dict z kluczami:
        - status: "PASS" | "WARN" | "FAIL"
        - issues: lista znalezionych problemów
        - summary: podsumowanie recenzji
    """
    response_upper = response_text.upper()

    if "FAIL" in response_upper:
        status = "FAIL"
    elif "WARN" in response_upper:
        status = "WARN"
    else:
        status = "PASS"

    return {
        "status": status,
        "issues": _extract_issues(response_text),
        "summary": response_text,
    }


def _extract_issues(text: str) -> list[str]:
    """Wyciąga listę problemów z tekstu recenzji."""
    issues = []
    for line in text.split("\n"):
        stripped = line.strip()
        # Szukaj linii zaczynających się od markera problemu
        if stripped.startswith(("- ❌", "- ⚠️", "- [FAIL]", "- [WARN]", "- BUG:")):
            issues.append(stripped)
    return issues
