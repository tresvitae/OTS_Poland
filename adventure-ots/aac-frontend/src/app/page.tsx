'use client';

import Navbar from '@/components/Navbar';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function HomePage() {
    const [onlineCount, setOnlineCount] = useState<number>(0);

    useEffect(() => {
        api.getOnline().then(data => setOnlineCount(data.count)).catch(() => { });
    }, []);

    return (
        <>
            <Navbar />
            <main className="max-w-6xl mx-auto px-4 sm:px-6 py-8">
                {/* Hero Section */}
                <section className="relative text-center py-16 md:py-24">
                    {/* Decorative glow */}
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                        <div className="w-96 h-96 rounded-full bg-blood/5 blur-3xl animate-pulse-slow" />
                    </div>

                    <div className="relative z-10">
                        <div className="text-6xl md:text-7xl mb-6 animate-float-glow">🛡️</div>
                        <h1 className="font-cinzel text-4xl md:text-6xl font-bold text-gold mb-4 tracking-wide">
                            Adventure OTS
                        </h1>
                        <p className="text-stone-light/70 text-lg md:text-xl max-w-2xl mx-auto leading-relaxed mb-2">
                            Wkrocz do mrocznego świata pełnego niebezpieczeństw, tajemnic i epickich przygód.
                        </p>
                        <p className="text-stone-dark text-sm mb-8">
                            The Forgotten Server 1.4.2 • Protocol 10.98
                        </p>

                        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                            <Link href="/register" className="btn-fantasy text-base px-8 py-4">
                                ⚔️ Dołącz do gry
                            </Link>
                            <Link href="/highscores" className="btn-fantasy-gold text-base px-8 py-4">
                                🏆 Ranking
                            </Link>
                        </div>
                    </div>
                </section>

                <div className="divider-fantasy" />

                {/* Info Cards */}
                <section className="grid grid-cols-1 md:grid-cols-3 gap-6 py-8">
                    <div className="fantasy-card text-center">
                        <div className="text-3xl mb-3">⚔️</div>
                        <h3 className="font-cinzel text-lg text-gold font-semibold mb-2">Graczy Online</h3>
                        <p className="text-3xl font-bold text-blood-light">{onlineCount}</p>
                        <Link href="/online" className="text-xs text-stone-dark hover:text-gold mt-2 inline-block transition-colors">
                            Zobacz kto gra →
                        </Link>
                    </div>

                    <div className="fantasy-card text-center">
                        <div className="text-3xl mb-3">🎮</div>
                        <h3 className="font-cinzel text-lg text-gold font-semibold mb-2">Serwer</h3>
                        <p className="text-sm text-stone-light/80 mb-1">IP: 127.0.0.1</p>
                        <p className="text-sm text-stone-light/80 mb-1">Port: 7171</p>
                        <p className="text-xs text-stone-dark">TFS 1.4.2 • PvP</p>
                    </div>

                    <div className="fantasy-card text-center">
                        <div className="text-3xl mb-3">📜</div>
                        <h3 className="font-cinzel text-lg text-gold font-semibold mb-2">Cechy Serwera</h3>
                        <ul className="text-sm text-stone-light/70 space-y-1">
                            <li>🗡️ Experience Stages</li>
                            <li>🛡️ Skill Rate x3</li>
                            <li>💰 Loot Rate x2</li>
                        </ul>
                    </div>
                </section>

                <div className="divider-fantasy" />

                {/* Experience Stages */}
                <section className="py-8">
                    <h2 className="section-title mb-6">📊 Experience Stages</h2>
                    <div className="fantasy-card overflow-x-auto">
                        <table className="table-fantasy">
                            <thead>
                                <tr>
                                    <th>Poziom</th>
                                    <th>Mnożnik EXP</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr><td>1 – 8</td><td className="text-gold font-semibold">x7</td></tr>
                                <tr><td>9 – 20</td><td className="text-gold font-semibold">x6</td></tr>
                                <tr><td>21 – 50</td><td className="text-gold font-semibold">x5</td></tr>
                                <tr><td>51 – 100</td><td className="text-gold font-semibold">x4</td></tr>
                                <tr><td>101+</td><td className="text-gold font-semibold">x3</td></tr>
                            </tbody>
                        </table>
                    </div>
                </section>

                {/* Footer */}
                <footer className="text-center py-8 text-stone-dark text-xs border-t border-abyss-600/20 mt-8">
                    <p>Adventure OTS © {new Date().getFullYear()} • Powered by TFS 1.4.2 &amp; AAC</p>
                </footer>
            </main>
        </>
    );
}
