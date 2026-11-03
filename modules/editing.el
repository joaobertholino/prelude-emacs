;;; editing.el -*- lexical-binding: t; -*-
(setq auto-save-visited-interval 0.5)
(auto-save-visited-mode +1)
(global-set-key (kbd "M-<left>") #'windmove-left)
(global-set-key (kbd "M-<right>") #'windmove-right)
(global-set-key (kbd "M-<up>") #'windmove-up)
(global-set-key (kbd "M-<down>") #'windmove-down)
(use-package yasnippet
  :ensure t
  :config
  (add-to-list 'yas-snippet-dirs (expand-file-name "snippets" prelude-personal-dir))
  (yas-global-mode 1))
(use-package citar
  :ensure t
  :commands (citar-insert-citation citar-open)
  :custom
  (citar-bibliography '("~/Documents/refs.bib"))
  (citar-library-paths '("~/Documents/papers/"))
  (citar-notes-paths '("~/Documents/notes/")))
(use-package markdown-mode :ensure t :mode "\\.md\\'"
  :custom (markdown-command "pandoc"))

;; Standard clipboard keys: C-c copy, C-x cut, C-v paste, C-z undo.
(cua-mode 1)

;; Export active selections and copy mouse-drag selections automatically.
(setq select-enable-primary t
      select-enable-clipboard t
      select-active-regions t
      mouse-drag-copy-region t)
