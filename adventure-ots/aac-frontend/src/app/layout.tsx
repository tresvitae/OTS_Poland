import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
    title: 'Adventure OTS — Dark Fantasy MMORPG',
    description: 'Adventure OTS — serwer Open Tibia oparty na TFS 1.4.2. Twórz konto, postacie i rywalizuj w rankingu!',
    keywords: 'tibia, ots, open tibia, mmorpg, adventure, rpg',
};

export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="pl">
            <body className="min-h-screen bg-dark-gradient">
                {children}
            </body>
        </html>
    );
}
