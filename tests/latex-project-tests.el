;;; latex-project-tests.el --- New project regression tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'package)
(setq package-user-dir (expand-file-name "~/.config/prelude/elpa"))
(package-initialize)
(require 'tex-site)
(defvar prelude-welcome-screen)
(defconst personal-latex-test-root
  (expand-file-name ".." (file-name-directory (or load-file-name buffer-file-name))))
(load (expand-file-name "modules/latex.el" personal-latex-test-root)
      nil t)

(defmacro personal-latex-with-test-directory (&rest body)
  "Run BODY in a private directory, cleaning only its files and buffers."
  (declare (indent 0))
  `(let ((directory (make-temp-file "prelude-latex-project-test-" t)))
     (unwind-protect
         (cl-letf (((symbol-function 'my/prelude-latex-start) #'ignore))
           ,@body)
       (dolist (buffer (buffer-list))
         (with-current-buffer buffer
           (when (and buffer-file-name (file-in-directory-p buffer-file-name directory))
             (set-buffer-modified-p nil)
             (kill-buffer buffer))))
       (delete-directory directory t))))

(ert-deftest personal-latex-project-creates-new-directory-and-auctex-buffer ()
  (personal-latex-with-test-directory
    (let* ((target (expand-file-name "nested/new-project" directory))
           (main (expand-file-name "main.tex" target)))
      (my/prelude-new-latex-project target)
      (should (equal buffer-file-name main))
      (should (derived-mode-p 'LaTeX-mode))
      (should my/prelude-latex-auto-mode)
      (should (equal (buffer-string) my/prelude-latex-project-template))
      (should (equal (directory-files target nil "^[^.]") '("main.tex"))))))

(ert-deftest personal-latex-project-preserves-existing-file-and-unsaved-buffer ()
  (personal-latex-with-test-directory
    (let ((main (expand-file-name "main.tex" directory)))
      (with-temp-file main (insert "\\documentclass{article}\nExisting source\n"))
      (my/prelude-new-latex-project directory)
      (goto-char (point-max))
      (insert "Unsaved user edits\n")
      (let ((edited (buffer-string)))
        (my/prelude-new-latex-project directory)
        (should (equal (buffer-string) edited))
        (should (buffer-modified-p)))
      (should (equal (with-temp-buffer (insert-file-contents main) (buffer-string))
                     "\\documentclass{article}\nExisting source\n")))))

(ert-deftest personal-latex-welcome-button-runs-interactive-command ()
  (let ((prelude-welcome-screen nil)
        (core (expand-file-name "~/.config/prelude/core")))
    (add-to-list 'load-path core)
    (require 'prelude-welcome)
    (load (expand-file-name "modules/welcome.el" personal-latex-test-root)
          nil t)
    (personal-latex-with-test-directory
      (let ((target (expand-file-name "chosen-project" directory)))
        (cl-letf (((symbol-function 'read-directory-name) (lambda (&rest _) target)))
          (with-temp-buffer
            (prelude-welcome--insert-getting-started)
            (goto-char (point-min))
            (search-forward "[New LaTeX project]")
            (let ((button (button-at (1- (point)))))
              (should button)
              (button-activate button))))
        (should (file-exists-p (expand-file-name "main.tex" target)))))))

;;; latex-project-tests.el ends here
