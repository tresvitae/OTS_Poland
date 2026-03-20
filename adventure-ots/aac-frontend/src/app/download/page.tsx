'use client';

import Navbar from '@/components/Navbar';

export default function DownloadPage() {
    return (
        <>
            <Navbar />
            <main className="max-w-4xl mx-auto px-4 py-8">
                <div className="flex items-center gap-4 mb-6">
                    <h1 className="section-title">📥 Pobierz Klienta (Download)</h1>
                </div>

                <div className="fantasy-card p-8 text-center space-y-6">
                    <div className="text-6xl mb-4">🛡️</div>
                    <h2 className="text-2xl font-cinzel font-bold text-gold">
                        Tibia Client (Protocol 10.98)
                    </h2>
                    <p className="text-stone-light max-w-lg mx-auto">
                        Pobierz dedykowany klient do naszego serwera. Zawiera on wszystkie wymagane pliki (spr, dat)
                        oraz wstępnie skonfigurowane połączenie.
                    </p>
                    
                    <div className="pt-4 space-y-4">
                        <a 
                            href="#" 
                            className="inline-block btn-fantasy text-lg px-8 py-4"
                            onClick={(e) => {
                                e.preventDefault();
                                alert('Link do pobrania klienta będzie wkrótce dostępny!');
                            }}
                        >
                            Pobierz (Windows / Linux / Mac)
                        </a>
                        
                        <p className="text-stone-dark text-sm mt-2">
                            Rozmiar pliku: ~50 MB
                        </p>
                    </div>
                </div>

                <div className="mt-8 fantasy-card bg-abyss-900/50">
                    <h3 className="text-xl font-cinzel text-gold mb-4">Instrukcja instalacji:</h3>
                    <ol className="list-decimal list-inside space-y-2 text-stone-light">
                        <li>Pobierz archiwum ZIP.</li>
                        <li>Wypakuj zawartość do wybranego folderu na swoim dysku.</li>
                        <li>Uruchom plik wykonywalny klienta.</li>
                        <li>Załóż postać na stronie, zaloguj się w kliencie i ciesz się grą!</li>
                    </ol>
                </div>
            </main>
        </>
    );
}
