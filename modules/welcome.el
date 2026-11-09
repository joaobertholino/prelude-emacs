;;; welcome.el --- Personal Prelude welcome links -*- lexical-binding: t; -*-

(defun my/prelude-welcome-latex-project ()
  "Add a keyboard-accessible project creation link to Getting started."
  (insert "  ")
  (prelude-welcome--button
   "[New LaTeX project]" "Choose a directory and create or open main.tex"
   (lambda () (call-interactively #'my/prelude-new-latex-project)))
  (insert "\n"))

(with-eval-after-load 'prelude-welcome
  (advice-add 'prelude-welcome--insert-getting-started :after
              #'my/prelude-welcome-latex-project)
  (when (get-buffer prelude-welcome-buffer-name)
    (with-current-buffer prelude-welcome-buffer-name
      (let ((position (point)))
        (prelude-welcome-refresh)
        (goto-char (min position (point-max)))))))

;;; welcome.el ends here
