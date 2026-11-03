;;; 00-isolation.el -*- lexical-binding: t; -*-
(setq user-full-name "João Bertholino"
      user-mail-address "comercial.bertholino@gmail.com"
      server-name "prelude"
      frame-title-format '("Prelude (test) — %b")
      prelude-theme 'modus-vivendi
      prelude-super-keybindings nil
      prelude-whitespace nil
      prelude-flyspell nil)
(dolist (bin '("~/.local/bin" "~/.local/share/texlive/2026/bin/x86_64-linux"))
  (let ((path (expand-file-name bin)))
    (when (file-directory-p path)
      (add-to-list 'exec-path path)
      (unless (member path (split-string (or (getenv "PATH") "") path-separator t))
        (setenv "PATH" (concat path path-separator (getenv "PATH")))))))

(let ((bin (expand-file-name "~/.local/share/prelude-tools/node_modules/.bin")))
  (when (file-directory-p bin)
    (add-to-list 'exec-path bin t)
    (unless (member bin (split-string (or (getenv "PATH") "") path-separator t))
      (setenv "PATH" (concat (getenv "PATH") path-separator bin)))))
