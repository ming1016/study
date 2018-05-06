;; command to comment/uncomment text
(defun yin-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For detail, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((comment-start "--")
        (comment-end ""))
    (comment-dwim arg)))

;; syntax table
(defvar yin-syntax-table nil "Syntax table for `yin-mode'.")
(setq yin-syntax-table
      (let ((st (make-syntax-table)))

        ;; haskell-style comment --comment
        (modify-syntax-entry ?- ". 12b" st)
        (modify-syntax-entry ?\n "> b" st)
        st))


;; define several class of keywords
(setq yin-keywords '("define" "fun" "if" "set!" "assert" "record"))
(setq yin-types '("Int" "Float" "Bool"))
(setq yin-constants '("true" "false"))
(setq yin-functions '("map" "and" "or" "not"))

;; create the regex string for each class of keywords
(setq yin-keywords-regexp (regexp-opt yin-keywords 'words))
(setq yin-type-regexp (regexp-opt yin-types 'words))
(setq yin-constant-regexp (regexp-opt yin-constants 'words))
(setq yin-functions-regexp (regexp-opt yin-functions 'words))


;; clear memory
(setq yin-keywords nil)
(setq yin-types nil)
(setq yin-constants nil)
(setq yin-functions nil)

;; create the list for font-lock.
;; each class of keyword is given a particular face
(setq yin-font-lock-keywords
  `(
    (,yin-type-regexp . font-lock-type-face)
    (,yin-constant-regexp . font-lock-constant-face)
    (,yin-functions-regexp . font-lock-function-name-face)
    (,yin-keywords-regexp . font-lock-keyword-face)
    ;; note: order above matters. “yin-keywords-regexp” goes last because
    ;; otherwise the keyword “state” in the function “state_entry”
    ;; would be highlighted.
))




;; define the major mode.
(define-derived-mode yin-mode scheme-mode
  "yin-mode is a major mode for the Yin language."
  :syntax-table yin-syntax-table

  (setq mode-name "yin")

  ;; modify the keymap
  (define-key yin-mode-map [remap comment-dwim] 'yin-comment-dwim)

;; code for syntax highlighting
  (setq font-lock-defaults '((yin-font-lock-keywords)))

  ;; clear memory
  (setq yin-keywords-regexp nil)
  (setq yin-types-regexp nil)
  (setq yin-constants-regexp nil)
  (setq yin-functions-regexp nil)
)


(provide 'yin-mode)
