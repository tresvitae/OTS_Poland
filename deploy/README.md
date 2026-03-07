[FAZA WDROŻENIA] Pliki Docker, konfiguracja CI/CD, Github Actions


 „Platforma agentowa oparta o LangGraph do wspomagania projektowania, konfiguracji, testowania i administracji serwera OTS"


Najlepszy wzorzec LangGraph
Dla takiego projektu polecam hierarchical supervisor. Dokumentacja pokazuje, że gdy agentów robi się więcej, pojedynczy supervisor może sobie gorzej radzić, więc lepiej zrobić supervisorów zespołowych i jednego nadrzędnego koordynatora; to bardzo dobrze pasuje do podziału na content team, operations team i support team.
​

Przykład logiczny:

Top Supervisor

Content Supervisor → quest agent, dialog agent, map event agent

Ops Supervisor → log agent, anomaly agent, economy agent

Support Supervisor → ticket agent, moderation agent

Zakres projektu inżynierskiego
Jeśli to ma być projekt dyplomowy lub semestralny, nie próbuj robić pełnego MMO od zera. Lepiej postawić tezę: bierzesz istniejący silnik OTS, który i tak potrzebuje plików serwera oraz bazy danych, a następnie budujesz nad nim warstwę agentową, która automatyzuje wybrane procesy projektowe i operacyjne.

Dobry, realistyczny zakres MVP:

uruchomienie istniejącego serwera OTS i DB,
​

zbieranie eventów z gry do API lub kolejki,
​

supervisor w LangGraph,
​

3 agentów specjalistycznych, np. Balance, QA, GM,
​

panel administracyjny z rekomendacjami i zatwierdzaniem akcji przez człowieka.
​