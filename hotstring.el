;;; hotstring.el --- auto replace string like Autohotkey's hotstring
;;
;; Copyright (C) 2013 a23
;;
;; Author:       a23
;; Maintainer:   a23
;; Version:      1.0
;; Created:      2013/10/01 12:42:46 (+0900)
;; Last-Updated: 2015/09/27 09:46:10 (+0900)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is part of Emacs.
;;
;; This file is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;  ===========
;;
;;  `hots' abbrev `hotstring'
;;
;;  Features that might be required by this library:
;;
;;   `timer'.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;  ===========
;;
;; 2013/10/01    Atami
;;    initialize:
;;
;;
;;; Code:



(eval-when-compile
  (require 'subr-x "subr-x" 'noerr))


(require 'timer nil 'noerror)
(require 'advice "advice" 'noerr)


(defgroup hotstring nil
  "Hotstring."
  :group 'editing
  :prefix "hots-")

(defcustom hots-clear-keys '(" " "\n")
  "Trigger keys for sequence."
  :type '(repeat string)
  :group 'hotstring)

(defcustom hots-after-replaced-hook '(hots-default-replaced-notifier)
  "Hook to run after replaced string."
  :type 'hook
  :group 'hotstring)

(defcustom hots-changed-sequence-hook nil
  "Hook to run after changed internal sequence."
  :type 'hook
  :group 'hotstring)

(defcustom hots-flash-p t
  "Non-nil means flash highlight replaced string."
  :type 'boolean
  :group 'hotstring)

(defcustom hots-flash-lighting-time 0.4
  "Float secounds for flash lighting."
  :type 'float
  :group 'hotstring)

(defcustom hots-flash-color '(:background "red")
  "Face of flash color."
  :type 'face
  :group 'hotstring)

(defcustom hots-global-table-predefine '(("eamcs" . "emacs")
                                         ("pyhton" . "python"))
  "Document"
  :type 'cons
  :group 'hotstring)


;;;; Hash Tables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; global hash table
(defvar hots--global-hash-table (make-hash-table :test 'equal :size 1000))

(defun hots--global-hash-table-put (key value)
  ""
  (puthash key value hots--global-hash-table))

(defun hots--global-hash-table-remove (key)
  ""
  (remhash key hots--global-hash-table))

(defun hots--global-hash-table-get (key)
  ""
  (and hots--global-hash-table (gethash key hots--global-hash-table)))

(defun hots--global-hash-table-keys ()
  ""
  (hash-table-keys hots--global-hash-table))

(defun hots--global-hash-table-values ()
  ""
  (hash-table-values hots--global-hash-table))

(defun hots--global-hash-table-clear ()
  ""
  (mapcar (lambda (k) (hots--global-hash-table-remove k))
          (hots--global-hash-table-keys)))

(defun hots--global-hash-table-contains-p (key)
  ""
  (and (hots--global-hash-table-get key) t))

;; local hash table
(defvar hots--local-hash-table nil)
(make-variable-buffer-local 'hots--local-hash-table)

(defun hots--local-hash-table-init ()
  ""
  (when (eq hots--local-hash-table nil)
    (setq hots--local-hash-table (make-hash-table :test 'equal))))

(defun hots--local-hash-table-put (key value)
  " "
  (puthash key value hots--local-hash-table))

(defun hots--local-hash-table-remove (key)
  ""
  (remhash key hots--local-hash-table))

(defun hots--local-hash-table-get (key)
  ""
  (and hots--local-hash-table (gethash key hots--local-hash-table)))

(defun hots--local-hash-table-keys ()
  ""
  (hash-table-keys hots--local-hash-table))

(defun hots--local-hash-table-values ()
  ""
  (hash-table-values hots--local-hash-table))

(defun hots--local-hash-table-clear ()
  ""
  (mapcar (lambda (k) (hots--local-hash-table-remove k))
          (hots--local-hash-table-keys)))

(defun hots--local-hash-table-contains-p (key)
  ""
  (and (hots--local-hash-table-get key) t))

;; interface for hash tables
(defun hots-global-table-register (key value)
  " "
  (interactive (list (read-string "register key: ")
                     (read-string "register value: ")))
  (hots--global-hash-table-put key value))

(defun hots--global-table-register-from-list (list)
  ""
  (mapc (lambda (elm) (hots--global-hash-table-put (car elm) (cdr elm))) list))

(defun hots-global-table-unregister (key)
  ""
  (interactive (list (read-string "remove key: ")))
  (hots--global-hash-table-remove key))

(defun hots-global-table-clear ()
  ""
  (interactive)
  (hots--global-hash-table-clear))

(defun hots-local-table-register (key value)
  " "
  (interactive (list (read-string "register key: ")
                     (read-string "register value: ")))
  (hots--local-hash-table-put key value))

(defun hots--local-table-register-from-list (list)
  ""
  (mapc (lambda (elm) (hots--local-hash-table-put (car elm) (cdr elm))) list))

(defun hots-local-table-unregister (key)
  ""
  (interactive (list (read-string "remove key: ")))
  (hots--local-hash-table-remove key))

(defun hots-local-table-clear ()
  ""
  (interactive)
  (hots--local-hash-table-clear))

(defun hots--tables-get (key)
  ""
  (or (hots--local-hash-table-get key) (hots--global-hash-table-get key)))

(defun hots-tables-unregister (key)
  ""
  (interactive (list (read-string "unregister key: ")))
  (hots--local-hash-table-remove key)
  (hots--global-hash-table-remove key))


;;;; sequence ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defvar hots--sequence "")

(defun hots--sequence-clear ()
  ""
  (setq hots--sequence "")
  (run-hooks 'hots-changed-sequence-hook))

(defun hots--sequence-append (chars)
  ""
  (setq hots--sequence (or (concat hots--sequence chars) ""))
  (run-hooks 'hots-changed-sequence-hook))

(defun hots--sequence-pop (&optional count)
  ""
  (setq hots--sequence (or (substring hots--sequence 0 (- (or count 1))) ""))
  (run-hooks 'hots-changed-sequence-hook))

(defun hots--sequence-delete-from-right (count)
  ""
  (when (< (hots--sequence-length) count)
    (setq count (hots--sequence-length)))
  (hots--sequence-pop count)
  (run-hooks 'hots-changed-sequence-hook))

(defun hots--sequence-get ()
  ""
  hots--sequence)

(defun hots--sequence-length ()
  ""
  (length hots--sequence))

(defun hots--sequence-equal (string)
  ""
  (string= hots--sequence string))

;; debug
(defun hots--debug-msg-sequence ()
  ""
  (or (minibufferp) (message "seq:%S" (hots--sequence-get))))

(defun hots-toggle-debug-sequence ()
  ""
  (interactive)
  (if (member 'hots--debug-msg-sequence hots-changed-sequence-hook)
      (progn
        (remove-hook 'hots-changed-sequence-hook 'hots--debug-msg-sequence)
        (message "hotstring: Disabled debug message."))
    (add-hook 'hots-changed-sequence-hook 'hots--debug-msg-sequence)
    (message "hotstring: Enabled debug message.")
    ))

;;;; Notifier ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defvar hots-flashing-overlay nil "[Internal].")
(defun hots-flash-overlay (start end color sec)
  ""
  (setq hots-flashing-overlay (make-overlay start end nil nil t))
  (overlay-put hots-flashing-overlay 'face color)
  (run-with-timer sec nil 'delete-overlay hots-flashing-overlay))

(defun hots-flash (start end)
  ""
  (hots-flash-overlay start end hots-flash-color hots-flash-lighting-time))

(defvar hots-last-replaced (list "" "" 0 0 nil))

(defun hots-default-replaced-notifier ()
  ""
  (and hots-flash-p
       (hots-flash (nth 2 hots-last-replaced) (nth 3 hots-last-replaced)))
  (or (minibufferp)
      (message "Replaced: %s => %s"
               (nth 0 hots-last-replaced)
               (nth 1 hots-last-replaced))))

;;;; minor mode setup
;;
(defvar hotstring-mode nil)
(defvar hots--loaded-global-table nil)

(defun hots--init-global-table ()
  ""
  (hots--global-table-register-from-list hots-global-table-predefine))

(defun hots-reload-global-table ()
  ""
  (interactive)
  (hots-global-table-clear)
  (hots--init-global-table))

(defun hots-setup ()
  ""
  (unless hots--local-hash-table
    (setq hots--local-hash-table (make-hash-table :test 'equal)))
  (add-hook 'post-self-insert-hook 'hots-key-listener)
  (unless hots--loaded-global-table
    (setq hots--loaded-global-table t)
    (hots--init-global-table))
  )

;;;###autoload
(define-minor-mode hotstring-mode
  "Hotstring mode"
  :ligther "HOTS"
  :group 'hotstring
  (if hotstring-mode
      (hots-setup)
    (remove-hook 'post-self-insert-hook 'hots-key-listener)))

;;;###autoload
(define-global-minor-mode hotstring-global-mode
  hotstring-mode
  (lambda ()
    (hotstring-mode 1))
  :group 'hotstring)


;;;; replacer ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defun hots--replacer (old new)
  ""
  (let (start)
    (delete-char (- (length old)))
    (setq start (point))
    (insert new)
    start))

(defun hots--replace ()
  ""
  (let* ((target-str (hots--sequence-get))
         (new-str (hots--tables-get target-str)))
    (when new-str
      (setq hots-last-replaced
            (list target-str new-str
                  (hots--replacer target-str new-str) (point)
                  (current-buffer)))
      (run-hooks 'hots-after-replaced-hook))))

(defun hots-key-listener ()
  "Replace certain text as it is typed."
  (when hotstring-mode
    (let ((str (char-to-string last-command-event)))
      (if (member str hots-clear-keys)
          (hots--sequence-clear)
        (or (eq this-command last-command) (hots--sequence-clear))
        (hots--sequence-append str)
        (hots--replace)
        ))))



(provide 'hotstring)
;; For Emacs
;; Local Variables:
;; no-check-type-miss: t
;; coding: utf-8
;; End:
;;; hotstring.el ends here
