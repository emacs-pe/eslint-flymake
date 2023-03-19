;;; eslint-flymake --- An ESLint backend for Flymake.   -*- lexical-binding: t -*-

;; Copyright (C) 2019 Javier Olaechea

;; Author: Javier Olaechea <pirata@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: javascript, languages, flymake
;; URL: http://github.com/emacs-pe/eslint-flymake

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides an ESLint backend for Flymake.
;; To enable it add the following to your init.el
;;
;;   (add-hook 'js-mode-hook 'eslint-flymake-setup-backend)
;;
;; Ideas for further development
;; - 'eslint-flymake-explain-diagnostic' to open rule explanation in
;;   the users browser.
;; - Parse error w/o regexp.

;;; Code:

(require 'cl-lib)
(require 'flymake)

(defgroup eslint-flymake nil
  "Flymake backend for ESLint"
  :group 'programming
  :prefix "eslint-flymake-")

(defvar-local eslint-flymake-proc nil)

(defcustom eslint-flymake-command '("eslint" "--no-color" "--stdin")
  "The `eslint' command along with the arguments it should be called with."
  :type '(repeat  string)
  :group 'eslint-flymake)

;; 1 both and line:col
;; 2 line
;; 3 column
;; 4 severity
;; 5 msg
;; 6 rule
(defvar eslint-flymake-regexp
  (rx-to-string
   '(seq (group (group (+ digit)) ":" (group (+ digit)))
         (+ " ") (group (or "error" "warning"))
         (group  (1+ any))
         blank
         (group (1+  any))
         eol)))

(defun eslint-flymake (report-fn &rest _args)
  (when (process-live-p eslint-flymake-proc)
    (kill-process eslint-flymake-proc))

  (let ((source-buffer (current-buffer)))
    (save-restriction
      (widen)
      (setq eslint-flymake-proc
            (make-process :name "eslint-flymake"
                          :noquery t
                          :connection-type 'pipe
                          :buffer (generate-new-buffer "*eslint-flymake*")
                          :command eslint-flymake-command
                          :sentinel (lambda (proc _event)
                                      (when (memq (process-status proc) '(signal exit))
                                        (unwind-protect
                                            (if (with-current-buffer source-buffer (eq proc eslint-flymake-proc))
                                                (with-current-buffer (process-buffer proc)
                                                  (goto-char (point-min))
                                                  (cl-loop
                                                   while (search-forward-regexp eslint-flymake-regexp nil t)
                                                   for (beg . end) = (flymake-diag-region source-buffer
                                                                                          (string-to-number (match-string 2))
                                                                                          (string-to-number (match-string 3)))
                                                   for type = (pcase (match-string 4)
                                                                ("warning" :warning)
                                                                ("error" :error)
                                                                (_ :note))
                                                   for msg = (match-string 5)
                                                   collect (flymake-make-diagnostic source-buffer
                                                                                    beg end
                                                                                    type msg)
                                                   into diags
                                                   finally (funcall report-fn diags)))
                                              (flymake-log :warning "Canceling obsolete check %s"
                                                           proc))
                                          (kill-buffer (process-buffer proc)))))))

      (process-send-region eslint-flymake-proc (point-min) (point-max))
      (process-send-eof eslint-flymake-proc))))

(defun eslint-flymake-setup-backend ()
  (add-hook 'flymake-diagnostic-functions 'eslint-flymake nil t))

(add-hook 'js-mode-hook 'eslint-flymake-setup-backend)

(provide 'eslint-flymake)
