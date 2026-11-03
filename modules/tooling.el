;;; tooling.el --- Language tools for enabled Prelude modules -*- lexical-binding: t; -*-
(use-package yaml-mode :ensure t :mode "\\.ya?ml\\'")
(use-package typescript-mode :ensure t :mode "\\.ts\\'")

(define-derived-mode my/prelude-tsx-mode web-mode "TSX"
  "Edit TSX with web-mode and TypeScript language intelligence.")
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . my/prelude-tsx-mode))

(with-eval-after-load 'eglot
  (setq eglot-server-programs
        (append
         '(((my/prelude-tsx-mode :language-id "typescriptreact") . ("typescript-language-server" "--stdio"))
           ((web-mode :language-id "html") . ("vscode-html-language-server" "--stdio"))
           (((python-mode :language-id "python") (python-ts-mode :language-id "python")) . ("pyright-langserver" "--stdio"))
           (((js-mode :language-id "javascript") (js-ts-mode :language-id "javascript")
             (typescript-mode :language-id "typescript") (typescript-ts-mode :language-id "typescript")
             (tsx-ts-mode :language-id "typescriptreact")) . ("typescript-language-server" "--stdio"))
           (((css-mode :language-id "css") (css-ts-mode :language-id "css")
             (scss-mode :language-id "scss")) . ("vscode-css-language-server" "--stdio"))
           (((json-mode :language-id "json") (json-ts-mode :language-id "json")
             (js-json-mode :language-id "json")) . ("vscode-json-language-server" "--stdio"))
           ((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio"))
           (((sh-mode :language-id "shellscript") (bash-ts-mode :language-id "shellscript")) . ("bash-language-server" "start")))
         eglot-server-programs)))

(defun my/prelude-language-tools ()
  "Start local completion and diagnostics for supported local files."
  (when (and buffer-file-name (not (file-remote-p buffer-file-name)))
    (require 'eglot)
    (eglot-ensure)))
(dolist (hook '(typescript-mode-hook web-mode-hook css-mode-hook scss-mode-hook
                js-json-mode-hook json-mode-hook yaml-mode-hook sh-mode-hook))
  (add-hook hook #'my/prelude-language-tools))

(with-eval-after-load 'apheleia
  (setf (alist-get 'python-mode apheleia-mode-alist) 'black
        (alist-get 'python-ts-mode apheleia-mode-alist) 'black
        (alist-get 'sh-mode apheleia-mode-alist) 'shfmt
        (alist-get 'bash-ts-mode apheleia-mode-alist) 'shfmt))
