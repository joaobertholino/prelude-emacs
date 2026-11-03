;;; copilot.el -*- lexical-binding: t; -*-
(use-package copilot
  :ensure t
  :hook ((prog-mode . copilot-mode) (LaTeX-mode . copilot-mode))
  :init
  (setq copilot-node-executable "/usr/bin/node"
        copilot-install-dir (expand-file-name "~/.local/share/vim-copilot")
        copilot-server-executable (expand-file-name "~/.local/share/vim-copilot/node_modules/.bin/copilot-language-server")
        copilot-indent-offset-warning-disable t)
  :bind (:map copilot-completion-map
              ("TAB" . copilot-accept-completion)
              ("<tab>" . copilot-accept-completion)
              ("C-<tab>" . copilot-accept-completion-by-word)))
