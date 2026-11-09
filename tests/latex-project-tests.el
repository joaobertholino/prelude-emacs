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
         (cl-letf (((symbol-function 'my/prelude-latex-start) #'ignore)
                   ((symbol-function 'completing-read)
                    (lambda (&rest _) "Mathematics article")))
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
      (should (equal (buffer-string)
                     (with-temp-buffer
                       (insert-file-contents
                        (expand-file-name "article.tex" my/prelude-latex-template-directory))
                       (buffer-string))))
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

(ert-deftest personal-latex-project-uses-personal-birkjour-and-local-assets ()
  (personal-latex-with-test-directory
    (let ((target (expand-file-name "project with spaces" directory)))
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (&rest _) "Birkjour (personal)")))
        (my/prelude-new-latex-project target))
      (should (string-match-p "\\\\documentclass{birkjour}" (buffer-string)))
      (should-not (string-match-p "# --\\|\.\./References" (buffer-string)))
      (dolist (name '("birkjour.cls" "cite.sty" "spmpsci.bst"))
        (should (file-exists-p (expand-file-name name target)))))))

(ert-deftest personal-latex-project-chooses-custom-file-with-spaces ()
  (personal-latex-with-test-directory
    (let* ((source (expand-file-name "my own template.tex" directory))
           (target (expand-file-name "new destination" directory))
           (body "\\documentclass{article}\n\\begin{document}Custom\\end{document}\n"))
      (with-temp-file source (insert body))
      (cl-letf (((symbol-function 'completing-read) (lambda (&rest _) "Choose a .tex file…"))
                ((symbol-function 'read-file-name) (lambda (&rest _) source)))
        (my/prelude-new-latex-project target))
      (should (equal (buffer-string) body))
      (should (equal (directory-files target nil "^[^.]") '("main.tex"))))))

(ert-deftest personal-latex-project-protects-existing-class-before-copying ()
  (personal-latex-with-test-directory
    (let ((protected (expand-file-name "birkjour.cls" directory)))
      (with-temp-file protected (insert "User's custom class"))
      (should-error
       (my/prelude-new-latex-project
        directory (expand-file-name "birkjour/" my/prelude-latex-template-directory)))
      (should (equal (directory-files directory nil "^[^.]") '("birkjour.cls")))
      (should (equal (with-temp-buffer (insert-file-contents protected) (buffer-string))
                     "User's custom class")))))

(ert-deftest personal-latex-project-cancellation-creates-no-directory ()
  (personal-latex-with-test-directory
    (let ((target (expand-file-name "cancelled project" directory)))
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (&rest _) (signal 'quit nil))))
        (should (eq (condition-case nil
                        (my/prelude-new-latex-project target)
                      (quit 'cancelled))
                    'cancelled)))
      (should-not (file-exists-p target)))))

;;; latex-project-tests.el ends here
