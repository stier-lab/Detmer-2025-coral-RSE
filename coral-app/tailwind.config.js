/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Brand colors
        primary: {
          50: '#f0f4ff',
          100: '#e0e9ff',
          200: '#c7d4fd',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#667eea',
          600: '#5568d3',
          700: '#4553b8',
          800: '#37439d',
          900: '#2e3582',
        },
        secondary: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#764ba2',
          600: '#613c87',
          700: '#4c2e6d',
          800: '#3a2254',
          900: '#2a1a3e',
        },
        // Compartment colors
        external: {
          light: '#6ee7b7',
          DEFAULT: '#10b981',
          dark: '#059669',
        },
        lab: {
          light: '#93c5fd',
          DEFAULT: '#3b82f6',
          dark: '#2563eb',
        },
        orchard: {
          light: '#5eead4',
          DEFAULT: '#06b6d4',
          dark: '#0891b2',
        },
        reef: {
          light: '#fca5a5',
          DEFAULT: '#f43f5e',
          dark: '#dc2626',
        },
        // Size class colors
        sizeclass: {
          sc1: '#10b981',
          sc2: '#3b82f6',
          sc3: '#8b5cf6',
          sc4: '#f59e0b',
          sc5: '#ef4444',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Consolas', 'monospace'],
      },
      boxShadow: {
        'soft': '0 2px 15px 0 rgba(0, 0, 0, 0.08)',
        'medium': '0 4px 20px 0 rgba(0, 0, 0, 0.12)',
        'large': '0 8px 30px 0 rgba(0, 0, 0, 0.16)',
      },
    },
  },
  plugins: [],
}
