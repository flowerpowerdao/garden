/* import tailwind default theme */
const defaultTheme = require("tailwindcss/defaultTheme");
const typography = require("@tailwindcss/typography");

const config = {
  darkMode: "class",
  mode: "jit",
  content: [
    "index.html",
    "./src/**/*.{html,js,svelte,ts}",
    "./node_modules/fpdao-ui/**/*",
  ],
  theme: {
    extend: {
      boxShadow: {
        DEFAULT: "3px 3px 0px",
      },
      fontFamily: {
        sans: ["TWK Everett", ...defaultTheme.fontFamily.sans],
        mono: ["Space Mono", ...defaultTheme.fontFamily.mono],
        "everett-medium": [
          "TWK Everett Medium",
          ...defaultTheme.fontFamily.sans,
        ],
      },
      typography: ({ theme }) => ({
        black: {
          css: {
            "--tw-prose-body": theme("colors.black"),
            "--tw-prose-headings": theme("colors.black"),
            "--tw-prose-lead": theme("colors.black"),
            "--tw-prose-links": theme("colors.black"),
            "--tw-prose-bold": theme("colors.black"),
            "--tw-prose-counters": theme("colors.black"),
            "--tw-prose-bullets": theme("colors.black"),
            "--tw-prose-hr": theme("colors.black"),
            "--tw-prose-quotes": theme("colors.black"),
            "--tw-prose-quote-borders": theme("colors.black"),
            "--tw-prose-captions": theme("colors.black"),
            "--tw-prose-code": theme("colors.black"),
            "--tw-prose-pre-code": theme("colors.white"),
            "--tw-prose-pre-bg": theme("colors.black"),
            "--tw-prose-th-borders": theme("colors.black"),
            "--tw-prose-td-borders": theme("colors.black"),
            "--tw-prose-invert-body": theme("colors.white"),
            "--tw-prose-invert-headings": theme("colors.white"),
            "--tw-prose-invert-lead": theme("colors.white"),
            "--tw-prose-invert-links": theme("colors.white"),
            "--tw-prose-invert-bold": theme("colors.white"),
            "--tw-prose-invert-counters": theme("colors.white"),
            "--tw-prose-invert-bullets": theme("colors.white"),
            "--tw-prose-invert-hr": theme("colors.white"),
            "--tw-prose-invert-quotes": theme("colors.white"),
            "--tw-prose-invert-quote-borders": theme("colors.white"),
            "--tw-prose-invert-captions": theme("colors.white"),
            "--tw-prose-invert-code": theme("colors.white"),
            "--tw-prose-invert-pre-code": theme("colors.black"),
            "--tw-prose-invert-pre-bg": theme("colors.white"),
            "--tw-prose-invert-th-borders": theme("colors.white"),
            "--tw-prose-invert-td-borders": theme("colors.white"),
          },
        },
      }),
    },
  },
  plugins: [typography],
};

module.exports = config;
