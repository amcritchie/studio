// Shared Tailwind config for all Studio apps
// Apps spread from this in their own tailwind.config.js

module.exports = {
  darkMode: 'class',
  theme: {
    fontFamily: {
      sans: ['Montserrat', 'system-ui', 'sans-serif'],
      mono: ['ui-monospace', 'SFMono-Regular', 'monospace'],
    },
    extend: {
      colors: {
        // Theme-aware semantic tokens (reference CSS variables)
        page:          'var(--color-page)',
        surface:       'var(--color-surface)',
        'surface-alt': 'var(--color-surface-alt)',
        inset:         'var(--color-inset)',

        mint: {
          DEFAULT: '#06D6A0',
          50: '#e6faf4',
          100: '#b3f0de',
          200: '#80e6c8',
          300: '#4ddcb2',
          400: '#1ad29c',
          500: '#06D6A0',
          600: '#05b888',
          700: '#049a70',
          800: '#037c58',
          900: '#025e40',
        },
        navy: {
          DEFAULT: '#1A1535',
          50: '#e8e7ed',
          100: '#b8b5c8',
          200: '#8883a3',
          300: '#58517e',
          400: '#3a3359',
          500: '#1A1535',
          600: '#16122e',
          700: '#120f27',
          800: '#0e0c20',
          900: '#0a0919',
        },
        violet: {
          DEFAULT: '#8E82FE',
          50: '#f0eeff',
          100: '#EAE8FF',
          200: '#b2aafe',
          300: '#C5C0FE',
          400: '#8E82FE',
          500: '#8E82FE',
          600: '#6558e5',
          700: '#6558E0',
          800: '#3b2cb3',
          900: '#3D2FB5',
        },
        mist: '#F7F6FF',
        lavender: '#E8E6F0',
        slate: '#6B6580',
        charcoal: '#2D2648',
        midnight: '#120F28',
        ember: '#FF8C69',
        gold: '#FFD166',
        magenta: '#F72585',
      },
      textColor: {
        heading:   'var(--color-text)',
        body:      'var(--color-text-body)',
        secondary: 'var(--color-text-secondary)',
        muted:     'var(--color-text-muted)',
      },
      borderColor: {
        subtle: 'var(--color-border)',
        strong: 'var(--color-border-strong)',
      },
    },
  },
}
