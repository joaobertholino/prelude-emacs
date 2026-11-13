# Personal Prelude Emacs configuration

Personal configuration only. The Prelude framework is supplied separately by
[bbatsov/prelude](https://github.com/bbatsov/prelude) and is not included in the
current repository tree.

## Layout

- `config.el`: loads the personal modules.
- `early-init.el`: enables exact window sizing before the first frame is created.
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

The desktop window manager controls the Prelude window's size and centering.
Emacs accepts its exact pixel dimensions without rounding to character cells;
no fixed screen coordinates are stored in the Emacs configuration.

## Updating Prelude

Run `M-x prelude-update` to update the official framework and installed Emacs
packages in a separate background process. Progress and errors appear in
`*prelude-update*`; the editor and open buffers remain available. Use
`C-u M-x prelude-update` to update only the framework. Save your work and restart
Emacs when convenient after a successful update to load the new versions.

The framework follows `origin/master` from `bbatsov/prelude` and accepts only
fast-forward updates. Personal settings stay in this repository and are never
reset or pulled by this command. Local framework edits stop the update with an
explanation. The worker uses low CPU priority and disables bulk native package
compilation to keep the desktop responsive.

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

## New LaTeX projects

Choose **New LaTeX project** under **Getting started** on the welcome screen,
or run `M-x my/prelude-new-latex-project`. Select a destination directory;
new directories are created automatically. Next choose **Birkjour (personal)**,
**Mathematics article**, or **Choose a .tex file…**. Birkjour is the default.
The command creates `main.tex` from the selected template and opens it in AUCTeX.
Existing `main.tex` files are opened without being overwritten. The normal
LaTeX autosave, compilation and F6 viewer settings continue to apply.
Use TAB to select the welcome link and Enter to activate it.

The versioned templates are in `templates/latex/`. Customize
`birkjour/main.tex` or `article.tex` there. The Birkjour document comes from the
personal `snippets/LaTeX-mode/birkjour` snippet, with its snippet header removed
and its escaped address line break converted to ordinary LaTeX. Its class and
styles are byte-for-byte copies of the existing personal files in
`~/.config/texlive/texmf/tex/latex/birkjour/`: `birkjour.cls`, `cite.sty`, and
`spmpsci.bst`. The originals remain unchanged.

Birkjour projects include those three local files, so compilation works in any
destination directory without changing the global TeX search path. The old
`../References/references-all` dependency is replaced by commented instructions
for a project-local `references.bib`; no personal bibliography or article is
copied automatically. Existing destination class/style files are protected too:
if any would conflict, creation stops before writing files. Canceling template
selection creates nothing. Selecting a custom `.tex` copies only that file;
add any custom dependencies the document needs yourself.

## Python

`modules/python.el` configures Python 3 editing and execution. Pyright/Eglot
provides completion, diagnostics and navigation through Corfu; Copilot remains
available. Black is configured through Apheleia. Language-server discovery is
restored after Prelude imports the shell environment.

| Shortcut in a Python buffer | Action |
| --- | --- |
| F5 | Save and run the entire file in a fresh Python process |
| Shift+F5 | Interrupt the file launched with F5 |
| F6 / C-c C-z | Open the interactive Python console |
| F7 | Send the selected region, or current function, to the console |
| C-c C-c | Execute the whole buffer in the console, including its main block |
| F8 | Jump to the next traceback error |

F5 uses a separate output buffer for each file. Programs can read `input()`:
type a response in the output buffer and press Enter. Traceback locations are
clickable. Code runs only when requested, not automatically when opening or
saving a Python file. The console waits for interpreter initialization before
sending code.

The runner prefers `.venv/bin/python` or `venv/bin/python` in the project, then
the active `VIRTUAL_ENV`, then system `python3`. Run `python3 -m venv .venv` from a project terminal to create a virtual environment.
Files outside a project run from their own directory rather than the HOME
dotfiles repository root.

## Handwritten notes with Xournal++

`modules/xournalpp.el` enables `org-xournalpp-mode` in Org buffers. The vendored
GPL package is pinned to the revision recorded in `vendor/org-xournalpp/UPSTREAM`;
its `f` and `s` dependencies are installed through Prelude. Editing opens the native
Xournal++ application; the first page appears inline in graphical Emacs and updates
after saving. Additional notebook pages remain accessible in Xournal++.

| Shortcut in an Org buffer | Action |
| --- | --- |
| C-c x n | Choose a new .xopp path and an A4 ruled dark/light template, insert its link and open Xournal++ |
| C-c x i | Insert an existing .xopp notebook |
| C-c x r | Refresh previews |
| C-c x o / C-c C-o | Open the notebook linked at point |

Commands are also available through `M-x my/xournalpp-new`,
`my/xournalpp-insert` and `my/xournalpp-refresh`. Links use the form
`[[xournalpp:notes.xopp][Handwritten notes]]`. Save the Org file to retain the link
and save in Xournal++ to retain the handwriting. Existing notebooks are never
overwritten by the new-notebook command. The dark paper matches the current white
pen; select a dark pen when using light paper.

Local compatibility overrides export only the first page, limit preview rendering
to 15 seconds, preserve the Org cursor, handle atomic notebook saves and release
file watches when the buffer closes. Preview PNGs are hidden files beside the
notebook (`.notes.png`); keep the original `.xopp` file with the Org document.
Verification covers real notebook rendering, insertion, creation, overwrite
protection, failed exports and resource cleanup (`tests/xournalpp-tests.el`).
