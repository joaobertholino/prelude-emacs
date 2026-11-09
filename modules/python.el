;;; python.el --- Python editing and execution -*- lexical-binding: t; -*-
(require 'python)
(require 'compile)
(require 'project)
(require 'cl-lib)

(let ((bin (expand-file-name "~/.local/share/prelude-tools/node_modules/.bin")))
  (when (file-directory-p bin)
    (add-to-list 'exec-path bin t)
    (unless (member bin (split-string (or (getenv "PATH") "") path-separator t))
      (setenv "PATH" (concat (getenv "PATH") path-separator bin)))))

(defun my/prelude-python-root ()
  "Return the Python project directory, excluding the HOME dotfiles project."
  (or (locate-dominating-file default-directory ".venv")
      (locate-dominating-file default-directory "venv")
      (when-let* ((project (project-current nil))
                  (root (project-root project)))
        (unless (file-equal-p root (expand-file-name "~")) root))
      default-directory))

(defun my/prelude-python-interpreter ()
  "Prefer the project's virtual environment, then the active one, then Python 3."
  (or (cl-loop for directory in '(".venv" "venv")
               for python = (expand-file-name (concat directory "/bin/python")
                                               (my/prelude-python-root))
               when (file-executable-p python) return python)
      (when-let* ((venv (getenv "VIRTUAL_ENV"))
                  (python (expand-file-name "bin/python" venv)))
        (when (file-executable-p python) python))
      (executable-find "python3")
      (user-error "Python 3 was not found")))

(defun my/prelude-python-run-buffer-name (&optional _mode)
  "Use a separate run buffer for each Python file."
  (format "*Python run: %s*" (abbreviate-file-name (or buffer-file-name (buffer-name)))))

(defun my/prelude-python-run ()
  "Save and run this file with interactive input and clickable tracebacks."
  (interactive)
  (unless (and buffer-file-name (not (file-remote-p buffer-file-name)))
    (user-error "Save this Python buffer as a local .py file first"))
  (save-buffer)
  (let* ((python (my/prelude-python-interpreter))
         (name (my/prelude-python-run-buffer-name))
         (default-directory (my/prelude-python-root))
         (command (mapconcat #'shell-quote-argument
                             (list python "-u" (expand-file-name buffer-file-name)) " ")))
    (compilation-start command t (lambda (_mode) name))))

(defun my/prelude-python-console ()
  "Start or display the Python console for this buffer."
  (interactive)
  (setq-local python-shell-interpreter (my/prelude-python-interpreter))
  (run-python (python-shell-calculate-command) nil t)
  (let ((process (python-shell-get-process))
        (deadline (+ (float-time) 5)))
    (while (and (process-live-p process)
                (< (float-time) deadline)
                (not (buffer-local-value 'python-shell--first-prompt-received
                                         (process-buffer process))))
      (accept-process-output process 0.05))
    (unless (and (process-live-p process)
                 (buffer-local-value 'python-shell--first-prompt-received
                                     (process-buffer process)))
      (user-error "Python console did not become ready")))
  (when (called-interactively-p 'interactive)
    (python-shell-switch-to-shell)))

(defun my/prelude-python-send-buffer ()
  "Execute the entire buffer in the console, including its main block."
  (interactive)
  (my/prelude-python-console)
  (python-shell-send-buffer t))

(defun my/prelude-python-send-region-or-defun ()
  "Execute the selection, or the current function, in the Python console."
  (interactive)
  (my/prelude-python-console)
  (if (use-region-p)
      (python-shell-send-region (region-beginning) (region-end) t)
    (python-shell-send-defun nil)))

(defun my/prelude-python-stop ()
  "Interrupt the file started with F5."
  (interactive)
  (if-let* ((process (get-buffer-process (my/prelude-python-run-buffer-name))))
      (interrupt-process process)
    (message "No Python file is running")))

(defun my/prelude-python-setup ()
  "Configure Python completion, indentation and execution keys."
  (setq-local python-indent-offset 4
              indent-tabs-mode nil
              python-shell-interpreter (my/prelude-python-interpreter)
              python-shell-process-environment
              (cons "PYTHON_BASIC_REPL=1" python-shell-process-environment))
  (local-set-key (kbd "<f5>") #'my/prelude-python-run)
  (local-set-key (kbd "S-<f5>") #'my/prelude-python-stop)
  (local-set-key (kbd "<f6>") #'my/prelude-python-console)
  (local-set-key (kbd "<f7>") #'my/prelude-python-send-region-or-defun)
  (local-set-key (kbd "<f8>") #'next-error)
  (local-set-key (kbd "C-c C-c") #'my/prelude-python-send-buffer)
  (local-set-key (kbd "C-c C-z") #'my/prelude-python-console))

(add-hook 'python-mode-hook #'my/prelude-python-setup)
(add-hook 'python-ts-mode-hook #'my/prelude-python-setup)
