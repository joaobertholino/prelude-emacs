# Personal Prelude Emacs configuration

Personal configuration only. The Prelude framework is supplied separately by
[bbatsov/prelude](https://github.com/bbatsov/prelude) and is not included in the
current repository tree.

## Layout

- `config.el`: loads the personal modules.
- `prelude-modules.el`: selects the enabled Prelude modules.
- `preload/00-isolation.el`: early preferences and environment.
- `modules/`: appearance, editing, LaTeX, Org, Copilot, Prettier and live server.
- `snippets/LaTeX-mode/`: personal LaTeX snippets.
- `custom.el`: preferences saved by Emacs Customize.

## Local integration

The configuration checkout is `~/.config/prelude-personal`, tracked as a
submodule of the dotfiles. `~/.config/prelude/personal` is a symbolic link to
this checkout. The framework and its packages remain in `~/.config/prelude`.
The `emacs-prelude` launcher and the `emacs.service` daemon keep using that
framework directory and the `prelude` server socket.

On a fresh system, install the official Prelude framework, initialize this
submodule, and link its directory as the framework's `personal` directory.
Keep a populated existing personal directory before replacing it with a link.

The desktop's hourly Git service commits and pushes this configuration and
then updates the parent dotfiles pointer. Bytecode and temporary files are
excluded. Do not store credentials or access tokens in configuration files.

The repository history starts with the personal configuration only; the
framework has its own separate upstream history.

## External dependencies

The configured languages are Python, JavaScript/TypeScript/TSX, HTML, CSS,
JSON, YAML, shell, Emacs Lisp, Markdown and LaTeX. Corfu uses the completion
provided by Eglot or AUCTeX; Copilot remains available independently.

- Native Gentoo packages: `app-text/pandoc-bin`, `dev-util/shellcheck-bin`,
  `dev-python/black`, `dev-python/isort`, `dev-python/flake8`, and
  `sys-apps/the_silver_searcher`.
- `shfmt` is supplied by the native Gentoo package `dev-util/sh`.
- TeX Live supplies latexmk, LuaLaTeX, Biber, ChkTeX and latexindent. The
  installed Zathura is used by F6; compilation does not launch the viewer.
- The Node language servers are pinned in `tools/package.json` and its lockfile.
  Reinstall them with `tools/install-node-tools.sh`. TypeScript 6 is required by
  this language-server release; TypeScript 7 uses a different native server.
  The pinned Zod/minimatch overrides address audited transitive dependencies.
- Eglot 1.26, yaml-mode and typescript-mode are installed through GNU ELPA/MELPA,
  alongside the packages selected in `custom.el`.

Run `M-x my/prelude-check-tools` to check executable discovery. Projects can
still use their own Prettier configuration and local formatter version.
The HTML server uses the single project root instead of requesting unsupported
dynamic workspace-folder registration from Eglot.

`~/Documents/refs.bib`, `~/Documents/papers/`, and `~/Documents/notes/` are the
Citar locations. Org capture and the agenda use `~/Org-Notes/task.org` and
`~/Org-Notes/project.org`. These personal documents are not part of this repo.

Existing Emacs sessions should be restarted after saving work to load updated
ELPA packages. Tree-sitter is optional; this Emacs build uses the regular major
modes, which support the configured completion, diagnostics and formatting.
