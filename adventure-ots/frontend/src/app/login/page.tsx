'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Navbar from '@/components/Navbar';
import { api, setToken } from '@/lib/api';

export default function LoginPage() {
    const router = useRouter();
    const [form, setForm] = useState({ name: '', password: '' });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const data = await api.login(form.name, form.password);
            setToken(data.token);
            router.push('/account');
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Nieprawidłowe dane logowania');
        } finally {
            setLoading(false);
        }
    };

    return (
        <>
            <Navbar />
            <main className="max-w-md mx-auto px-4 py-12">
                <div className="fantasy-card">
                    <h1 className="section-title mb-8 text-center w-full">🔑 Logowanie</h1>

                    {error && (
                        <div className="mb-4 px-4 py-3 rounded bg-blood-dark/30 border border-blood/40 text-blood-glow text-sm">
                            ⚠️ {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="space-y-5">
                        <div>
                            <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                Nazwa konta
                            </label>
                            <input
                                type="text"
                                className="input-fantasy"
                                placeholder="Twoja nazwa konta"
                                value={form.name}
                                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                Hasło
                            </label>
                            <input
                                type="password"
                                className="input-fantasy"
                                placeholder="Twoje hasło"
                                value={form.password}
                                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                                required
                            />
                        </div>

                        <button type="submit" className="btn-fantasy w-full" disabled={loading}>
                            {loading ? '⏳ Logowanie...' : '🔑 Zaloguj się'}
                        </button>
                    </form>

                    <p className="text-center text-stone-dark text-sm mt-6">
                        Nie masz konta?{' '}
                        <Link href="/register" className="text-gold hover:text-gold-light transition-colors">
                            Załóż konto
                        </Link>
                    </p>
                </div>
            </main>
        </>
    );
}
