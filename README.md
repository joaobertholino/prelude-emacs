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
