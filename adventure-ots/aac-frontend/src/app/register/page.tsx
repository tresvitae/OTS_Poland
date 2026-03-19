'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Navbar from '@/components/Navbar';
import { api } from '@/lib/api';

export default function RegisterPage() {
    const router = useRouter();
    const [form, setForm] = useState({ name: '', password: '', passwordConfirm: '', email: '' });
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSuccess('');

        if (form.password !== form.passwordConfirm) {
            setError('Hasła nie są identyczne');
            return;
        }

        setLoading(true);
        try {
            await api.register(form.name, form.password, form.email);
            setSuccess('Konto zostało utworzone! Przekierowuję do logowania...');
            setTimeout(() => router.push('/login'), 2000);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Wystąpił błąd');
        } finally {
            setLoading(false);
        }
    };

    return (
        <>
            <Navbar />
            <main className="max-w-md mx-auto px-4 py-12">
                <div className="fantasy-card">
                    <h1 className="section-title mb-8 text-center w-full">📜 Rejestracja</h1>

                    {error && (
                        <div className="mb-4 px-4 py-3 rounded bg-blood-dark/30 border border-blood/40 text-blood-glow text-sm">
                            ⚠️ {error}
                        </div>
                    )}

                    {success && (
                        <div className="mb-4 px-4 py-3 rounded bg-gold-dark/20 border border-gold/30 text-gold-light text-sm">
                            ✅ {success}
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
                                placeholder="np. warrior2024"
                                value={form.name}
                                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                                required
                                minLength={3}
                                maxLength={32}
                            />
                        </div>

                        <div>
                            <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                Email
                            </label>
                            <input
                                type="email"
                                className="input-fantasy"
                                placeholder="twoj@email.com"
                                value={form.email}
                                onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
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
                                placeholder="Minimum 4 znaki"
                                value={form.password}
                                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                                required
                                minLength={4}
                            />
                        </div>

                        <div>
                            <label className="block text-xs uppercase tracking-wider text-stone mb-2 font-cinzel">
                                Powtórz hasło
                            </label>
                            <input
                                type="password"
                                className="input-fantasy"
                                placeholder="Powtórz hasło"
                                value={form.passwordConfirm}
                                onChange={e => setForm(f => ({ ...f, passwordConfirm: e.target.value }))}
                                required
                                minLength={4}
                            />
                        </div>

                        <button type="submit" className="btn-fantasy w-full" disabled={loading}>
                            {loading ? '⏳ Tworzenie konta...' : '⚔️ Utwórz konto'}
                        </button>
                    </form>

                    <p className="text-center text-stone-dark text-sm mt-6">
                        Masz już konto?{' '}
                        <Link href="/login" className="text-gold hover:text-gold-light transition-colors">
                            Zaloguj się
                        </Link>
                    </p>
                </div>
            </main>
        </>
    );
}
