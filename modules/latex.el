;;; latex.el --- LaTeX builds and shortcuts -*- lexical-binding: t; -*-
(require 'compile)
(require 'cl-lib)

(defconst my/prelude-latex-template-directory
  (expand-file-name "../templates/latex/"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "Directory containing personal LaTeX project templates.")

(defun my/prelude-select-latex-template ()
  "Choose a project template and return its file or scaffold directory."
  (let ((choice (completing-read
                 "LaTeX template: "
                 '("Birkjour (personal)" "Mathematics article" "Choose a .tex file…")
                 nil t nil nil "Birkjour (personal)")))
    (pcase choice
      ("Birkjour (personal)"
       (expand-file-name "birkjour/" my/prelude-latex-template-directory))
      ("Mathematics article"
       (expand-file-name "article.tex" my/prelude-latex-template-directory))
      (_ (let ((file (read-file-name "LaTeX template (.tex): " nil nil t)))
           (unless (equal (downcase (or (file-name-extension file) "")) "tex")
             (user-error "Choose a .tex template file"))
           file)))))

(defun my/prelude-latex-create-files (directory template)
  "Create project files in DIRECTORY from TEMPLATE without overwriting data.
TEMPLATE is a .tex file or the bundled Birkjour scaffold directory."
  (let* ((scaffold (file-directory-p template))
         (files (if scaffold '("birkjour.cls" "cite.sty" "spmpsci.bst" "main.tex")
                  '("main.tex")))
         (sources (mapcar (lambda (name)
                            (if scaffold (expand-file-name name template) template))
                          files)))
    ;; Validate every source and destination before creating anything.
    (dolist (source sources)
      (unless (file-regular-p source)
        (user-error "Template file is missing: %s" source)))
    (dolist (name files)
      (let ((target (expand-file-name name directory)))
        (when (or (file-exists-p target) (file-symlink-p target))
          (user-error "Project file already exists; nothing was overwritten: %s" target))))
    (make-directory directory t)
    (cl-mapc (lambda (source name)
               ;; copy-file refuses an existing destination, including races
               ;; after validation. Never clean up a user's files on failure.
               (copy-file source (expand-file-name name directory) nil))
             sources files)))

(defun my/prelude-new-latex-project (directory &optional template)
  "Create a LaTeX project in DIRECTORY and open its main.tex with AUCTeX.
Choose TEMPLATE interactively unless supplied, then create missing directories.
If main.tex already exists, open it unchanged without asking for a template."
  (interactive (list (read-directory-name "LaTeX project directory: " nil nil nil)))
  (require 'latex)
  (let* ((directory (file-name-as-directory (expand-file-name directory)))
         (main (expand-file-name "main.tex" directory))
         (existing (file-exists-p main)))
    (unless existing
      (my/prelude-latex-create-files
       directory (or template (my/prelude-select-latex-template))))
    (find-file main)
    (unless (derived-mode-p 'LaTeX-mode)
      (LaTeX-mode))
    (message (if existing "Opened existing LaTeX project: %s"
               "Created LaTeX project: %s") directory)))

(defvar my/prelude-latex-processes (make-hash-table :test #'equal))
(defvar my/prelude-latex-pending (make-hash-table :test #'equal))

(defun my/prelude-latex-master ()
  "Return the absolute master source, respecting AUCTeX project settings."
  (unless (and buffer-file-name (not (file-remote-p buffer-file-name)))
    (user-error "Save a local LaTeX file first"))
  (expand-file-name (TeX-master-file "tex")))

(defun my/prelude-latex-log-buffer (master)
  (get-buffer-create
   (format "*Prelude LaTeX: %s <%s>*" (file-name-nondirectory master)
           (substring (md5 master) 0 8))))

(defun my/prelude-latex-start (&optional force)
  "Build the master without opening the PDF.  Queue edits during a build."
  (interactive "P")
  (let* ((master (my/prelude-latex-master))
         (source (current-buffer))
         (running (gethash master my/prelude-latex-processes))
         (latexmk (executable-find "latexmk")))
    (unless latexmk (user-error "latexmk was not found; check the TeX Live path"))
    (unless (executable-find "lualatex") (user-error "lualatex was not found"))
    (unless (file-exists-p master) (user-error "Master file does not exist: %s" master))
    (if (and running (process-live-p running))
        (puthash master source my/prelude-latex-pending)
      (let* ((default-directory (file-name-directory master))
             (log (my/prelude-latex-log-buffer master))
             (display-buffer-overriding-action
              '(display-buffer-no-window (allow-no-window . t)))
             (command (mapconcat #'shell-quote-argument
                                 (append (list latexmk "-lualatex" "-view=none" "-synctex=1"
                                               "-file-line-error" "-interaction=nonstopmode")
                                         (when force '("-g")) (list master)) " "))
             (compilation (compilation-start command 'compilation-mode (lambda (_) (buffer-name log))))
             (process (get-buffer-process compilation)))
        (set-process-query-on-exit-flag process nil)
        (puthash master process my/prelude-latex-processes)
        (with-current-buffer compilation
          (add-hook 'compilation-finish-functions
                    (lambda (_buffer result)
                      (when (eq process (gethash master my/prelude-latex-processes))
                        (remhash master my/prelude-latex-processes))
                      (let ((pending (gethash master my/prelude-latex-pending)))
                        (remhash master my/prelude-latex-pending)
                        (if (buffer-live-p pending)
                            (with-current-buffer pending
                              (when my/prelude-latex-auto-mode (my/prelude-latex-start)))
                          (message "LaTeX %s: %s" (file-name-nondirectory master) (string-trim result)))))
                    nil t))))))

(defun my/prelude-latex-compile ()
  "Save this buffer and explicitly rebuild the master."
  (interactive)
  (let ((my/prelude-latex-auto-mode nil)) (save-buffer))
  (my/prelude-latex-start t))

(defun my/prelude-latex-stop ()
  "Disable automatic builds for this buffer and stop its current build."
  (interactive)
  (my/prelude-latex-auto-mode -1)
  (let* ((master (my/prelude-latex-master))
         (process (gethash master my/prelude-latex-processes)))
    (remhash master my/prelude-latex-pending)
    (when (and process (process-live-p process)) (interrupt-process process))
    (message "Automatic LaTeX compilation stopped")))

(defun my/prelude-latex-after-save ()
  (when my/prelude-latex-auto-mode (my/prelude-latex-start)))

(define-minor-mode my/prelude-latex-auto-mode
  "Build LaTeX automatically after saves, including idle autosaves."
  :lighter " AutoTeX"
  (if my/prelude-latex-auto-mode
      (add-hook 'after-save-hook #'my/prelude-latex-after-save t t)
    (remove-hook 'after-save-hook #'my/prelude-latex-after-save t)))

(defun my/prelude-latex-toggle ()
  "Toggle automatic compilation; enabling it also saves and builds now."
  (interactive)
  (if my/prelude-latex-auto-mode
      (my/prelude-latex-stop)
    (my/prelude-latex-auto-mode 1)
    (my/prelude-latex-compile)
    (message "Automatic LaTeX compilation enabled")))

(defun my/prelude-latex-on-open ()
  "Build existing LaTeX documents after local variables have been read."
  (when (and (derived-mode-p 'latex-mode 'LaTeX-mode)
             my/prelude-latex-auto-mode buffer-file-name
             (not (file-remote-p buffer-file-name)) (file-exists-p buffer-file-name))
    (my/prelude-latex-start)))

(defun my/prelude-latex-log ()
  (interactive)
  (pop-to-buffer (my/prelude-latex-log-buffer (my/prelude-latex-master))))

(defun my/prelude-latex-next-error ()
  (interactive)
  (let ((next-error-last-buffer (my/prelude-latex-log-buffer (my/prelude-latex-master))))
    (next-error)))

(define-prefix-command 'my/prelude-latex-map)
(dolist (entry '(("c" . my/prelude-latex-compile) ("a" . my/prelude-latex-toggle)
                 ("k" . my/prelude-latex-stop) ("v" . TeX-view)
                 ("l" . my/prelude-latex-log) ("e" . my/prelude-latex-next-error)
                 ("b" . citar-insert-citation)))
  (define-key my/prelude-latex-map (kbd (car entry)) (cdr entry)))

(defun my/prelude-latex-setup ()
  (setq-local TeX-command-default "LatexMk")
  (my/prelude-latex-auto-mode 1)
  (TeX-source-correlate-mode 1)
  (local-set-key (kbd "<f5>") #'my/prelude-latex-toggle)
  (local-set-key (kbd "C-<f5>") #'my/prelude-latex-compile)
  (local-set-key (kbd "S-<f5>") #'my/prelude-latex-stop)
  (local-set-key (kbd "<f6>") #'TeX-view)
  (local-set-key (kbd "<f7>") #'my/prelude-latex-log)
  (local-set-key (kbd "<f8>") #'my/prelude-latex-next-error)
  (local-set-key (kbd "C-c l") my/prelude-latex-map)
  (local-set-key (kbd "C-c b") #'citar-insert-citation))

(with-eval-after-load 'latex
  (setq-default TeX-engine 'luatex TeX-master t)
  (setq TeX-source-correlate-start-server nil
        TeX-save-query nil TeX-parse-self t TeX-auto-save t
        TeX-view-program-selection '((output-pdf "Zathura"))
        LaTeX-indent-level 1 LaTeX-item-indent 1 TeX-brace-indent-level 2)
  ;; The installed Zathura has no SyncTeX support and exits on sync options.
  (add-to-list 'TeX-view-program-list '("Zathura" "zathura %o" "zathura"))
  (add-to-list 'TeX-command-list
               '("LatexMk" "latexmk -lualatex -view=none -synctex=1 -file-line-error -interaction=nonstopmode %t" TeX-run-TeX nil t))
  (add-hook 'LaTeX-mode-hook #'my/prelude-latex-setup)
  (add-hook 'LaTeX-mode-hook #'cdlatex-mode))
(add-hook 'find-file-hook #'my/prelude-latex-on-open t)

(defun my/prelude-latex-shutdown ()
  (clrhash my/prelude-latex-pending)
  (maphash (lambda (_ process)
             (when (process-live-p process) (delete-process process)))
           my/prelude-latex-processes))
(add-hook 'kill-emacs-hook #'my/prelude-latex-shutdown)
