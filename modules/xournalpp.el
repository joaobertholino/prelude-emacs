;;; xournalpp.el --- Handwritten notes in Org -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)

(add-to-list 'load-path (expand-file-name "vendor/org-xournalpp" prelude-personal-dir))

(defvar-local my/xournalpp-refresh-timer nil)

(defun my/xournalpp-edit (path &optional _)
  "Open PATH without blocking Emacs, including when it runs as a daemon."
  (let* ((path (expand-file-name path))
         (process-environment (copy-sequence process-environment))
         (display (frame-parameter nil 'display)))
    (unless (and (not (file-remote-p path)) (file-exists-p path))
      (user-error "Choose an existing local Xournal++ notebook"))
    (when (and (stringp display) (string-prefix-p ":" display))
      (setenv "DISPLAY" display))
    (set-process-query-on-exit-flag
     (start-process "xournalpp" "*Xournal++*" org-xournalpp-executable path) nil)
    (org-xournalpp--add-watcher path)))

(defun my/xournalpp-get-image (path refresh)
  "Render the first page of PATH, with a bounded wait and checked exit status."
  (when (file-remote-p path)
    (user-error "Xournal++ previews require a local file"))
  (let* ((path (expand-file-name path))
         (cache (org-xournalpp--make-cached-image-file-name path "png")))
    (when (or refresh (not (file-exists-p cache))
              (file-newer-than-file-p path cache))
      (make-directory (file-name-directory cache) t)
      (let ((temp (make-temp-file
                   (expand-file-name ".xournalpp-preview-" (file-name-directory cache))
                   nil ".png")))
        (unwind-protect
            (with-temp-buffer
              (let ((status (call-process
                             "timeout" nil (current-buffer) nil "15s"
                             org-xournalpp-executable "--export-range=1"
                             "--export-png-width=900" "-i" temp path)))
                (unless (and (eq status 0) (file-exists-p temp)
                             (> (file-attribute-size (file-attributes temp)) 0))
                  (error "Xournal++ preview failed (%s): %s"
                         status (string-trim (buffer-string))))
                (rename-file temp cache t)))
          (when (file-exists-p temp) (delete-file temp)))))
    cache))

(defun my/xournalpp-refresh ()
  "Refresh previews and watches in the current Org buffer."
  (interactive)
  (when (derived-mode-p 'org-mode)
    (let ((buffer (current-buffer))
          (frame (if (display-graphic-p) (selected-frame)
                   (cl-find-if #'display-graphic-p (frame-list)))))
      (save-excursion
        (org-xournalpp--disable)
        (dolist (link (org-xournalpp--get-links))
          (let ((path (expand-file-name (org-element-property :path link))))
            (when (and (not (file-remote-p path)) (file-exists-p path))
              (condition-case err
                  (when frame
                    (with-selected-frame frame
                      (with-current-buffer buffer
                        (org-xournalpp--show-link link t))))
                (error (message "%s" (error-message-string err))))
              (org-xournalpp--add-watcher path))))))))

(defun my/xournalpp-add-watcher (path)
  "Watch PATH in its owning Org buffer, including atomic replacements."
  (unless (or (file-remote-p path)
              (alist-get path org-xournalpp--watchers nil nil #'equal))
    (let* ((buffer (current-buffer))
           (path (expand-file-name path))
           (watch
            (file-notify-add-watch
             (file-name-directory path) '(change)
             (lambda (event)
               (when (and (buffer-live-p buffer)
                          (memq (cadr event) '(changed created renamed attribute-changed))
                          (member path (cddr event)))
                 (with-current-buffer buffer
                   (when (timerp my/xournalpp-refresh-timer)
                     (cancel-timer my/xournalpp-refresh-timer))
                   (setq my/xournalpp-refresh-timer
                         (run-with-idle-timer
                          0.3 nil
                          (lambda ()
                            (when (buffer-live-p buffer)
                              (with-current-buffer buffer
                                (when org-xournalpp-mode
                                  (my/xournalpp-refresh)))))))))))))
      (push (cons path watch) org-xournalpp--watchers))))

(defun my/xournalpp-cleanup ()
  "Release preview resources when leaving an Org buffer."
  (when (timerp my/xournalpp-refresh-timer)
    (cancel-timer my/xournalpp-refresh-timer))
  (org-xournalpp--disable))

(defun my/xournalpp-template ()
  "Choose a ruled A4 notebook template."
  (expand-file-name
   (concat "templates/xournalpp/"
           (completing-read "Paper: " '("A4-pautado-escuro" "A4-pautado-claro")
                            nil t nil nil "A4-pautado-escuro")
           ".xopp")
   prelude-personal-dir))

(defun my/xournalpp-new (path description)
  "Create a notebook at PATH, insert its link and open it for editing."
  (interactive (list (read-file-name "New Xournal++ notebook: " nil nil nil "notes.xopp")
                     (read-string "Description: " "Handwritten notes")))
  (unless (derived-mode-p 'org-mode) (user-error "Use this command in an Org buffer"))
  (setq path (expand-file-name (org-xournalpp--validate-path path)))
  (when (file-remote-p path) (user-error "Choose a local notebook"))
  (when (file-exists-p path) (user-error "This notebook already exists; use C-c x i"))
  (org-xournalpp-insert-new-image path description (my/xournalpp-template))
  (org-xournalpp--edit path))

(defun my/xournalpp-insert (path description)
  "Insert a link to an existing Xournal++ notebook PATH."
  (interactive (list (read-file-name "Xournal++ notebook: " nil nil t)
                     (read-string "Description: " "Handwritten notes")))
  (unless (derived-mode-p 'org-mode) (user-error "Use this command in an Org buffer"))
  (unless (and (file-regular-p path) (string-equal (file-name-extension path) "xopp")
               (not (file-remote-p path)))
    (user-error "Choose a local .xopp file"))
  (org-insert-link nil (concat "xournalpp:" (file-relative-name (expand-file-name path))) description)
  (my/xournalpp-refresh))

(with-eval-after-load 'org
  (when (fboundp 'prelude-require-packages)
    (prelude-require-packages '(f s)))
  (require 'org-xournalpp)
  (setq org-xournalpp-executable "/usr/local/bin/xournalpp"
        org-xournalpp-image-type 'png
        org-xournalpp-template-getter #'my/xournalpp-template)
  (advice-add 'org-xournalpp--get-image :override #'my/xournalpp-get-image)
  (advice-add 'org-xournalpp--edit :override #'my/xournalpp-edit)
  (advice-add 'org-xournalpp--add-watcher :override #'my/xournalpp-add-watcher)
  (advice-add 'org-xournalpp--enable :override #'my/xournalpp-refresh)
  (add-hook 'org-mode-hook #'org-xournalpp-mode)
  (add-hook 'org-mode-hook
            (lambda () (add-hook 'kill-buffer-hook #'my/xournalpp-cleanup nil t)))
  (define-key org-mode-map (kbd "C-c x") nil)
  (define-key org-mode-map (kbd "C-c x n") #'my/xournalpp-new)
  (define-key org-mode-map (kbd "C-c x i") #'my/xournalpp-insert)
  (define-key org-mode-map (kbd "C-c x r") #'my/xournalpp-refresh)
  (define-key org-mode-map (kbd "C-c x o") #'org-open-at-point))

(provide 'personal-xournalpp)
