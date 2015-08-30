;;; emc-command-info.el --- Info for the currently running command

;;; Commentary:

;; This file contains functions for storing and interacting with
;; the currently running command info

(require 'evil)
(require 'emc-common)

;;; Code:

(evil-define-local-var emc-command nil
  "Data for the current command to be executed by the fake cursors.")

(evil-define-local-var emc-command-recording nil
  "True if recording `this-command' data.")

(evil-define-local-var emc-command-debug nil
  "If true display debug messages about the current command being recorded.")

(defun emc-command-p ()
  "True if there is data saved for the current command."
  (not (null emc-command)))

(defun emc-command-reset ()
  "Clear the currently saved command info."
  (setq emc-command nil)
  (setq emc-command-recording nil))

(defun emc-command-debug-on ()
  "Show debug messages about the current command being recorded."
  (interactive)
  (setq emc-command-debug t))

(defun emc-command-debug-off ()
  "Hide debug messages about the current command being recorded."
  (interactive)
  (setq emc-command-debug nil))

(defun emc-command-recording-p ()
  "True if recording a command."
  (eq emc-command-recording t))

(defun emc-supported-command-p (cmd)
  "Return true if CMD is supported for multiple cursors."
  (let ((repeat-type (evil-get-command-property cmd :repeat)))
    (or (eq repeat-type 'motion)

        ;; extended commands (should be configurable by user)

        (eq cmd 'evil-commentary)
        (eq cmd 'org-self-insert-command)
        (eq cmd 'spacemacs/evil-numbers-increase)
        (eq cmd 'spacemacs/evil-numbers-decrease)
        (eq cmd 'transpose-chars-before-point)
        (eq cmd 'yaml-electric-dash-and-dot)
        (eq cmd 'yaml-electric-bar-and-angle)

        ;; core evil + emacs commands

        (eq cmd 'backward-delete-char-untabify)
        (eq cmd 'copy-to-the-end-of-line)
        (eq cmd 'delete-backward-char)
        (eq cmd 'evil-append)
        (eq cmd 'evil-append-line)
        (eq cmd 'evil-change)
        (eq cmd 'evil-change-line)
        (eq cmd 'evil-complete-next)
        (eq cmd 'evil-delete)
        (eq cmd 'evil-delete-backward-char-and-join)
        (eq cmd 'evil-delete-backward-word)
        (eq cmd 'evil-delete-char)
        (eq cmd 'evil-delete-line)
        (eq cmd 'evil-digit-argument-or-evil-beginning-of-line)
        (eq cmd 'evil-downcase)
        (eq cmd 'evil-insert-line)
        (eq cmd 'evil-invert-char)
        (eq cmd 'evil-join)
        (eq cmd 'evil-normal-state)
        (eq cmd 'evil-open-above)
        (eq cmd 'evil-open-below)
        (eq cmd 'evil-paste-after)
        (eq cmd 'evil-paste-before)
        (eq cmd 'evil-repeat)
        (eq cmd 'evil-replace)
        (eq cmd 'evil-upcase)
        (eq cmd 'evil-visual-char)
        (eq cmd 'evil-visual-line)
        (eq cmd 'evil-visual-block)
        (eq cmd 'evil-yank)
        (eq cmd 'keyboard-quit)
        (eq cmd 'move-text-down)
        (eq cmd 'move-text-up)
        (eq cmd 'newline-and-indent)
        (eq cmd 'paste-after-current-line)
        (eq cmd 'paste-before-current-line)
        (eq cmd 'self-insert-command)
        (eq cmd 'yank)

        )))

(defun emc-get-evil-state ()
  "Get the current evil state."
  (cond ((evil-insert-state-p) 'insert)
        ((evil-motion-state-p) 'motion)
        ((evil-visual-state-p) 'visual)
        ((evil-normal-state-p) 'normal)
        ((evil-replace-state-p) 'replace)
        ((evil-operator-state-p) 'operator)
        ((evil-emacs-state-p) 'emacs)))

(defun emc-set-command-property (&rest properties)
  "Set one or more command PROPERTIES and their values into `emc-command'."
  (setq emc-command (apply 'emc-put-object-property
                           (cons emc-command properties))))

(defun emc-get-command-property (name)
  "Return the current command property with NAME."
  (emc-get-object-property emc-command name))

(defun emc-begin-command-save ()
  "Initialize all variables at the start of saving a command."
  (when emc-command-debug (message "> CMD %s %s" this-command (this-command-keys)))
  (when (and (not emc-running-command)
             (not (emc-command-recording-p)))
    (setq emc-command nil))
  (when (and (not (emc-command-recording-p))
             (not emc-running-command)
             (not (evil-emacs-state-p))
             (emc-has-cursors-p))
    (let ((cmd this-command))
      (when (emc-supported-command-p cmd)
        (setq emc-command-recording t)
        (emc-set-command-property
         :name cmd
         :last last-command
         :operator-pending (evil-operator-state-p)
         :evil-state-begin (emc-get-evil-state)
         :keys-pre (this-command-keys-vector))
        (when emc-command-debug
          (message "> CMD-BEGIN %s" emc-command))))))

(defun emc-save-key-sequence (prompt &optional continue-echo dont-downcase-last
                                     can-return-switch-frame cmd-loop)
  "Save the current command key sequence."
  (when (emc-command-recording-p)
    (emc-set-command-property
     :keys-seq (vconcat
                (emc-get-command-property :keys-seq)
                (this-command-keys-vector)))
    (when emc-command-debug
      (message "+ CMD-KEY-SEQ %s %s %s"
               (this-command-keys)
               (this-command-keys-vector)
               this-command))))

(defun emc-finish-command-save ()
  "Completes the save of a command."
  (when (emc-command-recording-p)
    (emc-set-command-property
     :keys-post (this-command-keys-vector)
     :last-input (vector last-input-event)
     :evil-state-end (emc-get-evil-state)
     :keys-post-raw (this-single-command-raw-keys))
    (when emc-command-debug
      (message "| CMD-FINISH %s %s" emc-command this-command))
    (ignore-errors
      (condition-case error
          (emc-finalize-command)
        (error (message "Saving command %s failed with %s"
                        (emc-get-command-name)
                        (error-message-string error))
               nil))))
  (setq emc-command-recording nil))

(defun emc-key-to-char (key)
  "Converts KEY to a character if it is not one already."
  (cond ((characterp key) key)
        ((eq 'escape key) 27)
        ((eq 'backspace key) 127)
        ((and (stringp key) (string-equal key "escape")) 27)
        ((and (stringp key) (string-equal key "backspace")) 127)
        (t (message "Invalid key %s %s" key (type-of key)) 0)))

(defun emc-get-command-keys (&optional name)
  "Get the current command keys with NAME as a list."
  (mapcar 'emc-key-to-char
          (listify-key-sequence
           (emc-get-command-property (or name :keys)))))

(defun emc-get-command-keys-string (&optional name)
  "Get the current command keys with NAME as a string."
  (when emc-command
    (let* ((keys (emc-get-command-keys (or name :keys)))
           (keys-string (mapcar 'char-to-string keys)))
      (apply 'concat keys-string))))

(defun emc-get-command-name ()
  "Return the current command name."
  (when emc-command
    (emc-get-command-property :name)))

(defun emc-get-command-state ()
  "Return the current command end evil state."
  (when emc-command
    (emc-get-command-property :evil-state-end)))

(defun emc-finalize-command ()
  "Makes the command data ready for use, after a save.."
  (let ((pre (emc-get-command-keys :keys-pre))
        (seq (emc-get-command-keys :keys-seq))
        (post (emc-get-command-keys :keys-post))
        (last (emc-get-command-keys :last-input))
        (keys nil))
    (setq keys (or seq pre))
    (unless (null seq)
      (setq keys (append keys (or post last))))
    (emc-set-command-property :keys keys))
  (when emc-command-debug
    (message "< CMD-DONE %s %s %s %s %s -> %s"
             (emc-get-object-property emc-command :name)
             (emc-get-command-keys-string :keys-pre)
             (emc-get-command-keys-string :keys-seq)
             (emc-get-command-keys-string :keys-post)
             (emc-get-command-keys-string :last-input)
             (emc-get-command-keys-string :keys))))

(defun emc-add-command-hooks ()
  "Add hooks used for saving the current command."
  (interactive)
  (add-hook 'pre-command-hook 'emc-begin-command-save t t)

  ;; this hook must run before evil-repeat post hook
  ;; which clears the command keys
  (add-hook 'post-command-hook 'emc-finish-command-save nil t)
  (advice-add 'read-key-sequence :before #'emc-save-key-sequence))

(defun emc-remove-command-hooks ()
  "Remove hooks used for saving the current command."
  (interactive)
  (remove-hook 'pre-command-hook 'emc-begin-command-save t)
  (remove-hook 'post-command-hook 'emc-finish-command-save t)
  (advice-remove 'read-key-sequence #'emc-save-key-sequence))

(provide'emc-command-info)

;;; emc-command-info.el ends here
