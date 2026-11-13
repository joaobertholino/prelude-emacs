;;; xournalpp-tests.el --- Org notebook integration tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'cl-lib)
(require 'org)

(ert-deftest my/xournalpp-real-preview-and-cleanup ()
  (let ((dir (make-temp-file "prelude-xournalpp-" t)))
    (unwind-protect
        (with-temp-buffer
          (setq default-directory (file-name-as-directory dir))
          (copy-file (expand-file-name "templates/xournalpp/A4-pautado-escuro.xopp"
                                       prelude-personal-dir)
                     (expand-file-name "notes.xopp" dir))
          (org-mode)
          (should org-xournalpp-mode)
          (my/xournalpp-insert (expand-file-name "notes.xopp" dir) "Test notes")
          (should (= 1 (length org-xournalpp--overlays)))
          (should (= 1 (length org-xournalpp--watchers)))
          (let ((preview (expand-file-name ".notes.png" dir))
                (point-before (point)))
            (should (file-exists-p preview))
            (should (> (file-attribute-size (file-attributes preview)) 100))
            (my/xournalpp-refresh)
            (should (= point-before (point)))
            (should (= 1 (length org-xournalpp--overlays)))
            (should (= 1 (length org-xournalpp--watchers))))
          (org-xournalpp-mode -1)
          (should-not org-xournalpp--overlays)
          (should-not org-xournalpp--watchers))
      (delete-directory dir t))))

(ert-deftest my/xournalpp-preview-failure-does-not-wait ()
  (let ((dir (make-temp-file "prelude-xournalpp-failure-" t)))
    (unwind-protect
        (let ((calls 0))
          (cl-letf (((symbol-function 'call-process)
                     (lambda (&rest _) (cl-incf calls) 124)))
            (should-error (my/xournalpp-get-image (expand-file-name "bad.xopp" dir) t))
            (should (= calls 1))))
      (delete-directory dir t))))

(ert-deftest my/xournalpp-new-protects-existing-file ()
  (let ((file (make-temp-file "prelude-xournalpp-existing-" nil ".xopp" "keep")))
    (unwind-protect
        (with-temp-buffer
          (org-mode)
          (should-error (my/xournalpp-new file "Do not overwrite") :type 'user-error)
          (should (equal "keep" (with-temp-buffer (insert-file-contents file) (buffer-string)))))
      (delete-file file))))

(ert-deftest my/xournalpp-creation-and-opening ()
  (let* ((dir (make-temp-file "prelude-xournalpp-new-" t))
         (path (expand-file-name "new.xopp" dir))
         opened)
    (unwind-protect
        (with-temp-buffer
          (setq default-directory (file-name-as-directory dir))
          (org-mode)
          (cl-letf (((symbol-function 'my/xournalpp-template)
                     (lambda () (expand-file-name "templates/xournalpp/A4-pautado-escuro.xopp"
                                                  prelude-personal-dir)))
                    ((symbol-function 'org-xournalpp--edit)
                     (lambda (file &optional _) (setq opened file))))
            (my/xournalpp-new (file-name-sans-extension path) "New notes"))
          (should (file-exists-p path))
          (should (equal path opened))
          (should (string-match-p "xournalpp:new.xopp" (buffer-string)))
          (should (= 1 (length org-xournalpp--overlays))))
      (delete-directory dir t))))
