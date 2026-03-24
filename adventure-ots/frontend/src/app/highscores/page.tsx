'use client';

import { useEffect, useState } from 'react';
import Navbar from '@/components/Navbar';
import { api, HighscoreEntry } from '@/lib/api';

export default function HighscoresPage() {
    const [highscores, setHighscores] = useState<HighscoreEntry[]>([]);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(true);

    const LIMIT = 25;

    useEffect(() => {
        loadHighscores();
    }, [page]);

    const loadHighscores = async () => {
        setLoading(true);
        try {
            const data = await api.getHighscores(page, LIMIT);
            setHighscores(data.highscores);
            setTotalPages(data.pagination.totalPages);
            setTotal(data.pagination.total);
        } catch {
            // Silently handle error
        } finally {
            setLoading(false);
        }
    };

    const getRankMedal = (rank: number): string => {
        if (rank === 1) return '🥇';
        if (rank === 2) return '🥈';
        if (rank === 3) return '🥉';
        return `#${rank}`;
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
                <h1 className="section-title mb-2">🏆 Highscores</h1>
                <p className="text-stone-dark text-sm mb-6">
                    Ranking graczy — łącznie: <span className="text-gold">{total}</span>
                </p>

                {loading ? (
                    <div className="fantasy-card text-center py-12">
                        <p className="text-stone animate-pulse">⏳ Ładowanie rankingu...</p>
                    </div>
                ) : highscores.length === 0 ? (
                    <div className="fantasy-card text-center py-12">
                        <p className="text-stone-dark text-lg">Brak graczy w rankingu</p>
                    </div>
                ) : (
                    <>
                        <div className="fantasy-card overflow-x-auto">
                            <table className="table-fantasy">
                                <thead>
                                    <tr>
                                        <th className="w-16">#</th>
                                        <th>Nazwa</th>
                                        <th>Poziom</th>
                                        <th className="hidden sm:table-cell">Doświadczenie</th>
                                        <th>Profesja</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {highscores.map((player, index) => {
                                        const rank = (page - 1) * LIMIT + index + 1;
                                        return (
                                            <tr key={player.name} className={rank <= 3 ? 'bg-gold-dark/5' : ''}>
                                                <td className={`font-bold ${rank <= 3 ? 'text-lg' : 'text-stone-dark'}`}>
                                                    {getRankMedal(rank)}
                                                </td>
                                                <td className={`font-semibold ${rank === 1 ? 'text-gold text-lg' : 'text-parchment'}`}>
                                                    {player.name}
                                                </td>
                                                <td className="text-gold font-bold">{player.level}</td>
                                                <td className="hidden sm:table-cell text-stone-light/70">
                                                    {player.experience.toLocaleString()}
                                                </td>
                                                <td>
                                                    <span className="mr-1">{getVocationIcon(player.vocation_name)}</span>
                                                    {player.vocation_name}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>

                        {/* Pagination */}
                        {totalPages > 1 && (
                            <div className="flex items-center justify-center gap-2 mt-6">
                                <button
                                    onClick={() => setPage(p => Math.max(1, p - 1))}
                                    disabled={page === 1}
                                    className="px-4 py-2 rounded border border-abyss-600/40 text-sm
                           text-stone-light hover:text-gold hover:border-gold/30 
                           disabled:opacity-30 disabled:cursor-not-allowed transition-all"
                                >
                                    ← Poprzednia
                                </button>
                                <span className="text-stone-dark text-sm px-4">
                                    Strona <span className="text-gold">{page}</span> z {totalPages}
                                </span>
                                <button
                                    onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                                    disabled={page === totalPages}
                                    className="px-4 py-2 rounded border border-abyss-600/40 text-sm
                           text-stone-light hover:text-gold hover:border-gold/30 
                           disabled:opacity-30 disabled:cursor-not-allowed transition-all"
                                >
                                    Następna →
                                </button>
                            </div>
                        )}
                    </>
                )}
            </main>
        </>
    );
}
