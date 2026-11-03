;;; org.el -*- lexical-binding: t; -*-
(with-eval-after-load 'org
  (setq org-directory "~/Org-Notes/"
        org-agenda-files '("~/Org-Notes/tarefas.org" "~/Org-Notes/projetos.org")
        org-default-notes-file (expand-file-name "task.org" org-directory)
        org-todo-keywords '((sequence "TODO(t)" "IN-PROGRESS(p)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)"))
        org-capture-templates
        '(("t" "New Task" entry (file+headline "task.org" "Inbox") "* TODO %?\n  Create in: %U\n  %i" :prepend t)
          ("p" "Project idea" entry (file+headline "project.org" "Ideias") "* TODO %?\n  %i" :prepend t))))
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)
