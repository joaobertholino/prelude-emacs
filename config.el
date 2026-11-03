;;; config.el -*- lexical-binding: t; -*-
(dolist (module '("appearance" "tooling" "editing" "latex" "org" "copilot" "prettier" "www-live"))
  (load (expand-file-name (concat "modules/" module ".el") prelude-personal-dir) nil t))
