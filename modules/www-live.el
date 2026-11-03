;;; www-live.el --- Local website preview -*- lexical-binding: t; -*-

(defvar my/www-live-url "http://127.0.0.1:5500/"
  "Local live-reload preview URL.")

(defun my/www-live--service (action)
  "Run systemd ACTION for the website preview."
  (with-temp-buffer
    (let ((status (call-process "/usr/bin/systemctl" nil t nil
                                "--user" action "www-live-server.service")))
      (unless (eq status 0)
        (user-error "Live server: %s" (string-trim (buffer-string)))))))

(defun my/www-live--wait-ready ()
  "Wait up to five seconds for the local preview listener."
  (let ((deadline (+ (float-time) 5)) ready)
    (while (and (not ready) (< (float-time) deadline))
      (setq ready
            (condition-case nil
                (let ((connection
                       (make-network-process
                        :name "www-live-readiness"
                        :host "127.0.0.1" :service 5500
                        :nowait nil :noquery t)))
                  (delete-process connection)
                  t)
              (file-error nil)))
      (unless ready (accept-process-output nil 0.05)))
    (unless ready
      (user-error "Live server did not become ready; check its systemd log"))))

(defun my/www-live-start (&optional no-browser)
  "Start the live server for ~/www and open its preview.
With prefix argument NO-BROWSER, start without opening a browser."
  (interactive "P")
  (my/www-live--service "start")
  (my/www-live--wait-ready)
  (unless no-browser
    (browse-url my/www-live-url))
  (message "Live server started: %s" my/www-live-url))

(defun my/www-live-stop ()
  "Stop the live server without stopping Nginx or Tor."
  (interactive)
  (my/www-live--service "stop")
  (message "Live server stopped"))

(defun my/www-live-browse ()
  "Start the live server if necessary and open the preview."
  (interactive)
  (my/www-live-start))

(defun my/www-live-edit ()
  "Open ~/www/index.html and start its live preview."
  (interactive)
  (find-file (expand-file-name "~/www/index.html"))
  (my/www-live-start))

(define-prefix-command 'my/www-live-map)
(define-key global-map (kbd "C-c w") 'my/www-live-map)
(define-key my/www-live-map (kbd "s") #'my/www-live-start)
(define-key my/www-live-map (kbd "k") #'my/www-live-stop)
(define-key my/www-live-map (kbd "b") #'my/www-live-browse)
(define-key my/www-live-map (kbd "e") #'my/www-live-edit)

(when (fboundp 'map!)
  (map! :leader
        :prefix ("o w" . "website")
        :desc "Start live server" "s" #'my/www-live-start
        :desc "Stop live server" "k" #'my/www-live-stop
        :desc "Open live preview" "b" #'my/www-live-browse
        :desc "Edit website and preview" "e" #'my/www-live-edit))

(provide 'www-live)
