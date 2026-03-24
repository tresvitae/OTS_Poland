import fs from 'fs';
import path from 'path';

import Navbar from '@/components/Navbar';

export const dynamic = 'force-dynamic';

const DOWNLOAD_ROUTE = '/downloads/windows/adventure-ots-client-windows.zip';
const DOWNLOAD_FS_PATH = path.join(
    process.cwd(),
    'public',
    'downloads',
    'windows',
    'adventure-ots-client-windows.zip',
);

function getZipStatus() {
    if (!fs.existsSync(DOWNLOAD_FS_PATH)) {
        return { available: false, sizeLabel: null } as const;
    }

    const bytes = fs.statSync(DOWNLOAD_FS_PATH).size;
    return {
        available: true,
        sizeLabel: formatBytes(bytes),
    } as const;
}

function formatBytes(bytes: number): string {
    if (!Number.isFinite(bytes) || bytes <= 0) {
        return '0 B';
    }

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    const exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
    const value = bytes / Math.pow(1024, exponent);
    const precision = exponent === 0 ? 0 : 1;

    return `${value.toFixed(precision)} ${units[exponent]}`;
}

export default function DownloadPage() {
    const zipStatus = getZipStatus();

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
                        {zipStatus.available ? (
                            <a
                                href={DOWNLOAD_ROUTE}
                                className="inline-block btn-fantasy text-lg px-8 py-4"
                                download
                            >
                                Pobierz dla Windows (ZIP)
                            </a>
                        ) : (
                            <div className="rounded border border-red-500 bg-red-500/10 px-4 py-3 text-red-300">
                                Brak spakowanego klienta na serwerze WWW. Dodaj plik ZIP,
                                aby umożliwić pobieranie.
                            </div>
                        )}

                        <p className="text-stone-light text-sm max-w-xl mx-auto">
                            Jeśli kliknięcie zwraca 404, dodaj paczkę klienta pod ścieżką:
                            <span className="block text-gold mt-1">frontend/public/downloads/windows/adventure-ots-client-windows.zip</span>
                        </p>
                        
                        <p className="text-stone-dark text-sm mt-2">
                            {zipStatus.available
                                ? `Rozmiar pliku: ${zipStatus.sizeLabel ?? 'nieznany'}`
                                : 'Plik nie został jeszcze umieszczony.'}
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
