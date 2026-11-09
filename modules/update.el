;;; update.el --- Update Prelude without blocking the editor -*- lexical-binding: t; -*-

(require 'package)

(defun my/prelude-update-worker (framework packages archives framework-only)
  "Update FRAMEWORK and PACKAGES using ARCHIVES in a separate Emacs.
When FRAMEWORK-ONLY is non-nil, leave installed packages unchanged."
  (let ((default-directory (file-name-as-directory framework)))
    ;; Personal is a separate repository reached through a symbolic link.
    ;; Never reset, stash, commit or pull that repository as part of this job.
    (unless (zerop (call-process "git" nil nil nil "diff" "--quiet" "HEAD"
                                 "--" "." ":(exclude)personal"))
      (error "Prelude has local framework edits; preserve them before updating"))
    (with-temp-buffer
      (let ((status (call-process "git" nil t t "pull" "--no-rebase" "--ff-only"
                                  "origin" "master")))
        (princ (buffer-string))
        (unless (zerop status)
          (error "Prelude update failed; see the Git output above")))))
  (unless framework-only
    (setq package-user-dir packages
          package-archives archives
          package-native-compile nil
          native-comp-async-jobs-number 1)
    (package-initialize)
    (package-upgrade-all))
  (princ "\nPrelude update finished. Save your work and restart Emacs when convenient.\n"))

(defun my/prelude-update-sentinel (process event)
  "Report completion of PROCESS after EVENT without restarting Emacs."
  (when (memq (process-status process) '(exit signal))
    (with-current-buffer (process-buffer process)
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (insert (format "\nUpdate process: %s" event))))
    (if (and (eq (process-status process) 'exit)
             (zerop (process-exit-status process)))
        (message "Prelude updated. Save your work and restart Emacs when convenient.")
      (display-buffer (process-buffer process))
      (message "Prelude update failed; see *prelude-update* for details."))))

(defun my/prelude-update (&optional framework-only)
  "Update Prelude and its packages in the background.
With a prefix argument, update only the framework. Output is available in
`*prelude-update*'. Personal settings and open buffers are preserved."
  (interactive "P")
  (when (process-live-p (get-process "prelude-update"))
    (user-error "A Prelude update is already running; see *prelude-update*"))
  (when (y-or-n-p (if framework-only "Update only the Prelude framework? "
                   "Update Prelude and its installed packages? "))
    (let* ((module (expand-file-name "modules/update.el" prelude-personal-dir))
           (worker (list 'my/prelude-update-worker prelude-dir package-user-dir
                         (list 'quote package-archives) (and framework-only t)))
           (emacs (expand-file-name invocation-name invocation-directory))
           (buffer (get-buffer-create "*prelude-update*"))
           (command (append (when (executable-find "nice") '("nice" "-n" "10"))
                            (list emacs "-Q" "--batch" "-l" module
                                  "--eval" (prin1-to-string worker)))))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert "Updating Prelude in the background…\n\n"))
        (special-mode))
      (make-process :name "prelude-update" :buffer buffer :command command
                    :noquery t :connection-type 'pipe
                    :sentinel #'my/prelude-update-sentinel)
      (display-buffer buffer)
      (message "Updating Prelude; progress is in *prelude-update*."))))

;; Keep Prelude's familiar command and menu entry while using our safe updater.
(advice-add 'prelude-update :override #'my/prelude-update)

(provide 'personal-update)
;;; update.el ends here
