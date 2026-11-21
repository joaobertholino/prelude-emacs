;;; lean.el --- Lean 4 proofs, goals and Lake projects -*- lexical-binding: t; -*-
(require 'cl-lib)
(require 'compile)
(require 'package)

;; Keep the system installation; Elan selects the version in lean-toolchain.
(let ((bin (expand-file-name "~/.elan/bin")))
  (when (file-directory-p bin)
    (add-to-list 'exec-path bin)
    (unless (equal bin (car (split-string (or (getenv "PATH") "") path-separator t)))
      (setenv "PATH" (concat bin path-separator (getenv "PATH"))))))

(prelude-require-packages '(dash magit-section lsp-mode))
(unless (package-installed-p 'lean4-mode)
  (require 'package-vc)
  (package-vc-install
   '(lean4-mode :url "https://github.com/leanprover-community/lean4-mode.git")))
(dolist (package '(lsp-mode lean4-mode))
  (add-to-list 'package-selected-packages package))

(defun my/prelude-lean-root ()
  "Use the Lean project root, never the enclosing HOME dotfiles repository."
  (or (locate-dominating-file default-directory "lakefile.toml")
      (locate-dominating-file default-directory "lakefile.lean")
      (locate-dominating-file default-directory "lean-toolchain")
      default-directory))

(defun my/prelude-lean-check ()
  "Save and check the current Lean file, respecting Lake and Elan."
  (interactive)
  (unless buffer-file-name (user-error "Save this buffer as a .lean file first"))
  (save-buffer)
  (lean4-std-exe))

(defun my/prelude-lean-build ()
  "Save this file and build the Lake project."
  (interactive)
  (when buffer-file-name (save-buffer))
  (lean4-lake-build))

(defun my/prelude-lean-cache ()
  "Download precompiled Mathlib dependencies for the current Lake project."
  (interactive)
  (let ((default-directory (lean4-lake-find-dir-safe)))
    (compilation-start
     (concat (shell-quote-argument (lean4-get-executable "lake")) " exe cache get")
     'compilation-mode (lambda (_) "*Lean Mathlib cache*"))))

(defun my/prelude-new-lean-project (directory name template)
  "Create a Lake project named NAME inside DIRECTORY, using TEMPLATE."
  (interactive
   (list (read-directory-name "Parent directory: " "~/Mathematics/" nil t)
         (read-string "Project name (e.g. MyProofs): ")
         (completing-read "Template: " '("lib" "std" "math-lax" "math") nil t nil nil "lib")))
  (unless (string-match-p "\\`[A-Za-z][A-Za-z0-9_]*\\'" name)
    (user-error "Use a name starting with a letter, followed by letters, digits or underscores"))
  (unless (member template '("lib" "std" "math-lax" "math"))
    (user-error "Unknown Lake template"))
  (let* ((default-directory (file-name-as-directory (expand-file-name directory)))
         (target (expand-file-name name default-directory)))
    (when (file-exists-p target) (user-error "Directory already exists: %s" target))
    (unless (executable-find "lake") (user-error "Lake is unavailable"))
    (compilation-start
     (mapconcat #'shell-quote-argument (list (executable-find "lake") "new" name template) " ")
     'compilation-mode (lambda (_) "*Lean new project*"))
    (message "Creating %s; open its .lean files after the command finishes" target)))

(defun my/prelude-lean-refresh-inlay-hints (workspace _params)
  "Handle Lean's standard refresh request for visible inlay hints."
  (dolist (buffer (lsp--workspace-buffers workspace))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (when (bound-and-true-p lsp-inlay-hints-mode)
          (when-let* ((window (get-buffer-window buffer t)))
            (with-selected-window window
              (lsp-update-inlay-hints (window-start window) (window-end window t))))))))
  nil)

(defun my/prelude-lean-show-goals ()
  "Open the native Lean goals view once the language server is ready."
  (when (and (derived-mode-p 'lean4-mode) (bound-and-true-p lsp-managed-mode))
    (lean4-ensure-info-buffer lean4-info-buffer-name)
    (unless (get-buffer-window lean4-info-buffer-name t)
      (display-buffer lean4-info-buffer-name))
    (lean4-info-buffer-refresh)))

(defun my/prelude-lean-setup ()
  "Use Lean's own language client, Corfu completion and live diagnostics."
  (setq-local lsp-completion-provider :capf
              lsp-diagnostics-provider :flycheck
              lsp-enable-on-type-formatting nil
              lsp-enable-file-watchers nil
              lsp-headerline-breadcrumb-enable nil
              lsp-idle-delay 0.3
              lsp-enable-snippet t
              lsp-inlay-hint-enable t
              indent-tabs-mode nil
              tab-width 2)
  (lsp-workspace-folders-add (my/prelude-lean-root))
  (corfu-mode 1)
  (add-hook 'lsp-managed-mode-hook #'my/prelude-lean-show-goals nil t)
  ;; CUA/Evil remain enabled; these bindings belong only to Lean buffers.
  (dolist (binding '(("C-c C-c" . my/prelude-lean-check)
                     ("C-c C-b" . my/prelude-lean-build)
                     ("C-c C-i" . lean4-toggle-info)
                     ("C-c C-r" . lsp-workspace-restart)
                     ("C-c C-a" . lsp-execute-code-action)
                     ("C-c C-h" . lsp-describe-thing-at-point)
                     ("C-c C-e" . flycheck-list-errors)
                     ("C-c C-t" . lsp-inlay-hints-mode)
                     ("C-c C-n" . flycheck-next-error)
                     ("C-c C-p C-n" . my/prelude-new-lean-project)
                     ("C-c C-p C-c" . my/prelude-lean-cache)
                     ("<f5>" . my/prelude-lean-check)
                     ("<f6>" . lean4-toggle-info)))
    (local-set-key (kbd (car binding)) (cdr binding))))

(use-package lean4-mode
  :ensure nil
  :mode ("\\.lean\\'" . lean4-mode)
  :commands (lean4-mode lean4-show-version)
  :config
  ;; Configure the buffer before starting Lean's dedicated LSP client.
  (add-hook 'lean4-mode-hook #'my/prelude-lean-setup)
  (add-hook 'lean4-mode-hook #'lsp t)
  ;; lsp-mode 20261109 advertises no refresh support, but Lean still requests it.
  ;; Install a real handler only when the client does not already provide one.
  (let ((handlers (lsp--client-request-handlers (gethash 'lean4-lsp lsp-clients))))
    (unless (gethash "workspace/inlayHint/refresh" handlers)
      (puthash "workspace/inlayHint/refresh"
               #'my/prelude-lean-refresh-inlay-hints handlers)))
  (add-to-list 'display-buffer-alist
               '("\\`\\*Lean Goal\\*\\'"
                 (display-buffer-reuse-window display-buffer-in-direction)
                 (direction . right)
                 (window-width . 0.36)
                 (window-min-width . 28))))

(provide 'my-prelude-lean)
;;; lean.el ends here
