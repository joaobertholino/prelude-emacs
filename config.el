;;; config.el -*- lexical-binding: t; -*-
(dolist (module '("appearance" "tooling" "python" "editing" "latex" "org" "xournalpp" "copilot" "prettier" "www-live" "update" "welcome"))
  (load (expand-file-name (concat "modules/" module ".el") prelude-personal-dir) nil t))
