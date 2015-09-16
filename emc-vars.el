;;; emc-vars.el --- Settings and variables for emc

;;; Commentary:

;; This file contains all variables and settings used by emc

;;; Code:

(defface emc-cursor-default-face
  '((t (:background "#D13A82")))
  "The face used for simple fake cursors."
  :group 'emc)

(defface emc-region-face
  '((t :inherit region))
  "The face used for fake regions"
  :group 'emc)

(defcustom emc-cursor-overlay-priority 201
  "The priority of the fake cursors overlay."
  :type 'integer
  :group 'emc)

(defcustom emc-region-overlay-priority 99
  "The priority of the fake regions overlay."
  :type 'integer
  :group 'emc)

(evil-define-local-var emc-executing-command nil
  "True when executing a command for all cursors.")

(evil-define-local-var emc-recording-command nil
  "True when recording `this-command' data.")

(evil-define-local-var emc-cursor-command nil
  "True if the current command is an emc cursor command.")

(evil-define-local-var emc-cursor-current-face nil
  "The face to use when making fake cursors.")

(evil-define-local-var emc-cursor-list nil
  "The list of current fake cursors")

(evil-define-local-var emc-frozen nil
  "If true the fake cursors are frozen.")

(evil-define-local-var emc-pattern nil
  "The current pattern")

(evil-define-local-var emc-command nil
  "Data for the current command to be executed by the fake cursors.")

(evil-define-local-var emc-executing-debug nil
  "If true display debug messages during the execution of a command.")

(evil-define-local-var emc-recording-debug nil
  "If true display debug messages during the recording of a command.")

(defun emc-has-cursors-p ()
  "True if there are any fake cursors."
  (not (null emc-cursor-list)))

(defun emc-has-command-p ()
  "True if there is data saved for the current command."
  (not (null emc-command)))

(defun emc-has-pattern-p ()
  "True if there is a saved pattern."
  (not (null emc-pattern)))

(defun emc-executing-command-p ()
  "True when executing a command for all fake cursors."
  (eq emc-executing-command t))

(defun emc-recording-command-p ()
  "True when recording a command."
  (eq emc-recording-command t))

(defun emc-executing-debug-p ()
  "True if debugging is enabled during the execution of a command."
  (eq emc-executing-debug t))

(defun emc-recording-debug-p ()
  "True if debugging is enabled during the recording of a command."
  (eq emc-recording-debug t))

(defun emc-debug (state executing recording)
  "Enable debugging according to STATE for command EXECUTING or RECORDING or both."
  (when recording (setq emc-recording-debug state))
  (when executing (setq emc-executing-debug state)))

(defun emc-executing-debug-on ()
  "Turn debug on while executing a command."
  (interactive)
  (emc-debug t t nil))

(defun emc-executing-debug-off ()
  "Turn debug off while executing a command."
  (interactive)
  (emc-debug nil t nil))

(defun emc-recording-debug-on ()
  "Turn debug on while recording a command."
  (interactive)
  (emc-debug t nil t))

(defun emc-recording-debug-off ()
  "Turn debug off while recording a command."
  (interactive)
  (emc-debug nil nil t))

(defun emc-all-debug-on ()
  "Turn all debug on."
  (interactive)
  (emc-debug t t t))

(defun emc-all-debug-off ()
  "Turn all debug off."
  (interactive)
  (emc-debug nil t t))

(defun emc-print-pattern ()
  "Print the curent pattern."
  (interactive)
  (message "%s" emc-pattern))

(defun emc-print-cursor-list ()
  "Return the cursor list."
  (interactive)
  (if emc-cursor-list
      (message "%s: %s" (length emc-cursor-list) emc-cursor-list)
    (message "No cursors found")))

(defun emc-print-command ()
  "Print the information saved for the current command."
  (interactive)
  (message "%s" emc-command))

(defun emc-frozen-p ()
  "True if the fake cursors are frozen."
  (eq emc-frozen t))

(defun emc-stop-cursors ()
  "Freeze the fake cursors."
  (interactive)
  (setq emc-frozen t))

(defun emc-thaw-cursors ()
  "Unfreeze the fake cursors."
  (interactive)
  (setq emc-frozen nil))

(defun emc-clear-pattern ()
  "Clear the currently saved pattern."
  (setq emc-pattern nil))

(defun emc-clear-cursors ()
  "Clear the cursor list."
  (setq emc-cursor-list nil))

(defun emc-get-pattern ()
  "Return the current pattern."
  (when emc-pattern (car emc-pattern)))

(defun emc-get-pattern-text ()
  "Return the current pattern text."
  (when emc-pattern (car (emc-get-pattern))))

(defun emc-get-pattern-start ()
  "Return the current pattern start position."
  (when emc-pattern (nth 1 emc-pattern)))

(defun emc-get-pattern-end ()
  "Return the current pattern end position."
  (when emc-pattern (nth 2 emc-pattern)))

(defun emc-get-pattern-length ()
  "Return the current pattern length."
  (when emc-pattern
    (- (emc-get-pattern-end) (emc-get-pattern-start))))

(provide'emc-vars)

;;; emc-vars.el ends here