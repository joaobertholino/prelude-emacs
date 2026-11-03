;;; prettier.el -*- lexical-binding: t; -*-

(let ((bin (expand-file-name "~/.local/bin")))
  (add-to-list 'exec-path bin)
  (unless (member bin (split-string (or (getenv "PATH") "") path-separator t))
    (setenv "PATH" (concat bin path-separator (getenv "PATH")))))

(with-eval-after-load 'prelude-mode
  (define-key prelude-mode-map (kbd "C-c f") nil))

(with-eval-after-load 'apheleia
  (setf (alist-get 'my-prettier apheleia-formatters)
        '("apheleia-npx" "prettier" "--stdin-filepath" filepath)))

(defun my/prettier-enable ()
  "Use Prettier for supported local files, preserving project configuration."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name))
             (let ((case-fold-search t))
               (string-match-p
                "\\.\\(?:html?\\|css\\|scss\\|less\\|[cm]?jsx?\\|[cm]?tsx?\\|json[5c]?\\|ya?ml\\|mdx?\\|graphql\\|gql\\)\\'"
                buffer-file-name)))
    (require 'apheleia)
    (setq-local apheleia-formatter 'my-prettier)
    (apheleia-mode +1)
    (local-set-key (kbd "C-c f") #'apheleia-format-buffer)))

(add-hook 'after-change-major-mode-hook #'my/prettier-enable t)
(add-hook 'lsp-managed-mode-hook #'my/prettier-enable t)
(add-hook 'eglot-managed-mode-hook #'my/prettier-enable t)

(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (my/prettier-enable)))
