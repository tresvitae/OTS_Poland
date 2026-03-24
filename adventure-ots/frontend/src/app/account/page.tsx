'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Navbar from '@/components/Navbar';
import { api, isAuthenticated, Character } from '@/lib/api';

const VOCATIONS = [
    { id: 1, name: 'Sorcerer', icon: '🔮', desc: 'Master of destructive magic' },
    { id: 2, name: 'Druid', icon: '🌿', desc: 'Healer and nature mage' },
    { id: 3, name: 'Paladin', icon: '🏹', desc: 'Holy warrior with ranged skills' },
    { id: 4, name: 'Knight', icon: '🗡️', desc: 'Melee tank and warrior' },
];

export default function AccountPage() {
    const router = useRouter();
    const [characters, setCharacters] = useState<Character[]>([]);
    const [loading, setLoading] = useState(true);

    // Create character form
    const [showCreate, setShowCreate] = useState(false);
    const [charForm, setCharForm] = useState({ name: '', vocation: 1, sex: 1 });
    const [charError, setCharError] = useState('');
    const [charSuccess, setCharSuccess] = useState('');
    const [charLoading, setCharLoading] = useState(false);

    // Change password form
    const [showPassword, setShowPassword] = useState(false);
    const [passForm, setPassForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
    const [passError, setPassError] = useState('');
    const [passSuccess, setPassSuccess] = useState('');
    const [passLoading, setPassLoading] = useState(false);

    useEffect(() => {
        if (!isAuthenticated()) {
            router.push('/login');
            return;
        }
        loadCharacters();
    }, [router]);

    const loadCharacters = async () => {
        try {
            const data = await api.getCharacters();
            setCharacters(data.characters);
        } catch {
            // Token expired — redirect to login
            router.push('/login');
        } finally {
            setLoading(false);
        }
    };

    const handleCreateCharacter = async (e: React.FormEvent) => {
        e.preventDefault();
        setCharError('');
        setCharSuccess('');
        setCharLoading(true);

        try {
            await api.createCharacter(charForm.name, charForm.vocation, charForm.sex);
            setCharSuccess(`Postać "${charForm.name}" została utworzona!`);
            setCharForm({ name: '', vocation: 1, sex: 1 });
            await loadCharacters();
            setTimeout(() => setShowCreate(false), 2000);
        } catch (err: unknown) {
            setCharError(err instanceof Error ? err.message : 'Błąd tworzenia postaci');
        } finally {
            setCharLoading(false);
        }
    };

    const handleChangePassword = async (e: React.FormEvent) => {
        e.preventDefault();
        setPassError('');
        setPassSuccess('');

        if (passForm.newPassword !== passForm.confirmPassword) {
            setPassError('Nowe hasła nie są identyczne');
            return;
        }

        setPassLoading(true);
        try {
            await api.changePassword(passForm.currentPassword, passForm.newPassword);
            setPassSuccess('Hasło zostało zmienione!');
            setPassForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
        } catch (err: unknown) {
            setPassError(err instanceof Error ? err.message : 'Błąd zmiany hasła');
        } finally {
            setPassLoading(false);
        }
    };

    if (loading) {
        return (
            <>
                <Navbar />
                <main className="max-w-4xl mx-auto px-4 py-12 text-center">
                    <p className="text-stone animate-pulse">⏳ Ładowanie...</p>
                </main>
            </>
        );
    }

    return (
        <>
            <Navbar />
            <main className="max-w-4xl mx-auto px-4 py-8 space-y-8">
                {/* Characters Section */}
                <section>
                    <div className="flex items-center justify-between mb-6">
                        <h1 className="section-title">👤 Moje Konto</h1>
                        <button
                            onClick={() => { setShowCreate(!showCreate); setCharError(''); setCharSuccess(''); }}
                            className="btn-fantasy text-xs py-2"
                        >
                            {showCreate ? '✕ Anuluj' : '➕ Nowa Postać'}
                        </button>
                    </div>

                    {/* Create Character Form */}
                    {showCreate && (
                        <div className="fantasy-card mb-6">
                            <h2 className="font-cinzel text-lg text-gold mb-4">Tworzenie Postaci</h2>

                            {charError && (
                                <div className="mb-4 px-4 py-3 rounded bg-blood-dark/30 border border-blood/40 text-blood-glow text-sm">
                                    ⚠️ {charError}
                                </div>
                            )}
                            {charSuccess && (
                                <div className="mb-4 px-4 py-3 rounded bg-gold-dark/20 border border-gold/30 text-gold-light text-sm">
                                    ✅ {charSuccess}
                                </div>
                            )}

                            <form onSubmit={handleCreateCharacter} className="space-y-5">
                                <div>
                                    <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                        Nazwa postaci
                                    </label>
                                    <input
                                        type="text"
                                        className="input-fantasy"
                                        placeholder="np. Dark Warrior"
                                        value={charForm.name}
                                        onChange={e => setCharForm(f => ({ ...f, name: e.target.value }))}
                                        required
                                        minLength={2}
                                        maxLength={29}
                                    />
                                </div>

                                <div>
                                    <label className="block text-xs uppercase tracking-wider text-stone mb-3 font-cinzel">
                                        Profesja
                                    </label>
                                    <div className="grid grid-cols-2 gap-3">
                                        {VOCATIONS.map(voc => (
                                            <button
                                                key={voc.id}
                                                type="button"
                                                onClick={() => setCharForm(f => ({ ...f, vocation: voc.id }))}
                                                className={`p-3 rounded border text-left transition-all duration-200
                          ${charForm.vocation === voc.id
                                                        ? 'border-gold/50 bg-gold-dark/20 shadow-glow-gold'
                                                        : 'border-abyss-600/40 bg-abyss-800/30 hover:border-stone-dark'
                                                    }`}
                                            >
                                                <div className="text-xl mb-1">{voc.icon}</div>
                                                <div className="font-cinzel text-sm text-gold">{voc.name}</div>
                                                <div className="text-xs text-stone-dark">{voc.desc}</div>
                                            </button>
                                        ))}
                                    </div>
                                </div>

                                <div>
                                    <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                        Płeć
                                    </label>
                                    <div className="flex gap-4">
                                        <label className={`flex items-center gap-2 cursor-pointer px-4 py-2 rounded border transition-all
                      ${charForm.sex === 1 ? 'border-gold/40 bg-gold-dark/10' : 'border-abyss-600/30'}`}>
                                            <input type="radio" name="sex" value={1} checked={charForm.sex === 1}
                                                onChange={() => setCharForm(f => ({ ...f, sex: 1 }))} className="sr-only" />
                                            <span>♂️ Mężczyzna</span>
                                        </label>
                                        <label className={`flex items-center gap-2 cursor-pointer px-4 py-2 rounded border transition-all
                      ${charForm.sex === 0 ? 'border-gold/40 bg-gold-dark/10' : 'border-abyss-600/30'}`}>
                                            <input type="radio" name="sex" value={0} checked={charForm.sex === 0}
                                                onChange={() => setCharForm(f => ({ ...f, sex: 0 }))} className="sr-only" />
                                            <span>♀️ Kobieta</span>
                                        </label>
                                    </div>
                                </div>

                                <button type="submit" className="btn-fantasy-gold w-full" disabled={charLoading}>
                                    {charLoading ? '⏳ Tworzenie...' : '⚔️ Utwórz Postać'}
                                </button>
                            </form>
                        </div>
                    )}

                    {/* Characters List */}
                    {characters.length > 0 ? (
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
                                    {characters.map(char => (
                                        <tr key={char.id}>
                                            <td className="font-semibold text-parchment">{char.name}</td>
                                            <td className="text-gold">{char.level}</td>
                                            <td>{char.vocation_name}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    ) : (
                        <div className="fantasy-card text-center py-8">
                            <p className="text-stone-dark text-lg mb-2">Nie masz jeszcze żadnej postaci</p>
                            <p className="text-stone-dark text-sm">Kliknij &quot;Nowa Postać&quot; aby utworzyć swoją pierwszą postać</p>
                        </div>
                    )}
                </section>

                <div className="divider-fantasy" />

                {/* Change Password Section */}
                <section>
                    <button
                        onClick={() => { setShowPassword(!showPassword); setPassError(''); setPassSuccess(''); }}
                        className="section-title cursor-pointer hover:text-gold-light transition-colors"
                    >
                        🔒 Zmiana Hasła
                        <span className="text-sm text-stone-dark ml-2">{showPassword ? '▲' : '▼'}</span>
                    </button>

                    {showPassword && (
                        <div className="fantasy-card mt-6">
                            {passError && (
                                <div className="mb-4 px-4 py-3 rounded bg-blood-dark/30 border border-blood/40 text-blood-glow text-sm">
                                    ⚠️ {passError}
                                </div>
                            )}
                            {passSuccess && (
                                <div className="mb-4 px-4 py-3 rounded bg-gold-dark/20 border border-gold/30 text-gold-light text-sm">
                                    ✅ {passSuccess}
                                </div>
                            )}

                            <form onSubmit={handleChangePassword} className="space-y-5 max-w-md">
                                <div>
                                    <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                        Aktualne hasło
                                    </label>
                                    <input
                                        type="password"
                                        className="input-fantasy"
                                        value={passForm.currentPassword}
                                        onChange={e => setPassForm(f => ({ ...f, currentPassword: e.target.value }))}
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                        Nowe hasło
                                    </label>
                                    <input
                                        type="password"
                                        className="input-fantasy"
                                        placeholder="Minimum 4 znaki"
                                        value={passForm.newPassword}
                                        onChange={e => setPassForm(f => ({ ...f, newPassword: e.target.value }))}
                                        required
                                        minLength={4}
                                    />
                                </div>
                                <div>
                                    <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                        Powtórz nowe hasło
                                    </label>
                                    <input
                                        type="password"
                                        className="input-fantasy"
                                        value={passForm.confirmPassword}
                                        onChange={e => setPassForm(f => ({ ...f, confirmPassword: e.target.value }))}
                                        required
                                        minLength={4}
                                    />
                                </div>
                                <button type="submit" className="btn-fantasy" disabled={passLoading}>
                                    {passLoading ? '⏳ Zmiana...' : '🔒 Zmień Hasło'}
                                </button>
                            </form>
                        </div>
                    )}
                </section>
            </main>
        </>
    );
}
