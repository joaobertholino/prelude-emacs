;;; update-tests.el --- Regression checks for Prelude updates -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(load (expand-file-name "../modules/update.el"
                        (file-name-directory (or load-file-name buffer-file-name)))
      nil t)

(ert-deftest personal-update-reports-demoted-package-failure ()
  "A failed package makes the worker fail even if other upgrades continue."
  (let (completed)
    (cl-letf (((symbol-function 'call-process) (lambda (&rest _) 0))
              ((symbol-function 'package-initialize) #'ignore)
              ((symbol-function 'package-upgrade)
               (lambda (package)
                 (if (eq package 'broken-package)
                     (error "Simulated signature verification failure")
                   (push package completed))))
              ((symbol-function 'package-upgrade-all)
               (lambda (&rest _)
                 ;; Match package.el's individual-error demotion behavior.
                 (dolist (package '(broken-package good-package))
                   (condition-case nil
                       (package-upgrade package)
                     (error nil))))))
      (let ((err (should-error
                  (my/prelude-update-worker "/tmp" "/tmp/elpa" nil nil))))
        (should (string-match-p "broken-package.*signature verification failure"
                                (error-message-string err))))
      (should (equal completed '(good-package))))))

(ert-deftest personal-update-successful-packages-remain-successful ()
  (let (completed)
    (cl-letf (((symbol-function 'package-upgrade)
               (lambda (package) (push package completed)))
              ((symbol-function 'package-upgrade-all)
               (lambda (&rest _) (package-upgrade 'good-package))))
      (should-not (my/prelude-upgrade-packages))
      (should (equal completed '(good-package))))))

;;; update-tests.el ends here
