module.exports = {
  root: true,
  env: {
    node: true,
  },
  extends: [
    'plugin:vue/essential',
    '@vue/typescript',
  ],
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'eol-last': 0,
    'indent': 0,
    'comma-dangle': 0,
    'max-len': 0,
    'class-methods-use-this': 0,
    'no-else-return': 0,
    'padded-blocks': 0,
    'no-unreachable': 0
  },
  parserOptions: {
    parser: '@typescript-eslint/parser',
  },
};
