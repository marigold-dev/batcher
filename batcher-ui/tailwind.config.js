/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./pages/**/*.{js,ts,jsx,tsx}', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        dark: '#1C1D22',
        primary: '#D8464E',
        darkgray: '#2B2A2E',
        lightgray: '#7B7B7E',
        hovergray: '#d1d5db',
        green: '#6FE17A',
      },
    },
    fontFamily: {
      custom: ['Roboto Mono'],
    },
    keyframes: {
      rotate: {
        from: { transform: 'rotate(0deg)' },
        to: { transform: 'rotate(180deg)' },
      },
    },
    animation: {
      rotate: 'rotate 750ms ease',
    },
  },
  plugins: [],
};
