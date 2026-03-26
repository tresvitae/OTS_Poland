import fs from 'fs';
import path from 'path';

import Navbar from '@/components/Navbar';

export const dynamic = 'force-dynamic';

type PlatformDownloadConfig = {
    id: string;
    label: string;
    ctaLabel: string;
    route: string;
    operatorPathHint: string;
    fsPath: string;
};

const PLATFORM_DOWNLOADS: PlatformDownloadConfig[] = [
    {
        id: 'windows',
        label: 'Windows',
        ctaLabel: 'Pobierz dla Windows (ZIP)',
        route: '/downloads/windows/adventure-ots-client-windows.zip',
        operatorPathHint: 'frontend/public/downloads/windows/adventure-ots-client-windows.zip',
        fsPath: path.join(
            process.cwd(),
            'public',
            'downloads',
            'windows',
            'adventure-ots-client-windows.zip',
        ),
    },
    {
        id: 'macos-arm64',
        label: 'macOS (Apple Silicon)',
        ctaLabel: 'Pobierz dla macOS arm64 (ZIP)',
        route: '/downloads/macos/adventure-ots-client-macos-arm64.zip',
        operatorPathHint: 'frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip',
        fsPath: path.join(
            process.cwd(),
            'public',
            'downloads',
            'macos',
            'adventure-ots-client-macos-arm64.zip',
        ),
    },
];

type PlatformDownloadStatus = PlatformDownloadConfig & {
    available: boolean;
    sizeLabel: string | null;
};

function getDownloadStatuses(): PlatformDownloadStatus[] {
    return PLATFORM_DOWNLOADS.map((platform) => {
        if (!fs.existsSync(platform.fsPath)) {
            return { ...platform, available: false, sizeLabel: null };
        }

        const bytes = fs.statSync(platform.fsPath).size;
        return {
            ...platform,
            available: true,
            sizeLabel: formatBytes(bytes),
        };
    });
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
    const downloadStatuses = getDownloadStatuses();
    const allMissing = downloadStatuses.every((status) => !status.available);

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
                        {allMissing && (
                            <div className="rounded border border-red-500 bg-red-500/10 px-4 py-3 text-red-300" role="alert">
                                Brak paczek klienta na serwerze WWW dla wszystkich platform. Dodaj artefakty,
                                aby odblokować pobieranie.
                            </div>
                        )}

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-left">
                            {downloadStatuses.map((platform) => (
                                <section
                                    key={platform.id}
                                    className="rounded-lg border border-gold/30 bg-abyss-900/40 p-4 space-y-3"
                                    aria-label={`Status pobierania dla ${platform.label}`}
                                >
                                    <h3 className="text-lg font-cinzel font-semibold text-gold">{platform.label}</h3>

                                    {platform.available ? (
                                        <>
                                            <a
                                                href={platform.route}
                                                className="inline-block btn-fantasy text-base px-6 py-3"
                                                download
                                                aria-label={`Pobierz klient Adventure OTS dla ${platform.label}`}
                                            >
                                                {platform.ctaLabel}
                                            </a>
                                            <p className="text-stone-dark text-sm">
                                                Rozmiar pliku: {platform.sizeLabel ?? 'nieznany'}
                                            </p>
                                        </>
                                    ) : (
                                        <>
                                            <div
                                                className="rounded border border-red-500 bg-red-500/10 px-3 py-2 text-red-300 text-sm"
                                                role="status"
                                            >
                                                Brak artefaktu dla tej platformy.
                                            </div>
                                            <p className="text-stone-light text-sm">Operator hint (exact path):</p>
                                            <p className="text-gold text-sm break-all">{platform.operatorPathHint}</p>
                                        </>
                                    )}
                                </section>
                            ))}
                        </div>

                        {!allMissing && (
                            <div className="text-stone-light text-sm max-w-xl mx-auto">
                                Jeśli kliknięcie zwraca 404, sprawdź czy odpowiedni plik ZIP istnieje w katalogu
                                wskazanym przy danej platformie.
                            </div>
                        )}
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
