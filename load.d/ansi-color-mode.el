(defun ansi-color-apply-on-region-int (beg end)
  "interactive version of func"
  (interactive "r")
  (ansi-color-apply-on-region beg end))

(define-derived-mode fundamental-ansi-mode fundamental-mode "fundamental ansi"
  "Fundamental mode that understands ansi colors."
  (require 'ansi-color)
  (ansi-color-apply-on-region (point-min) (point-max))
  (when buffer-file-name
    (save-buffer))
  (read-only-mode))

(add-to-list 'auto-mode-alist '("\\.ansi_color\\'" . fundamental-ansi-mode))
