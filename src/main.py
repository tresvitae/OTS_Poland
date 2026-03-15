"""
Adventure OTS — Multi-Agent System
Punkt wejścia do aplikacji.

Uruchamia interaktywną pętlę CLI, w której użytkownik
wysyła polecenia przetwarzane przez graf LangGraph.
"""

from langchain_core.messages import HumanMessage

from src.graph.main_graph import build_graph


def main():
    """Główna pętla CLI — interakcja z systemem agentów."""
    print("=" * 60)
    print("  🏰 Adventure OTS — Multi-Agent System")
    print("  Silnik: TFS 1.4.2 | Protokół: 10.98")
    print("  LLM: Anthropic Claude | Tracing: LangSmith")
    print("=" * 60)
    print()
    print("Wpisz polecenie dla systemu agentów.")
    print("Przykłady:")
    print('  → "Stwórz prosty quest na zabicie 10 szczurów"')
    print('  → "Wygeneruj NPC kupca z mrocznym dialogiem"')
    print('  → "Przygotuj docker-compose.yml dla serwera"')
    print('  → "Przeanalizuj spawny z map-spawns.xml"')
    print()
    print("Wpisz 'quit' lub 'exit' aby zakończyć.")
    print("-" * 60)

    # Zbuduj graf
    graph = build_graph()

    while True:
        try:
            user_input = input("\n🎮 Polecenie> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\n👋 Do zobaczenia, wędrowcze!")
            break

        if not user_input:
            continue

        if user_input.lower() in ("quit", "exit", "q"):
            print("\n👋 Do zobaczenia, wędrowcze!")
            break

        print(f"\n⏳ Przetwarzam: \"{user_input}\"...\n")

        try:
            # Uruchom graf z poleceniem użytkownika
            result = graph.invoke({
                "messages": [HumanMessage(content=user_input)],
                "task_type": "",
                "generated_code": "",
                "qa_result": {},
                "current_team": "",
                "map_context": {},
            })

            # Wyświetl wynik
            _display_result(result)

        except Exception as e:
            print(f"\n❌ Błąd: {e}")
            print("Spróbuj ponownie lub sprawdź klucz API w .env")


def _display_result(result: dict):
    """Wyświetla wynik przetwarzania w czytelnym formacie."""
    print("\n" + "=" * 60)
    print("📋 WYNIK")
    print("=" * 60)

    # Zespół
    team = result.get("current_team", "?")
    print(f"\n🏷️  Zespół: {team.upper()}")

    # QA status
    qa = result.get("qa_result", {})
    if qa:
        status = qa.get("status", "?")
        status_emoji = {"PASS": "✅", "WARN": "⚠️", "FAIL": "❌"}.get(status, "❓")
        print(f"🔍 QA Status: {status_emoji} {status}")

        issues = qa.get("issues", [])
        if issues:
            print("\n📝 Znalezione problemy:")
            for issue in issues:
                print(f"   {issue}")

    # Odpowiedź (ostatnia wiadomość)
    messages = result.get("messages", [])
    if messages:
        last_msg = messages[-1]
        print(f"\n💬 Odpowiedź:\n{last_msg.content}")

    print("\n" + "-" * 60)


if __name__ == "__main__":
    main()