'use client';

import { useEffect, useState } from 'react';
import Navbar from '@/components/Navbar';
import { api, OnlinePlayer } from '@/lib/api';

export default function OnlinePage() {
    const [players, setPlayers] = useState<OnlinePlayer[]>([]);
    const [count, setCount] = useState(0);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadOnline();
        // Auto-refresh every 30 seconds
        const interval = setInterval(loadOnline, 30000);
        return () => clearInterval(interval);
    }, []);

    const loadOnline = async () => {
        try {
            const data = await api.getOnline();
            setPlayers(data.online);
            setCount(data.count);
        } catch {
            // Silently handle
        } finally {
            setLoading(false);
        }
    };

    const getVocationIcon = (vocationName: string): string => {
        switch (vocationName) {
            case 'Sorcerer': case 'Master Sorcerer': return '🔮';
            case 'Druid': case 'Elder Druid': return '🌿';
            case 'Paladin': case 'Royal Paladin': return '🏹';
            case 'Knight': case 'Elite Knight': return '🗡️';
            default: return '👤';
        }
    };

    return (
        <>
            <Navbar />
            <main className="max-w-4xl mx-auto px-4 py-8">
                <div className="flex items-center gap-4 mb-6">
                    <h1 className="section-title">⚔️ Who Is Online</h1>
                    <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-abyss-800/50 border border-abyss-600/30">
                        <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                        <span className="text-sm text-stone-light">{count} online</span>
                    </div>
                </div>

                {loading ? (
                    <div className="fantasy-card text-center py-12">
                        <p className="text-stone animate-pulse">⏳ Ładowanie...</p>
                    </div>
                ) : players.length === 0 ? (
                    <div className="fantasy-card text-center py-12">
                        <div className="text-4xl mb-4">🌙</div>
                        <p className="text-stone-dark text-lg mb-2">Nikt nie jest teraz online</p>
                        <p className="text-stone-dark text-sm">Zaloguj się do gry i bądź pierwszy!</p>
                    </div>
                ) : (
                    <div className="fantasy-card overflow-x-auto">
                        <table className="table-fantasy">
                            <thead>
                                <tr>
                                    <th>Nazwa</th>
                                    <th>Poziom</th>
                                    <th>Profesja</th>
                                </tr>
                            </thead>
                            <tbody>
                                {players.map(player => (
                                    <tr key={player.name}>
                                        <td className="font-semibold text-parchment">
                                            <span className="w-2 h-2 rounded-full bg-green-500 inline-block mr-2" />
                                            {player.name}
                                        </td>
                                        <td className="text-gold font-bold">{player.level}</td>
                                        <td>
                                            <span className="mr-1">{getVocationIcon(player.vocation_name)}</span>
                                            {player.vocation_name}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}

                <p className="text-center text-stone-dark text-xs mt-4">
                    Lista odświeża się automatycznie co 30 sekund
                </p>
            </main>
        </>
    );
}
