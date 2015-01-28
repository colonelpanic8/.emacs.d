;; -*- lexical-binding: t; -*-
;; =============================================================================
;;    ___ _ __ ___   __ _  ___ ___
;;   / _ \ '_ ` _ \ / _` |/ __/ __|
;;  |  __/ | | | | | (_| | (__\__ \
;; (_)___|_| |_| |_|\__,_|\___|___/
;; =============================================================================


(setq user-full-name
      (replace-regexp-in-string "\n$" "" (shell-command-to-string
                                          "git config --get user.name")))
(setq user-mail-address
      (replace-regexp-in-string "\n$" "" (shell-command-to-string
                                          "git config --get user.email")))

(defun emacs24_4-p ()
  (or (and (>= emacs-major-version 24)
           (>= emacs-minor-version 4))
      (>= emacs-major-version 25)))

;; =============================================================================
;;                                                                  GUI Disables
;; =============================================================================

 ;; Turn off mouse interface early in startup to avoid momentary display
(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; These silence the byte compiler.
(defvar ido-cur-item nil)
(defvar ido-default-item nil)
(defvar ido-context-switch-command nil)
(defvar ido-cur-list nil)
(defvar inherit-input-method nil)

;; =============================================================================
;;                                                         ELPA/package.el/MELPA
;; =============================================================================

(require 'package)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives '("elpa" . "http://tromey.com/elpa/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)

(defun ensure-packages-installed (packages)
  (unless package-archive-contents
    (package-refresh-contents))
  (mapcar
   (lambda (package)
     (if (package-installed-p package)
         package
       (progn (message (format "Installing package %s." package))
              (package-install package))))
   packages))

(package-initialize)
(ensure-packages-installed '(epl use-package))
(require 'use-package)

(use-package benchmark-init
  :ensure t
  ;; Set do-benchmark in custom.el
  :if (and (boundp 'do-benchmark) do-benchmark)) ;; This doesn't work
                                                 ;; anymore because
                                                 ;; custom.el is
                                                 ;; loaded much later

;; =============================================================================
;;                                                          Config Free Packages
;; =============================================================================

(defvar packages-eager
  '(popup auto-complete yasnippet cl-lib paradox
    xclip dired+ ctags ctags-update aggressive-indent imenu+ neotree diminish
    gist))

(ensure-packages-installed packages-eager)

;; =============================================================================
;;                                                                      Disables
;; =============================================================================

(setq visible-bell nil)
(setq sentence-end-double-space nil)

;; Disable the creation of backup files.
(setq backup-inhibited t)
(setq make-backup-files nil)
(setq auto-save-default nil)

(defconst emacs-tmp-dir
  (format "%s/%s%s/" temporary-file-directory "emacs" (user-uid)))
(setq backup-directory-alist `((".*" . ,emacs-tmp-dir)))
(setq auto-save-file-name-transforms `((".*" ,emacs-tmp-dir t)))
(setq auto-save-list-file-prefix emacs-tmp-dir)


(put 'set-goal-column 'disabled nil)
(auto-fill-mode -1)
(setq indent-tabs-mode nil)
(setq flyspell-issue-welcome-flag nil)

;; No hsplits. EVER.
(defun split-horizontally-for-temp-buffers () (split-window-horizontally))
(add-hook 'temp-buffer-setup-hook 'split-horizontally-for-temp-buffers)
(setq split-height-threshold nil)
(setq split-width-threshold 160)

;; No popup frames.
(setq ns-pop-up-frames nil)
(setq pop-up-frames nil)
(setq confirm-nonexistent-file-or-buffer nil)

;; No prompt for killing a buffer with processes attached.
(setq kill-buffer-query-functions
  (remq 'process-kill-buffer-query-function
        kill-buffer-query-functions))

(setq inhibit-startup-message t
      inhibit-startup-echo-area-message t)

(when (fboundp 'tooltip-mode) (tooltip-mode -1))
(setq tooltip-use-echo-area t)

(setq use-dialog-box nil)

(defadvice yes-or-no-p (around prevent-dialog activate)
  "Prevent yes-or-no-p from activating a dialog"
  (let ((use-dialog-box nil))
    ad-do-it))

(defadvice y-or-n-p (around prevent-dialog-yorn activate)
  "Prevent y-or-n-p from activating a dialog"
  (let ((use-dialog-box nil))
    ad-do-it))

;; =============================================================================
;;                                                                     functions
;; =============================================================================

(defun cmp-int-list (a b)
  (when (and a b)
    (cond ((> (car a) (car b)) 1)
          ((< (car a) (car b)) -1)
          (t (cmp-int-list (cdr a) (cdr b))))))

(defun get-date-created-from-agenda-entry (agenda-entry)
  (org-time-string-to-time
   (org-entry-get (get-text-property 1 'org-marker agenda-entry) "CREATED")))

(defun narrow-to-region-indirect (start end)
  "Restrict editing in this buffer to the current region, indirectly."
  (interactive "r")
  (deactivate-mark)
  (let ((buf (clone-indirect-buffer nil nil)))
    (with-current-buffer buf
      (narrow-to-region start end))
      (switch-to-buffer buf)))

(defmacro defvar-setq (name value)
  (if (boundp name)
      `(setq ,name ,value)
    `(defvar ,name ,value)))

(defun eval-region-or-last-sexp ()
  (interactive)
  (if (region-active-p) (call-interactively 'eval-region)
    (call-interactively 'eval-last-sexp)))

(defun undo-redo (&optional arg)
  (interactive "P")
  (if arg (undo-tree-redo) (undo-tree-undo)))

(defun up-list-region ()
  (interactive)
  (up-list) (set-mark-command nil) (backward-sexp))

(defun up-list-back ()
  (interactive)
  (up-list) (backward-sexp))

(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn
                 (barf-if-buffer-read-only)
                 (list t)))
  (let ((fill-column (point-max)))
    (fill-paragraph nil region)))

(defun fill-or-unfill-paragraph (&optional unfill region)
  "Fill paragraph (or REGION). With the prefix argument UNFILL,
unfill it instead."
    (interactive (progn
                   (barf-if-buffer-read-only)
                   (list (if current-prefix-arg 'unfill) t)))
    (let ((fill-column (if unfill (point-max) fill-column)))
      (fill-paragraph nil region)))

(defun sudo-edit (&optional arg)
  "Edit currently visited file as root.

With a prefix ARG prompt for a file to visit.
Will also prompt for a file to visit if current
buffer is not visiting a file."
  (interactive "P")
  (if (or arg (not buffer-file-name))
      (find-file (concat "/sudo:root@localhost:"
                         (ido-read-file-name "Find file (as root): ")))
    (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))

(defun frame-exists ()
  (cl-find-if
   (lambda (frame)
     (assoc 'display (frame-parameters frame))) (frame-list)))

(defun make-frame-if-none-exists ()
  (let* ((existing-frame (frame-exists)))
    (if existing-frame
        existing-frame
      (make-frame-on-display (getenv "DISPLAY")))))

(defun make-frame-if-none-exists-and-focus ()
  (make-frame-visible (select-frame (make-frame-if-none-exists))))

(defun os-copy (&optional b e)
  (interactive "r")
  (shell-command-on-region b e "source ~/.zshrc; cat | smart_copy"))

(defun os-paste ()
  (interactive)
  (insert (shell-command-to-string "source ~/.zshrc; ospaste")))

(defun all-copy (&optional b e)
  (interactive "r")
  (os-copy b e)
  (tmux-copy b e)
  (kill-ring-save b e))

(defun open-pdf ()
  (interactive)
  (let ( (pdf-file (replace-regexp-in-string
                    "\.tex$" ".pdf" buffer-file-name)))
    (shell-command (concat "open " pdf-file))))

(defun tmux-copy (&optional b e)
  (interactive "r")
  (shell-command-on-region b e "cat | tmux loadb -"))

(defun eval-and-replace ()
  (interactive)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
             (current-buffer))
    (error (message "Invalid expression")
           (insert (current-kill 0)))))

(defun flatten-imenu-index (index)
  (cl-mapcan
   (lambda (x)
     (if (listp (cdr x))
         (cl-mapcar (lambda (item)
                      `(,(concat (car x) "/" (car item)) . ,(cdr item)))
                    (flatten-imenu-index (cdr x)))
       (list x))) index))

(defun flatten-imenu-index-function (function)
  (lambda () (flatten-imenu-index (funcall function))))

(defun flatten-current-imenu-index-function ()
  (setq imenu-create-index-function
        (flatten-imenu-index-function imenu-create-index-function)))

(defun notification-center (title message)
  (flet ((encfn (s) (encode-coding-string s (keyboard-coding-system))))
    (shell-command
     (format "osascript -e 'display notification \"%s\" with title \"%s\"'"
             (encfn message) (encfn title)))))

(defun growl-notify (title message)
  (shell-command (format "grownotify -t %s -m %s" title message)))

(defun notify-send (title message)
  (shell-command (format "notify-send -u critical %s %s" title message)))

(defvar notify-function
  (cond ((eq system-type 'darwin) 'notification-center)
        ((eq system-type 'gnu/linux) 'notify-send)))

(defun project-root-of-file (filename)
  "Retrieves the root directory of a project if available.
The current directory is assumed to be the project's root otherwise."
  (file-truename
   (let ((dir (file-truename filename)))
     (or (--reduce-from
          (or acc
              (let* ((cache-key (format "%s-%s" it dir))
                     (cache-value (gethash cache-key
                                           projectile-project-root-cache)))
                (if cache-value
                    (if (eq cache-value 'no-project-root)
                        nil
                      cache-value)
                  (let ((value (funcall it dir)))
                    (puthash cache-key (or value 'no-project-root)
                             projectile-project-root-cache)
                    value))))
          nil
          projectile-project-root-files-functions)
         (if projectile-require-project-root
             (error "You're not in a project")
           default-directory)))))

;; =============================================================================
;;                                                       Load Path Configuration
;; =============================================================================

(defvar machine-custom "~/.emacs.d/this-machine.el")
(setq custom-file "~/.emacs.d/custom.el")
(when (file-exists-p custom-file) (load custom-file))
(when (file-exists-p machine-custom) (load machine-custom))

;; =============================================================================
;;                                                         General Emacs Options
;; =============================================================================

;; This makes it so that emacs --daemon puts its files in ~/.emacs.d/server
(setq server-use-tcp t)

;; Display line and column numbers in mode line.
(line-number-mode t)
(column-number-mode t)
(global-linum-mode t)
(setq visible-bell t)
(show-paren-mode 1)

;; Make buffer names unique.
(setq uniquify-buffer-name-style 'forward)

;; We want closures.nil
(setq lexical-binding t)

;; Don't disable downcase and upcase region.
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; Make forward word understand camel and snake case.
(setq c-subword-mode t)

;; Preserve pastes. Why wouldn't this be enabled by default.
(setq save-interprogram-paste-before-kill t)

(setq-default cursor-type 'box)
(setq-default cursor-in-non-selected-windows 'bar)

(add-hook 'after-init-hook '(lambda () (setq debug-on-error t)))

;; Make mouse scrolling less jumpy.
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))

(eval-after-load 'subword '(diminish 'subword-mode))
(eval-after-load 'simple '(diminish 'visual-line-mode))

(display-time-mode 1)
(setq reb-re-syntax 'string)

(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; =============================================================================
;;                                                                   use-package
;; =============================================================================

;; Set path from shell.
(use-package exec-path-from-shell
  :ensure t
  :config (exec-path-from-shell-initialize))

(use-package yasnippet
  :ensure t
  :commands (yas-global-mode)
  :idle (yas-global-mode)
  :config
  (progn
    (diminish 'yas-minor-mode)
    (setq yas-prompt-functions
          (cons 'yas-ido-prompt
                (cl-delete 'yas-ido-prompt yas-prompt-functions)))))

(use-package tramp
  :commands tramp
  :config
  (setq tramp-default-method "ssh"))

;; text mode stuff:
(remove-hook 'text-mode-hook #'turn-on-auto-fill)
(add-hook 'text-mode-hook 'turn-on-visual-line-mode)
(setq sentence-end-double-space nil)

;; y and n instead of yes and no
(defalias 'yes-or-no-p 'y-or-n-p)

(use-package discover-my-major :ensure t)

(use-package guide-key
  :ensure t
  :config
  (progn
    (setq guide-key/guide-key-sequence
          '("C-c" "C-c p" "C-x C-k" "C-x r" "C-h" "C-x c" "C-x"))
    (guide-key-mode 1)
    (diminish 'guide-key-mode)
    (setq guide-key/idle-delay 0.25)
    (setq guide-key/recursive-key-sequence-flag t)
    (setq guide-key/popup-window-position 'bottom)))

(use-package jump-char
  :bind (("C-;" . jump-char-forward))
  :ensure t)

(use-package ace-jump-mode
  :ensure t
  :commands (ace-jump-mode imalison:ace-jump-mode)
  :bind (("C-j" . imalison:ace-jump-mode))
  :init
  (progn
    (use-package ace-window
      :ensure t
      :config (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
      :bind ("C-c w" . ace-select-window)))
  :config
  (progn
    (setq ace-jump-mode-scope 'window)
    (defun imalison:ace-jump-mode (&optional prefix)
      (interactive "P")
      (let ((ace-jump-mode-scope (if prefix 'global 'window)))
        (ace-jump-mode 0)))))

(use-package flycheck
  :ensure t
  :config
  (progn (global-flycheck-mode))
  :diminish flycheck-mode)

(use-package haskell-mode
  :ensure t
  :commands haskell-mode
  :config
  (progn
    (add-hook 'haskell-mode-hook 'turn-on-haskell-indent)))

(use-package rainbow-delimiters
  :ensure t
  :commands rainbow-delimiters-mode
  :init
  (progn
    (add-hook 'prog-mode-hook (lambda () (rainbow-delimiters-mode t)))))

(use-package diff-hl :ensure t)

(use-package magit
  :ensure t
  :commands magit-status
  :bind (("C-x g" . magit-status))
  :config
  (progn
    (diminish 'magit-auto-revert-mode)
    (use-package magit-filenotify
      ;; Seems like OSX does not support filenotify.
      :disabled t
      :ensure t
      :if (emacs24_4-p)
      :config
      :init (add-hook 'magit-status-mode-hook 'magit-filenotify-mode))))

(use-package auto-complete
  :ensure t
  :commands auto-complete-mode
  :config
  (diminish 'auto-complete-mode)
  :init
  (add-hook 'prog-mode-hook (lambda () (auto-complete-mode t))))

(use-package company
  :ensure t
  :commands company-mode
  :bind (("C-\\" . company-complete))
  :config
  (progn
    (setq company-idle-delay .25)
    (global-company-mode)
    (diminish 'company-mode))
  :init
  (add-hook 'prog-mode-hook (lambda () (company-mode t))))

(use-package expand-region
  :ensure t
  :commands er/expand-region
  :config (setq expand-region-contract-fast-key "j")
  :bind (("C-c k" . er/expand-region)))

(use-package multiple-cursors
  :config
  (progn
    (use-package phi-search-mc
      :ensure t
      :config
      (phi-search-mc/setup-keys))
    (use-package mc-extras
      :ensure t
      :config
      (define-key mc/keymap (kbd "C-. =") 'mc/compare-chars)))
  :bind
   (("C-c m a" . mc/mark-all-like-this)
    ("C-c m m" . mc/mark-all-like-this-dwim)
    ("C-c m l" . mc/edit-lines)
    ("C-c m n" . mc/mark-next-like-this)
    ("C-c m p" . mc/mark-previous-like-this)
    ("C-c m s" . mc/mark-sgml-tag-pair)
    ("C-c m d" . mc/mark-all-like-this-in-defun)))

(use-package undo-tree
  :ensure t
  :bind (("C--" . undo-redo)
         ("C-c u" . undo-tree-visualize)
         ("C-c r" . undo-tree-redo))
  :config
  (diminish 'undo-tree-mode)
  :init
  (progn
    ;;(setq undo-tree-visualizer-diff t) ;; This causes performance problems
    (global-undo-tree-mode)
    (setq undo-tree-visualizer-timestamps t)))

(use-package smooth-scrolling
  :ensure t
  :init (require 'smooth-scrolling))

(use-package smooth-scroll
  :ensure t
  :init
  (progn
    (smooth-scroll-mode)
    (setq smooth-scroll/vscroll-step-size 8))
  :config
  (diminish 'smooth-scroll-mode))

(use-package string-inflection
  :ensure t
  :commands string-inflection-toggle
  :bind ("C-c l" . string-inflection-toggle))

(use-package load-dir
  :ensure t
  :config
  (progn
    (add-to-list 'load-dirs "~/.emacs.d/load.d")
    (defvar site-lisp "/usr/share/emacs24/site-lisp/")
    (when (file-exists-p site-lisp) (add-to-list 'load-dirs site-lisp))))

(use-package recentf
  ;; binding is in helm.
  :config
  (progn
    (recentf-mode 1)
    (setq recentf-max-menu-items 500)))

;; =============================================================================
;;                                                         Non-Programming Stuff
;; =============================================================================

(use-package helm-spotify
  :ensure t
  :commands helm-spotify)

(use-package edit-server
  :ensure t
  :commands edit-server-start
  :idle (edit-server-start)
  :config
  (progn
    (setq edit-server-new-frame nil)))

(use-package jabber
  :ensure t
  :commands jabber-connect
  :config
  (progn
    (setq jabber-alert-presence-hooks nil)
    (defun jabber-message-content-message (from buffer text)
      (when (or jabber-message-alert-same-buffer
                (not (memq (selected-window) (get-buffer-window-list buffer))))
        (if (jabber-muc-sender-p from)
            (format "%s: %s" (jabber-jid-resource from) text)
          (format "%s: %s" (jabber-jid-displayname from) text))))
    (setq jabber-alert-message-function 'jabber-message-content-message)))

(use-package htmlize :ensure t)

(use-package org
  :ensure org-plus-contrib
  :commands (org-mode org org-mobile-push org-mobile-pull org-agenda)
  :mode ("\\.org\\'" . org-mode)
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c n t" . org-insert-todo-heading)
         ("C-c n s" . org-insert-todo-subheading)
         ("C-c n h" . org-insert-habit)
         ("C-c n m" . org-make-habit)
         ("C-c n l" . org-store-link)
         ("C-c n i" . org-insert-link)
         ("C-c C-t" . org-todo)
         ("C-c C-S-t" . org-todo-force-notes))
  :config
  (progn
    (defadvice org-agenda-to-appt (before wickedcool activate)
      "Clear the appt-time-msg-list."
      (setq appt-time-msg-list nil))
    (appt-activate)
    (org-agenda-to-appt)
    (run-at-time "00:00" 60 'org-agenda-to-appt)
    (defun org-archive-if (condition-function)
      (if (funcall condition-function)
          (org-archive-subtree)))

    (defun org-archive-if-completed ()
      (interactive)
      (org-archive-if 'org-entry-is-done-p))

    (defun org-archive-completed-in-buffer ()
      (interactive)
      (org-map-entries 'org-archive-if-completed))

    (defun org-capture-make-todo-template (&optional content)
      (unless content (setq content "%?"))
      (with-temp-buffer
        (org-mode)
        (org-insert-heading)
        (insert content)
        (org-todo "TODO")
        (org-set-property "CREATED"
                          (with-temp-buffer
                            (org-insert-time-stamp
                             (org-current-effective-time) t t)))
        (remove-hook 'post-command-hook 'org-add-log-note)
        (org-add-log-note)
        (buffer-substring-no-properties (point-min) (point-max))))

    (defun org-todo-force-notes ()
      (interactive)
      (let ((org-todo-log-states
             (mapcar (lambda (state)
                       (list state 'note 'time))
                     (apply 'append org-todo-sets))))
        (cond ((eq major-mode 'org-mode)  (org-todo))
              ((eq major-mode 'org-agenda-mode) (org-agenda-todo)))))

    (defun org-make-habit ()
      (interactive)
      (org-set-property "STYLE" "habit"))

    (defun org-insert-habit ()
      (interactive)
      (org-insert-todo-heading nil)
      (org-make-habit))

    (defun org-todo-at-date (date)
      (interactive (list (org-time-string-to-time (org-read-date))))
      (flet ((org-current-effective-time (&rest r) date)
             (org-today (&rest r) (time-to-days date)))
        (cond ((eq major-mode 'org-mode) (org-todo))
              ((eq major-mode 'org-agenda-mode) (org-agenda-todo)))))

    (defun org-capture-make-linked-todo-template ()
      (org-capture-make-todo-template "%? %A"))

    (defun org-cmp-creation-times (a b)
      (let ((a-created (get-date-created-from-agenda-entry a))
            (b-created (get-date-created-from-agenda-entry b)))
        (cmp-int-list a-created b-created)))

    (defun org-agenda-done (&optional arg)
      "Mark current TODO as done.
This changes the line at point, all other lines in the agenda referring to
the same tree node, and the headline of the tree node in the Org-mode file."
      (interactive "P")
      (org-agenda-todo "DONE"))
    ;; Override the key definition for org-exit
    ;; (define-key org-agenda-mode-map "x" #'org-agenda-done) ;; TODO why does this cause an error

    ;; org-mode add-ons
    (use-package org-present :ensure t)
    (use-package org-pomodoro :ensure t)
    (use-package org-projectile
      :ensure t
      :demand t
      :bind (("C-c n p" . imalison:org-projectile:project-todo))
      :config
      (progn
        (defun imalison:org-projectile:project-todo (&optional arg)
          (interactive "P")
          (org-projectile:project-todo-completing-read
           (if arg (org-capture-make-linked-todo-template)
             (org-capture-make-todo-template))))))

    ;; variable configuration
    (add-to-list 'org-modules 'org-habit)
    (add-to-list 'org-modules 'org-expiry)
    (setq org-src-fontify-natively t)
    (setq org-habit-graph-column 50)
    (setq org-habit-show-habits-only-for-today t)
    (setq org-lowest-priority 69) ;; The character E
    (setq org-completion-use-ido t)
    (setq org-enforce-todo-dependencies t)
    (setq org-default-priority ?D)
    (setq org-agenda-skip-scheduled-if-done t)
    (setq org-agenda-skip-deadline-if-done t)
    ;;(add-to-list org-agenda-tag-filter-preset "+PRIORITY<\"C\"")

    ;; Agenda setup.
    (unless (boundp 'org-gtd-file)
      (defvar org-gtd-file "~/org/gtd.org"))
    (unless (boundp 'org-habits-file)
      (defvar org-habits-file "~/org/habits.org"))
    (unless (boundp 'org-calendar-file)
      (defvar org-calendar-file "~/org/calendar.org"))

    (unless (boundp 'org-capture-templates)
      (defvar org-capture-templates nil))
    (setq org-agenda-files
          (--filter (file-exists-p it)
                    (list org-gtd-file org-habits-file org-projectile:projects-file
                          org-calendar-file)))

    (add-to-list 'org-capture-templates
                 `("g" "GTD Todo" entry (file+headline ,org-gtd-file "Tasks")
                   (function org-capture-make-todo-template)))

    (add-to-list 'org-capture-templates
                 `("t" "Linked GTD Todo" entry (file+headline ,org-gtd-file "Tasks")
                   (function org-capture-make-linked-todo-template)))

    (add-to-list 'org-capture-templates
                 `("c" "Calendar entry" entry
                   (file+headline ,org-calendar-file "Personal")
                   "* %? %^T
  :PROPERTIES:
  :CREATED: %U
  :END:"))

    (add-to-list 'org-capture-templates
                 `("y" "Linked Calendar entry" entry
                   (file+headline ,org-calendar-file "Personal")
                   "* %? %A %^T
  :PROPERTIES:
  :CREATED: %U
  :END:"))

    (add-to-list 'org-capture-templates
                 `("h" "Habit" entry (file+headline ,org-habits-file "Habits")
                   "* TODO
  SCHEDULED: %^t
  :PROPERTIES:
  :CREATED: %U
  :STYLE: habit
  :END:"))

    (add-to-list 'org-capture-templates (org-projectile:project-todo-entry "p"))
    (add-to-list 'org-capture-templates
                 (org-projectile:project-todo-entry "l" "* TODO %? %a\n"))

    (let ((this-week-high-priority
           ;; The < in the following line works has behavior that is opposite
           ;; to what one might expect.
           '(tags-todo "+PRIORITY<\"C\"+DEADLINE<\"<+1w>\"DEADLINE>\"<+0d>\""
                       ((org-agenda-overriding-header
                         "Upcoming high priority tasks:"))))
          (due-today '(tags-todo
                           "+DEADLINE=<\"<+0d>\""
                           ((org-agenda-overriding-header
                             "Due today:"))))
          (recently-created '(tags-todo
                           "+CREATED=>\"<-3d>\""
                           ((org-agenda-overriding-header "Recently created:")
                            (org-agenda-cmp-user-defined 'org-cmp-creation-times)
                            (org-agenda-sorting-strategy '(user-defined-down)))))
          (missing-deadline
           '(tags-todo "-DEADLINE={.}/!"
                       ((org-agenda-overriding-header
                         "These don't have deadlines:"))))
          (missing-priority
           '(tags-todo "-PRIORITY={.}/!"
                       ((org-agenda-overriding-header
                         "These don't have priorities:")))))

      (setq org-agenda-custom-commands
            `(("M" "Main agenda view"
               (,due-today
                ,this-week-high-priority
                ,recently-created
                (agenda ""
                        ((org-agenda-overriding-header "Agenda:")
                         (org-agenda-ndays 5)
                         (org-deadline-warning-days 0)))
                ,missing-deadline
                ,missing-priority)
               nil nil)
              ,(cons "A" (cons "High priority upcoming" this-week-high-priority))
              ,(cons "d" (cons "Overdue tasks and due today" due-today))
              ,(cons "r" (cons "Recently created" recently-created))
	      ("h" "A, B priority:" tags-todo "+PRIORITY<\"C\""
                       ((org-agenda-overriding-header
                         "High Priority:")))
              ("c" "At least priority C:" tags-todo "+PRIORITY<\"D\""
                       ((org-agenda-overriding-header
                         "High Priority:"))))))

    ;; Record changes to todo states
    (setq org-log-into-drawer t)
    (setq org-todo-keywords
          '((sequence "TODO(t!)" "STARTED(s!)" "WAIT(w!)" "|"
                      "DONE(d!)" "CANCELED(c!)")))
    ;; Stop starting agenda from deleting frame setup!
    (setq org-agenda-window-setup 'other-window)
    (define-key mode-specific-map [?a] 'org-agenda)
    (unbind-key "C-j" org-mode-map))
  :init
  (progn
    ;; Automatically sync with mobile
    (defvar my-org-mobile-sync-timer nil)
    (defvar my-org-mobile-sync-secs 120)
    (defun my-org-mobile-sync-pull-and-push ()
      (org-mobile-pull)
      (org-mobile-push)
      (when (fboundp 'sauron-add-event)
        (sauron-add-event 'me 1 "Called org-mobile-pull and org-mobile-push")))
    (defun my-org-mobile-sync-start ()
      "Start automated `org-mobile-push'"
      (interactive)
      (setq my-org-mobile-sync-timer
            (run-with-idle-timer my-org-mobile-sync-secs t
                                 'my-org-mobile-sync-pull-and-push)))

    (defun my-org-mobile-sync-stop ()
      "Stop automated `org-mobile-push'"
      (interactive)
      (cancel-timer my-org-mobile-sync-timer))
    (if (and (boundp 'file-notify--library) file-notify--library)
        (use-package org-mobile-sync :ensure t :config (org-mobile-sync-mode 1))
      (my-org-mobile-sync-start))
    (setq org-directory "~/Dropbox/org")
    (setq org-mobile-inbox-for-pull "~/Dropbox/org/flagged.org")
    (setq org-mobile-directory "~/Dropbox/Apps/MobileOrg")
    (defun guide-key/my-hook-function-for-org-mode ()
      (guide-key/add-local-guide-key-sequence "C-c")
      (guide-key/add-local-guide-key-sequence "C-c C-x")
      (guide-key/add-local-highlight-command-regexp "org-"))
    (add-hook 'org-mode-hook 'guide-key/my-hook-function-for-org-mode)
    (defun disable-linum-mode () (linum-mode 0))
    (add-hook 'org-mode-hook 'disable-linum-mode)
    (add-hook 'org-agenda-mode-hook 'disable-linum-mode)))

(use-package epg
  :ensure t
  :config
  (epa-file-enable))

(use-package twittering-mode
  :ensure t
  :commands twittering-mode)

(use-package erc
  :ensure t
  :commands erc
  :config
  (progn
    ;; (add-to-list 'erc-modules 'notifications)
    (use-package erc-colorize :ensure t) (erc-colorize-mode 1)))

(use-package s :ensure t)
(add-to-list 'load-path (s-trim (shell-command-to-string "mu4e_directory")))

(use-package mu4e
  :commands (mu4e mu4e-view-message-with-msgid mu4e-update-index email)
  :bind ("C-c 0" . email)
  :config
  (progn
    (defun email ()
      (interactive)
      (persp-switch "email")
      (unless (mu4e-running-p)
        (mu4e)))
    ;; enable inline images
    (setq mu4e-view-show-images t)
    ;; show images
    (setq mu4e-show-images t)
    ;; Try to display html as text
    (setq mu4e-view-prefer-html nil)

    (setq mu4e-html2text-command "html2text -width 80 -nobs -utf8")

    ;; use imagemagick, if available
    (when (fboundp 'imagemagick-register-types)
         (imagemagick-register-types))
    (setq mail-user-agent 'mu4e-user-agent)
    (require 'org-mu4e)
    (setq mu4e-compose-complete-only-after nil)
    (setq mu4e-maildir "~/Mail")

    (setq mu4e-drafts-folder "/[Gmail].Drafts")
    (setq mu4e-sent-folder   "/[Gmail].Sent Mail")
    (setq mu4e-trash-folder  "/[Gmail].Trash")

    (setq mu4e-sent-messages-behavior 'delete)
    (setq mu4e-update-interval (* 60 20))
    (setq message-kill-buffer-on-exit t)
    (setq mail-user-agent 'mu4e-user-agent) ;; make mu4e the default mail client

    ;; don't save message to Sent Messages, Gmail/IMAP takes care of this
    (setq mu4e-sent-messages-behavior 'delete)

    ;; allow for updating mail using 'U' in the main view:
    (setq mu4e-get-mail-command "timeout 60 offlineimap")

    (add-hook 'mu4e-compose-mode-hook
              (defun my-do-compose-stuff () (flyspell-mode)))

    (add-to-list 'mu4e-headers-actions '("view in browser" . mu4e-action-view-in-browser))
    (add-to-list 'mu4e-view-actions '("view in browser" . mu4e-action-view-in-browser))

    (defun mu4e-view (msg headersbuf)
      "Display the message MSG in a new buffer, and keep in sync with HDRSBUF.
'In sync' here means that moving to the next/previous message in
the the message view affects HDRSBUF, as does marking etc.

As a side-effect, a message that is being viewed loses its 'unread'
marking if it still had that."
      (let* ((embedded ;; is it as an embedded msg (ie. message/rfc822 att)?
              (when (gethash (mu4e-message-field msg :path)
                             mu4e~path-parent-docid-map) t))
             (buf
              (if embedded
                  (mu4e~view-embedded-winbuf)
                (get-buffer-create mu4e~view-buffer-name))))
        ;; note: mu4e~view-mark-as-read will pseudo-recursively call mu4e-view again
        ;; by triggering mu4e~view again as it marks the message as read
        (with-current-buffer buf
          (switch-to-buffer buf)
          (setq mu4e~view-msg msg)
          (when (or (mu4e~view-mark-as-read msg) t) ;;(or embedded (not (mu4e~view-mark-as-read msg)))
            (let ((inhibit-read-only t))
              (erase-buffer)
              (mu4e~delete-all-overlays)
              (insert (mu4e-view-message-text msg))
              (goto-char (point-min))
              (mu4e~fontify-cited)
              (mu4e~fontify-signature)
              (mu4e~view-make-urls-clickable)
              (mu4e~view-show-images-maybe msg)
              (setq
               mu4e~view-buffer buf
               mu4e~view-headers-buffer headersbuf)
              (when embedded (local-set-key "q" 'kill-buffer-and-window))
              (mu4e-view-mode))))))

    (require 'smtpmail)

    ;; alternatively, for emacs-24 you can use:
    (setq message-send-mail-function 'smtpmail-send-it
          smtpmail-stream-type 'starttls
          smtpmail-default-smtp-server "smtp.gmail.com"
          smtpmail-smtp-server "smtp.gmail.com"
          smtpmail-smtp-service 587)))

(use-package gmail-message-mode :ensure t)

(use-package alert
  :ensure t
  :config
  (progn
    (defun alert-notifier-notify (info)
      (if alert-notifier-command
          (let ((args
                 (list "-title"   (alert-encode-string (plist-get info :title))
                       "-activate" "org.gnu.Emacs"
                       "-message" (alert-encode-string (plist-get info :message))
                       "-execute" (format "\"%s\"" (switch-to-buffer-command (plist-get info :buffer))))))
            (apply #'call-process alert-notifier-command nil nil nil args))
        (alert-message-notify info)))

    (defun switch-to-buffer-command (buffer-name)
      (emacsclient-command (format "(switch-to-buffer \\\"%s\\\")" buffer-name)))

    (defun emacsclient-command (command)
      (format "emacsclient --server-file='%s' -e '%s'" server-name command))

    (setq alert-default-style 'notifier)))

(use-package sauron
  :ensure t
  :defer t
  :commands (sauron-start sauron-start-hidden)
  :init
  (progn
    (when (eq system-type 'darwin)
      (setq sauron-modules '(sauron-erc sauron-org sauron-notifications
                                        sauron-twittering sauron-jabber sauron-identica))
      (defun sauron-dbus-start ()
        nil)
      (makunbound 'dbus-path-emacs)))
  :config
  (progn
    ;; This should really check (featurep 'dbus) but for some reason
    ;; this is always true even if support is not there.
    (setq sauron-prio-sauron-started 2)
    (setq sauron-min-priority 3)
    ;; (setq sauron-dbus-cookie t) ;; linux only?
    (setq sauron-separate-frame nil)
    (setq sauron-nick-insensitivity 1)
    (defun sauron:jabber-notify (origin priority message &optional properties)
      (funcall notify-function "gtalk" message))
    (defun sauron:erc-notify (origin priority message &optional properties)
      (let ((event (plist-get properties :event)))
        (funcall notify-function "IRC" message)))
    (defun sauron:mu4e-notify (origin priority message &optional properties)
      nil)
    (defun sauron:dbus-notify (origin priority message &optional properties)
      (funcall notify-function "GMail" message))
    (defun sauron:dispatch-notify (origin priority message &optional properties)
      (let ((handler (cond ((string= origin "erc") 'sauron:erc-notify)
                            ((string= origin "jabber") 'sauron:jabber-notify)
                            ((string= origin "mu4e") 'sauron:mu4e-notify)
                            ((string= origin "dbus") 'sauron:dbus-notify)
                            (t (lambda (&rest r) nil)))))
        (funcall handler origin priority message properties)))
    ;; Prefering alert.el for now ;; (add-hook 'sauron-event-added-functions 'sauron:dispatch-notify)
    (sauron-start-hidden)
    (add-hook 'sauron-event-added-functions 'sauron-alert-el-adapter))
  :idle (sauron-start-hidden)
  :idle-priority 3)

(use-package screenshot :ensure t)

(use-package flyspell
  :ensure t
  :config
  (progn
    (diminish 'flyspell-mode)
    (bind-key "M-s" 'flyspell-correct-word-before-point flyspell-mode-map)
    (unbind-key "C-;" flyspell-mode-map)
    (defun flyspell-emacs-popup-textual (event poss word)
      "A textual flyspell popup menu."
      (let* ((corrects (if flyspell-sort-corrections
                           (sort (car (cdr (cdr poss))) 'string<)
                         (car (cdr (cdr poss)))))
             (cor-menu (if (consp corrects)
                           (mapcar (lambda (correct)
                                     (list correct correct))
                                   corrects)
                         '()))
             (affix (car (cdr (cdr (cdr poss)))))
             show-affix-info
             (base-menu  (let ((save (if (and (consp affix) show-affix-info)
                                         (list
                                          (list (concat "Save affix: "
                                                        (car affix))
                                                'save)
                                          '("Accept (session)" session)
                                          '("Accept (buffer)" buffer))
                                       '(("Save word" save)
                                         ("Accept (session)" session)
                                         ("Accept (buffer)" buffer)))))
                           (if (consp cor-menu)
                               (append cor-menu (cons "" save))
                             save)))
             (menu (mapcar
                    (lambda (arg) (if (consp arg) (car arg) arg))
                    base-menu)))
        (cadr (assoc (popup-menu* menu :scroll-bar t) base-menu))))
    (fset 'flyspell-emacs-popup 'flyspell-emacs-popup-textual)))

;; =============================================================================
;;                                                        Programming Mode Hooks
;; =============================================================================

(add-hook 'prog-mode-hook (lambda () (auto-fill-mode -1)))
(add-hook 'prog-mode-hook (lambda () (subword-mode t) (diminish 'subword-mode)))
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

;; (add-hook 'prog-mode-hook (lambda () (highlight-lines-matching-regexp
;;                                  ".\\{81\\}" 'hi-blue)))

;; =============================================================================
;;                                          File Navigation: helm/projectile/ido
;; =============================================================================

(use-package helm-config
  :ensure helm
  :demand t
  :bind (("M-y" . helm-show-kill-ring)
         ("M-x" . helm-M-x)
         ("C-x C-i" . helm-imenu)
         ("C-h a" . helm-apropos)
         ("C-c C-h" . helm-org-agenda-files-headings)
         ("C-c ;" . helm-recentf))
  :init
  (progn
    (helm-mode 1)
    (use-package helm-ag :ensure t))
  :config
  (progn
    (cl-defun helm-org-headings-in-buffer ()
      (interactive)
      (helm :sources (helm-source-org-headings-for-files
                      (list (projectile-completing-read
                             "File to look at headings from: "
                             (projectile-all-project-files))))
            :candidate-number-limit 99999
            :buffer "*helm org inbuffer*"))
    ;; helm zsh source history
    (defvar helm-c-source-zsh-history
      '((name . "Zsh History")
        (candidates . helm-c-zsh-history-set-candidates)
        (action . (("Execute Command" . helm-c-zsh-history-action)))
        (volatile)
        (requires-pattern . 3)
        (delayed)))
    (defun helm-c-zsh-history-set-candidates (&optional request-prefix)
      (let ((pattern (replace-regexp-in-string
                      " " ".*"
                      (or (and request-prefix
                               (concat request-prefix
                                       " " helm-pattern))
                          helm-pattern))))
        (with-current-buffer (find-file-noselect "~/.zsh_history" t t)
          (auto-revert-mode -1)
          (goto-char (point-max))
          (loop for pos = (re-search-backward pattern nil t)
                while pos
                collect (replace-regexp-in-string
                         "\\`:.+?;" ""
                         (buffer-substring (line-beginning-position)
                                           (line-end-position)))))))

    (defun helm-c-zsh-history-action (candidate)
      (async-shell-command candidate))

    (defun helm-command-from-zsh ()
      (interactive)
      (require 'helm)
      (helm-other-buffer 'helm-c-source-zsh-history "*helm zsh history*"))

    (use-package helm-descbinds
      :demand t
      :config (helm-descbinds-mode 1)
      :ensure t)
    (helm-mode 1)
    (diminish 'helm-mode)))

(use-package helm-swoop
  :ensure t
  :bind ("C-S-s" . helm-swoop)
  :commands helm-swoop)

(use-package perspective
  :ensure t
  :demand t
  :config
  (progn
    (persp-mode)
    (defun persp-get-perspectives-for-buffer (buffer)
      "Get the names of all of the perspectives of which `buffer` is a member."
      (cl-loop for perspective being the hash-value of perspectives-hash
               if (member buffer (persp-buffers perspective))
               collect (persp-name perspective)))

    (defun persp-pick-perspective-by-buffer (buffer)
  "Select a buffer and go to the perspective to which that buffer
belongs. If the buffer belongs to more than one perspective
completion will be used to pick the perspective to switch to.
Switch the focus to the window in which said buffer is displayed
if such a window exists. Otherwise display the buffer in whatever
window is active in the perspective."
  (interactive (list (funcall persp-interactive-completion-function
                              "Buffer: " (mapcar 'buffer-name (buffer-list)))))
  (let* ((perspectives (persp-get-perspectives-for-buffer (get-buffer buffer)))
         (perspective (if (> (length perspectives) 1)
                          (funcall persp-interactive-completion-function
                                   (format "Select the perspective in which you would like to visit %s."
                                           buffer)
                                   perspectives)
                                   (car perspectives))))
    (if (string= (persp-name persp-curr) perspective)
        ;; This allows the opening of a single buffer in more than one window
        ;; in a single perspective.
        (switch-to-buffer buffer)
      (progn
          (persp-switch perspective)
          (if (get-buffer-window buffer)
              (set-frame-selected-window nil (get-buffer-window buffer))
            (switch-to-buffer buffer))))))

    (defun persp-mode-switch-buffers (arg)
      (interactive "P")
      (if arg (call-interactively 'ido-switch-buffer)
        (call-interactively 'persp-pick-perspective-by-buffer)))

    (define-key persp-mode-map (kbd "C-x b") 'persp-mode-switch-buffers))
  :bind ("C-c 9" . persp-switch))

(use-package projectile
  :ensure t
  :demand t
  :config
  (progn
    (defun do-ag (&optional arg)
      (interactive "P")
      (if arg (helm-do-ag) (helm-projectile-ag)))
    (projectile-global-mode)
    (setq projectile-enable-caching t)
    (setq projectile-completion-system 'helm)
    (helm-projectile-on)
    (diminish 'projectile-mode)
    (unbind-key "C-c p s a" projectile-command-map)
    (unbind-key "C-c p s g" projectile-command-map)
    (unbind-key "C-c p s s" projectile-command-map)
    (unbind-key "C-c p s" projectile-command-map)
    (bind-key* "C-c p s" 'do-ag))
  :bind (("C-x f" . projectile-find-file-in-known-projects))
  :init
  (progn
    (use-package persp-projectile
      :ensure t
      :commands projectile-persp-switch-project)
    (use-package helm-projectile
      :ensure t
      :commands (helm-projectile-on)
      :defer t)))

(use-package smex
  :ensure t
  ;; Using helm-M-x instead
  :disabled t
  :commands smex
  ;; This is here because smex feels like part of ido
  :bind ("M-x" . smex))

(use-package ido
  :ensure t
  :commands ido-mode
  :config
  (progn
    (setq ido-auto-merge-work-directories-length -1)
    (setq ido-create-new-buffer 'always)
    (ido-everywhere 1)
    (setq ido-enable-flex-matching t)
    (use-package flx :ensure t)
    (use-package flx-ido
      :commands flx-ido-mode
      :ensure t
      :init (flx-ido-mode 1)
      :config
      (progn
        ;; disable ido faces to see flx highlights.
        ;; This makes flx-ido much faster.
        (setq gc-cons-threshold 20000000)
        (setq ido-use-faces nil)))
    (use-package ido-ubiquitous
      :ensure t
      :disabled t
      :commands (ido-ubiquitous-mode))
    (use-package ido-vertical-mode
      :ensure t
      :config (ido-vertical-mode 1))
    (use-package flx-ido :ensure t)))

(if (and (boundp 'use-ido) use-ido) (ido-mode))

;; =============================================================================
;;                                                                         elisp
;; =============================================================================

(setq edebug-trace t)

(use-package macrostep :ensure t)

(use-package paredit
  :ensure t)

(use-package elisp-slime-nav
  :ensure t
  :commands elisp-slime-nav-mode
  :config
  (diminish 'elisp-slime-nav-mode)
  :init
  (add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t))))


(defun imenu-elisp-sections ()
  (setq imenu-prev-index-position-function nil)
  (setq imenu-space-replacement nil)
  (add-to-list 'imenu-generic-expression
               `("Package"
                 ,"(use-package \\(.+\\)$" 1))
  (add-to-list 'imenu-generic-expression
               `("Section"
                 ,(concat ";\\{1,4\\} =\\{10,80\\}\n;\\{1,4\\} \\{10,80\\}"
                          "\\(.+\\)$") 1) t))

(put 'use-package 'lisp-indent-function 1) ;; reduce indentation for use-package
(add-hook 'emacs-lisp-mode-hook 'imenu-elisp-sections)
(add-hook 'emacs-lisp-mode-hook 'flatten-current-imenu-index-function)
(add-hook 'emacs-lisp-mode-hook (lambda ()
                                  (setq indent-tabs-mode nil)
                                  (setq show-trailing-whitespace t)))
(bind-key "C-c C-f" 'find-function)
(bind-key "C-c C-v" 'find-variable)
(define-key lisp-mode-shared-map (kbd "C-c C-c") 'eval-defun)
(define-key lisp-mode-shared-map (kbd "C-c C-r") 'eval-and-replace)
(define-key lisp-mode-shared-map (kbd "C-c o r") 'up-list-region)
(define-key lisp-mode-shared-map (kbd "C-c o o") 'up-list-back)
(define-key lisp-mode-shared-map (kbd "C-x C-e") 'eval-region-or-last-sexp)
(unbind-key "C-j" lisp-interaction-mode-map)

;; =============================================================================
;;                                                                        Python
;; =============================================================================

(defvar use-python-tabs nil)

(defun python-tabs ()
  (setq tab-width 4 indent-tabs-mode t python-indent-offset 4))

(defun add-virtual-envs-to-jedi-server ()
  (let ((virtual-envs (get-virtual-envs)))
    (when virtual-envs (set (make-local-variable 'jedi:server-args)
                            (make-virtualenv-args virtual-envs)))))

(defun make-virtualenv-args (virtual-envs)
  (apply #'append (mapcar (lambda (env) `("-v" ,env)) virtual-envs)))

(defun get-virtual-envs ()
  (if (projectile-project-p)
      (condition-case ex
          (let ((project-root (projectile-project-root)))
            (cl-remove-if-not 'file-exists-p
                              (mapcar (lambda (env-suffix)
                                        (concat project-root env-suffix))
                                      '(".tox/py27/" "env" ".tox/venv/"))))
        ('error
         (message (format "Caught exception: [%s]" ex))
         (setq retval (cons 'exception (list ex))))
        nil)))

(defun message-virtual-envs ()
  (interactive)
          (message "%s" (get-virtual-envs)))

(use-package python
  :commands python-mode
  :mode ("\\.py\\'" . python-mode)
  :config
  (progn
    ;; macros
    (fset 'ipdb "import ipdb; ipdb.set_trace()")
    (fset 'main "if __name__ == '__main__':")
    (fset 'sphinx-class ":class:`~")
  :init
  (progn
    (use-package jedi
      :commands jedi:goto-definition
      :config
      (progn
        (setq jedi:complete-on-dot t)
        (setq jedi:install-imenu t)
        (setq jedi:imenu-create-index-function 'jedi:create-flat-imenu-index))
      :ensure t
      :bind (("M-." . jedi:goto-definition)
             ("M-," . jedi:goto-definition-pop-marker)))
    (use-package pytest
      :ensure t
      :bind ("C-c t" . pytest-one))
    (use-package pymacs :ensure t)
    (use-package sphinx-doc :ensure t)
    (defun imalison:python-mode ()
      (setq show-trailing-whitespace t)
      (if use-python-tabs (python-tabs))
      (subword-mode t)
      (jedi:setup)
      (add-virtual-envs-to-jedi-server)
      (remove-hook 'completion-at-point-functions
                   'python-completion-complete-at-point 'local))
    (add-hook 'python-mode-hook #'imalison:python-mode))))

;; =============================================================================
;;                                                                         Scala
;; =============================================================================

(use-package scala-mode2
  :config
  (progn
    (use-package ensime
      :ensure t
      :config
      (progn
        (add-hook 'scala-mode-hook 'ensime-scala-mode-hook)
        (defun guide-key/scala-mode-hook ()
          (guide-key/add-local-guide-key-sequence "C-c C-v"))
        (add-hook 'scala-mode-hook 'guide-key/scala-mode-hook)))
    (setq scala-indent:align-parameters t))
  :mode (("\\.scala\\'" . scala-mode)
         ("\\.sc\\'" . scala-mode))
  :ensure t)

;; =============================================================================
;;                                                                    JavaScript
;; =============================================================================

(use-package js2-mode
  :ensure t
  :commands (js-mode)
  :mode "\\.js\\'"
  :bind
  (("C-c b" . web-beautify-js))
  :init
  (progn
    (setq js2-bounce-indent-p t)
    (setq js2-basic-offset 2)
    (use-package skewer-mode
      :ensure t
      :commands skewer-mode)
    (add-hook 'js-mode-hook 'js2-minor-mode)
    (add-hook 'js2-mode-hook (lambda () (tern-mode t)))
    (add-hook 'js2-mode-hook 'skewer-mode)
    (add-hook 'js2-mode-hook (lambda () (setq js-indent-level 1)))
    (use-package tern
      :commands tern-mode
      :ensure t
      :config
      (progn (tern-ac-setup))
      :init
      (progn
        (use-package tern-auto-complete :ensure t
          :commands tern-ac-setup)))))

(use-package json-mode
  :ensure t
  :mode "\\.json\\'"
  :init
  (add-hook 'json-mode-hook
            (lambda ()
            (setq js-indent-level 2))))

(add-hook 'css-mode-hook #'skewer-css-mode)
(add-hook 'html-mode-hook #'skewer-html-mode)

(eval-after-load 'css-mode
  '(define-key css-mode-map (kbd "C-c b") 'web-beautify-css))

;; =============================================================================
;;                                                                          Ruby
;; =============================================================================

(use-package robe
  :ensure t
  :commands robe-mode
  :init
  (progn (add-hook 'ruby-mode-hook
                   (lambda () (robe-mode) (ac-robe-setup)
                     (auto-complete-mode)))))

(use-package rinari :ensure t)

;; =============================================================================
;;                                                                         C/C++
;; =============================================================================

(use-package helm-gtags
  :ensure t
  :config (custom-set-variables
           '(helm-gtags-path-style 'relative)
           '(helm-gtags-ignore-case t)
           '(helm-gtags-auto-update t))
  :bind
  (("M-t" . helm-gtags-find-tag)
   ("M-r" . helm-gtags-find-rtag)
   ("M-s" . helm-gtags-find-symbol)
   ("M-g M-p" . helm-gtags-parse-file)
   ("C-c <" . helm-gtags-previous-history)
   ("C-c >" . helm-gtags-next-history)
   ("M-," . helm-gtags-pop-stack))
  :init
  (progn
    ;;; Enable helm-gtags-mode
    (add-hook 'c-mode-hook 'helm-gtags-mode)
    (add-hook 'c++-mode-hook 'helm-gtags-mode)
    (add-hook 'asm-mode-hook 'helm-gtags-mode)))

;; =============================================================================
;;                                                                           TeX
;; =============================================================================

(defun guess-TeX-master (filename)
  "Guess the master file for FILENAME from currently open .tex files."
  (let ((candidate nil)
        (filename (file-name-nondirectory filename)))
    (save-excursion
      (dolist (buffer (buffer-list))
        (with-current-buffer buffer
          (let ((name (buffer-name))
                (file buffer-file-name))
            (if (and file (string-match "\\.tex$" file))
                (progn
                  (goto-char (point-min))
                  (if (re-search-forward (concat "\\\\input{" filename "}") nil t)
                      (setq candidate file))
                  (if (re-search-forward (concat "\\\\include{" (file-name-sans-extension filename) "}") nil t)
                      (setq candidate file))))))))
    (if candidate
        (message "TeX master document: %s" (file-name-nondirectory candidate)))
    candidate))

(defun set-TeX-master ()
    (setq TeX-master (guess-TeX-master (buffer-file-name))))

(use-package tex
  :ensure auctex
  :commands TeX-mode
  :config
  (progn
    (add-hook 'TeX-mode-hook 'set-TeX-master)
    (unbind-key "C-j" LaTeX-mode-map)
    (unbind-key "C-j" TeX-mode-map)
    (setq TeX-auto-save t)
    (setq TeX-parse-self t)
    (setq TeX-save-query nil)
    (setq TeX-PDF-mode t)
    (TeX-global-PDF-mode t)
    (setq-default TeX-master nil)))

;; =============================================================================
;;                                                                   other modes
;; =============================================================================

(use-package rust-mode :ensure t
  :mode (("\\.rs\\'" . rust-mode)))

(use-package yaml-mode :ensure t
  :mode (("\\.yaml\\'" . yaml-mode)
         ("\\.yml\\'" . yaml-mode)))

(use-package sgml-mode
  :ensure t
  :commands sgml-mode
  :bind ("C-c b" . web-beautify-html))

(use-package gitconfig-mode
  :ensure t
  :mode "\\.?gitconfig\\'")

(use-package evil :ensure t :commands (evil-mode))

;; =============================================================================
;;                                                           Custom Key Bindings
;; =============================================================================

;; Miscellaneous
(global-unset-key (kbd "C-o")) ;; Avoid collision with tmux binding.
(bind-key "M-q" 'fill-or-unfill-paragraph)
(bind-key "C-c C-s" 'sudo-edit)
(bind-key "C-c SPC"
          (lambda () (interactive)
            (if current-prefix-arg (helm-global-mark-ring) (helm-mark-ring))))
(bind-key "C-c e" 'os-copy)
(bind-key "C-x p" 'pop-to-mark-command)
(setq set-mark-command-repeat-pop t)
(bind-key "C-x C-b" 'buffer-menu)
(bind-key "C-x C-c" 'kill-emacs)
(bind-key "C-x C-i" 'imenu)
(bind-key "C-x C-r" (lambda () (interactive) (revert-buffer t t)))
(bind-key "C-x O" (lambda () (interactive) (other-window -1)))
(bind-key "C-x w" 'whitespace-mode)
(bind-key "M-g" 'goto-line)
(bind-key "M-n" 'forward-paragraph)
(bind-key "M-p" 'backward-paragraph)
(bind-key "M-z" 'zap-to-char)
(bind-key "C-M-<backspace>" 'backward-kill-sexp)
(bind-key "s-<return>" 'toggle-frame-fullscreen)

(fset 'global-set-key-to-use-package
      (lambda (&optional arg) "Keyboard macro." (interactive "p")
        (kmacro-exec-ring-item
         (quote ([1 67108896 19 100 6 23 40 19 41 return
                    backspace 32 46 6 4] 0 "%d")) arg)))

;; =============================================================================
;;                                                                          toys
;; =============================================================================

(use-package hackernews :ensure t :commands hackernews)

;; =============================================================================
;;                                                                    Appearance
;; =============================================================================

(defvar packages-appearance
  '(monokai-theme solarized-theme zenburn-theme base16-theme molokai-theme
    tango-2-theme gotham-theme sublime-themes ansi-color rainbow-delimiters
    ample-theme))

(ensure-packages-installed packages-appearance)


(use-package smart-mode-line
  :ensure t
  :config
  (progn
    (setq sml/theme 'respectful)
    (sml/setup)))

(setq inhibit-startup-screen t)
(blink-cursor-mode -1)

;; make whitespace-mode use just basic coloring
(setq whitespace-style (quote (spaces tabs newline space-mark
                                      tab-mark newline-mark)))
(setq whitespace-display-mappings
      '((space-mark 32 [183] [46])
        (tab-mark 9 [9655 9] [92 9])))

(defun colorize-compilation-buffer ()
  (read-only-mode)
  (ansi-color-apply-on-region (point-min) (point-max))
  (read-only-mode))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

;; =============================================================================
;;                                                                        Themes
;; =============================================================================

(unless (boundp 'dark-themes)
  (defvar dark-themes '(solarized-dark)))
(unless (boundp 'light-themes)
  (defvar light-themes '(solarized-light)))
(unless (boundp 'terminal-themes)
  (defvar terminal-themes '(solarized-light monokai)))
(unless (boundp 'fonts)
  (defvar fonts '(monaco-9)))
(unless (boundp 'current-theme) (defvar current-theme))
(setq current-theme nil)

(defun random-choice (choices)
  (nth (random (length choices)) choices))

(defun get-appropriate-theme ()
  (if t ;; (display-graphic-p) why doesn't this work at frame startup?
      (let ((hour
             (string-to-number (format-time-string "%H"))))
        (if (or (< hour 8) (> hour 16))
            (random-choice dark-themes) (random-choice light-themes)))
    (random-choice terminal-themes)))

(defun set-theme ()
  (interactive)
  (let ((appropriate-theme (get-appropriate-theme)))
        (if (eq appropriate-theme current-theme)
            nil
          (progn
            (disable-and-load-theme appropriate-theme t)
            (setq current-theme appropriate-theme)))))

(defun disable-all-themes ()
  (interactive)
  (mapcar
   (lambda (theme) (unless (s-contains? "smart-mode" (symbol-name theme))
                     (disable-theme theme))) custom-enabled-themes))

(defun disable-and-load-theme (theme &optional no-confirm no-enable)
  (interactive
   (list
    (intern (completing-read "Load custom theme: "
                             (mapcar 'symbol-name
                                     (custom-available-themes))))
    nil nil))
  (disable-all-themes)
  (load-theme theme no-confirm no-enable)
  (set-my-font-for-frame nil))

(defun set-my-font-for-frame (frame)
  (interactive (list nil))
  (condition-case exp
      (set-frame-font (random-choice fonts) nil t)
    ('error (package-refresh-contents)
            (set-frame-font "Monaco for Powerline-12" nil t) nil)))

(defun remove-fringe-and-hl-line-mode (&rest stuff)
  (if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
  (if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
  (set-fringe-mode 0)
  (setq linum-format 'dynamic)
  (setq left-margin-width 0)
  (setq hl-line-mode nil)
  (set-my-font-for-frame nil))

(if (emacs24_4-p)
    (advice-add 'load-theme :after #'remove-fringe-and-hl-line-mode)
  (defadvice load-theme (after name activate)
    (remove-fringe-and-hl-line-mode)))

;; enable to set theme based on time of day.
(run-at-time "00:00" 3600 'set-theme)

;; This is needed because you can't set the font at daemon start-up.
(add-hook 'after-make-frame-functions 'set-my-font-for-frame)
(add-hook 'after-make-frame-functions (lambda (frame) (set-theme)))
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)
