'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { isAuthenticated, removeToken } from '@/lib/api';

const NAV_LINKS = [
    { href: '/', label: 'Home', icon: '🏰' },
    { href: '/highscores', label: 'Highscores', icon: '🏆' },
    { href: '/online', label: 'Online', icon: '⚔️' },
    { href: '/download', label: 'Download', icon: '📥' },
];

export default function Navbar() {
    const pathname = usePathname();
    const [loggedIn, setLoggedIn] = useState(false);
    const [menuOpen, setMenuOpen] = useState(false);

    useEffect(() => {
        setLoggedIn(isAuthenticated());
    }, [pathname]);

    const handleLogout = () => {
        removeToken();
        setLoggedIn(false);
        window.location.href = '/';
    };

    return (
        <nav className="sticky top-0 z-50 border-b border-abyss-600/40 bg-abyss-950/90 backdrop-blur-md">
            <div className="max-w-6xl mx-auto px-4 sm:px-6">
                <div className="flex items-center justify-between h-16">
                    {/* Logo */}
                    <Link href="/" className="flex items-center gap-2 group">
                        <span className="text-2xl group-hover:scale-110 transition-transform duration-300">🛡️</span>
                        <span className="font-cinzel font-bold text-gold tracking-wider text-lg hidden sm:block
                           group-hover:text-gold-light transition-colors duration-300">
                            Adventure OTS
                        </span>
                    </Link>

                    {/* Desktop Nav */}
                    <div className="hidden md:flex items-center gap-1">
                        {NAV_LINKS.map(link => (
                            <Link
                                key={link.href}
                                href={link.href}
                                className={`px-4 py-2 rounded text-sm font-medium tracking-wide transition-all duration-200
                  ${pathname === link.href
                                        ? 'text-gold bg-abyss-700/50 border border-gold/20'
                                        : 'text-stone-light hover:text-gold hover:bg-abyss-700/30'
                                    }`}
                            >
                                <span className="mr-1.5">{link.icon}</span>
                                {link.label}
                            </Link>
                        ))}

                        <div className="w-px h-6 bg-abyss-600/40 mx-2" />

                        {loggedIn ? (
                            <>
                                <Link
                                    href="/account"
                                    className={`px-4 py-2 rounded text-sm font-medium tracking-wide transition-all duration-200
                    ${pathname === '/account'
                                            ? 'text-gold bg-abyss-700/50 border border-gold/20'
                                            : 'text-stone-light hover:text-gold hover:bg-abyss-700/30'
                                        }`}
                                >
                                    <span className="mr-1.5">👤</span>
                                    My Account
                                </Link>
                                <button
                                    onClick={handleLogout}
                                    className="px-4 py-2 rounded text-sm font-medium text-blood-light 
                           hover:text-blood-glow hover:bg-blood-dark/20 transition-all duration-200"
                                >
                                    Logout
                                </button>
                            </>
                        ) : (
                            <>
                                <Link
                                    href="/login"
                                    className="px-4 py-2 rounded text-sm font-medium text-stone-light 
                           hover:text-gold hover:bg-abyss-700/30 transition-all duration-200"
                                >
                                    Login
                                </Link>
                                <Link
                                    href="/register"
                                    className="btn-fantasy text-xs py-2 px-4"
                                >
                                    Register
                                </Link>
                            </>
                        )}
                    </div>

                    {/* Mobile hamburger */}
                    <button
                        onClick={() => setMenuOpen(!menuOpen)}
                        className="md:hidden p-2 text-stone-light hover:text-gold transition-colors"
                        aria-label="Toggle menu"
                    >
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            {menuOpen ? (
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            ) : (
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                            )}
                        </svg>
                    </button>
                </div>

                {/* Mobile menu */}
                {menuOpen && (
                    <div className="md:hidden pb-4 border-t border-abyss-600/30 mt-2 pt-3 space-y-1">
                        {NAV_LINKS.map(link => (
                            <Link
                                key={link.href}
                                href={link.href}
                                onClick={() => setMenuOpen(false)}
                                className={`block px-4 py-2 rounded text-sm transition-all
                  ${pathname === link.href ? 'text-gold bg-abyss-700/50' : 'text-stone-light hover:text-gold'}`}
                            >
                                <span className="mr-2">{link.icon}</span>{link.label}
                            </Link>
                        ))}
                        <div className="divider-fantasy !my-3" />
                        {loggedIn ? (
                            <>
                                <Link href="/account" onClick={() => setMenuOpen(false)}
                                    className="block px-4 py-2 rounded text-sm text-stone-light hover:text-gold">
                                    👤 My Account
                                </Link>
                                <button onClick={handleLogout}
                                    className="block w-full text-left px-4 py-2 rounded text-sm text-blood-light hover:text-blood-glow">
                                    Logout
                                </button>
                            </>
                        ) : (
                            <>
                                <Link href="/login" onClick={() => setMenuOpen(false)}
                                    className="block px-4 py-2 rounded text-sm text-stone-light hover:text-gold">
                                    Login
                                </Link>
                                <Link href="/register" onClick={() => setMenuOpen(false)}
                                    className="block px-4 py-2 rounded text-sm text-blood-light hover:text-blood-glow">
                                    Register
                                </Link>
                            </>
                        )}
                    </div>
                )}
            </div>
        </nav>
    );
}
