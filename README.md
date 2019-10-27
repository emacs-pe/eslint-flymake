# Flymake ESLint

# Usage

## Installation

```emacs-lisp
(use-package eslint-flymake)
```

## Customization options


### eslint-flymake-command

You can configure how to call ESLint by setting
`eslint-flymake-command`. For example if you don't to call it using
[npx] you can do so by executing `(setq eslint-flymake-command ("npx"
"eslint" "--no-color" "--stdin"))`.


# Alternatives

- [compile-eslint.el]: Enables compilation-mode to work understand the
  error ESLint error format. Ideal when running ESLint against the
  whole project.

# License

GPLv3+

# Author

Javier Olaechea <pirata@gmail.com>


[compile-eslint.el]: https://github.com/Fuco1/compile-eslint
[npx]: https://github.com/npm/npx
