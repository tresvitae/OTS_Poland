import type { Config } from 'tailwindcss';

const config: Config = {
    content: [
        './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
        './src/components/**/*.{js,ts,jsx,tsx,mdx}',
        './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    ],
    theme: {
        extend: {
            colors: {
                // Dark Fantasy RPG palette
                'abyss': {
                    950: '#0a0a0f',
                    900: '#0f0f1a',
                    800: '#161625',
                    700: '#1e1e30',
                    600: '#2a2a3d',
                },
                'blood': {
                    DEFAULT: '#8b1a1a',
                    light: '#b22222',
                    dark: '#5c0e0e',
                    glow: '#ff3333',
                },
                'gold': {
                    DEFAULT: '#c9a84c',
                    light: '#e8d589',
                    dark: '#8a7234',
                    glow: '#ffd700',
                },
                'stone': {
                    DEFAULT: '#6b6b7b',
                    light: '#9a9aab',
                    dark: '#3d3d4d',
                },
                'parchment': '#d4c5a9',
            },
            fontFamily: {
                'cinzel': ['Cinzel', 'serif'],
                'inter': ['Inter', 'sans-serif'],
            },
            boxShadow: {
                'glow-red': '0 0 15px rgba(139, 26, 26, 0.5)',
                'glow-gold': '0 0 15px rgba(201, 168, 76, 0.4)',
                'inner-dark': 'inset 0 2px 8px rgba(0, 0, 0, 0.6)',
            },
            backgroundImage: {
                'dark-gradient': 'linear-gradient(180deg, #0a0a0f 0%, #161625 50%, #0f0f1a 100%)',
                'card-gradient': 'linear-gradient(145deg, rgba(30,30,48,0.8) 0%, rgba(15,15,26,0.9) 100%)',
            },
            animation: {
                'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'glow': 'glow 2s ease-in-out infinite alternate',
            },
            keyframes: {
                glow: {
                    '0%': { boxShadow: '0 0 5px rgba(201, 168, 76, 0.2)' },
                    '100%': { boxShadow: '0 0 20px rgba(201, 168, 76, 0.6)' },
                },
            },
        },
    },
    plugins: [],
};

export default config;
