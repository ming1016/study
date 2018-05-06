(defvar yin-mode-syntax-table
  (let ((st (make-syntax-table))
	(i 0))
    ;; Symbol constituents
    ;; We used to treat chars 128-256 as symbol-constituent, but they
    ;; should be valid word constituents (Bug#8843).  Note that valid
    ;; identifier characters are Yin-implementation dependent.
    (while (< i ?0)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    (setq i (1+ ?9))
    (while (< i ?A)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    (setq i (1+ ?Z))
    (while (< i ?a)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))
    (setq i (1+ ?z))
    (while (< i 128)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))

    ;; Whitespace
    (modify-syntax-entry ?\t "    " st)
    (modify-syntax-entry ?\f "    " st)
    (modify-syntax-entry ?\r "    " st)
    (modify-syntax-entry ?\s "    " st)

    ;; Brackets and braces balance for editing convenience.
    (modify-syntax-entry ?\[ "(]  " st)
    (modify-syntax-entry ?\] ")[  " st)
    (modify-syntax-entry ?{ "(}  " st)
    (modify-syntax-entry ?} "){  " st)
    (modify-syntax-entry ?\| "\" 23bn" st)
    (modify-syntax-entry ?\( "()  " st)
    (modify-syntax-entry ?\) ")(  " st)

    ;; It's used for single-line comments as well as for #;(...) sexp-comments.
    (modify-syntax-entry ?- ". 12b" st)
    (modify-syntax-entry ?\n "> b" st)

    (modify-syntax-entry ?\" "\"   " st)
    (modify-syntax-entry ?' "'   " st)
    (modify-syntax-entry ?` "'   " st)

    ;; Special characters
    (modify-syntax-entry ?, "'   " st)
    (modify-syntax-entry ?@ "'   " st)
    (modify-syntax-entry ?# "'   " st)
    (modify-syntax-entry ?\\ "\\   " st)
    st))

(defvar yin-mode-abbrev-table nil)
(define-abbrev-table 'yin-mode-abbrev-table ())

(defvar yin-imenu-generic-expression
      '((nil
	 "^(define\\(\\|-\\(generic\\(\\|-procedure\\)\\|method\\)\\)*\\s-+(?\\(\\sw+\\)" 4)
	("Types"
	 "^(define-class\\s-+(?\\(\\sw+\\)" 1)
	("Macros"
	 "^(\\(defmacro\\|define-macro\\|define-syntax\\)\\s-+(?\\(\\sw+\\)" 2))
  "Imenu generic expression for Yin mode.  See `imenu-generic-expression'.")


(defvar yin-mode-line-process "")

(defvar yin-mode-map
  (let ((smap (make-sparse-keymap))
        (map (make-sparse-keymap "Yin")))
    (set-keymap-parent smap lisp-mode-shared-map)
    (define-key smap [menu-bar yin] (cons "Yin" map))
    (define-key map [run-yin] '("Run Inferior Yin" . run-yin))
    (define-key map [uncomment-region]
      '("Uncomment Out Region" . (lambda (beg end)
                                   (interactive "r")
                                   (comment-region beg end '(4)))))
    (define-key map [comment-region] '("Comment Out Region" . comment-region))
    (define-key map [indent-region] '("Indent Region" . indent-region))
    (define-key map [indent-line] '("Indent Line" . lisp-indent-line))
    (put 'comment-region 'menu-enable 'mark-active)
    (put 'uncomment-region 'menu-enable 'mark-active)
    (put 'indent-region 'menu-enable 'mark-active)
    smap)
  "Keymap for Yin mode.
All commands in `lisp-mode-shared-map' are inherited by this map.")


;; define several class of keywords
(setq yin-keywords '("define" "fun" "if" "set!" "declare" "record" "seq" "U"))
(setq yin-types '("Int" "Float" "Bool" "String"))
(setq yin-constants '("true" "false"))
(setq yin-functions '("map" "and" "or" "not"))

;; create the regex string for each class of keywords
(setq yin-keywords-regexp (regexp-opt yin-keywords 'words))
(setq yin-type-regexp (regexp-opt yin-types 'words))
(setq yin-constant-regexp (regexp-opt yin-constants 'words))
(setq yin-functions-regexp (regexp-opt yin-functions 'words))

(setq yin-font-lock-keywords
  `((,yin-type-regexp . font-lock-type-face)
    (,yin-constant-regexp . font-lock-constant-face)
    (,yin-functions-regexp . font-lock-function-name-face)
    ("\\<:\\sw+\\>" . font-lock-builtin-face)
    (,yin-keywords-regexp . font-lock-keyword-face)    ;; must be last
))


(defun yin-mode-variables ()
  (set-syntax-table yin-mode-syntax-table)
  (setq local-abbrev-table yin-mode-abbrev-table)
  (set (make-local-variable 'paragraph-start) (concat "$\\|" page-delimiter))
  (set (make-local-variable 'paragraph-separate) paragraph-start)
  (set (make-local-variable 'paragraph-ignore-fill-prefix) t)
  (set (make-local-variable 'fill-paragraph-function) 'lisp-fill-paragraph)
  (set (make-local-variable 'adaptive-fill-mode) nil)
  (set (make-local-variable 'indent-line-function) 'lisp-indent-line)
  (set (make-local-variable 'comment-start) "-- ")
  (set (make-local-variable 'comment-column) 40)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'lisp-indent-function) 'yin-indent-function)
  (setq mode-line-process '("" yin-mode-line-process))
  (set (make-local-variable 'imenu-case-fold-search) t)
  (setq imenu-generic-expression yin-imenu-generic-expression)
  (set (make-local-variable 'imenu-syntax-alist)
       '(("+/.<>=?!$%_&~^:" . "w")))
  (set (make-local-variable 'font-lock-defaults)
       '((yin-font-lock-keywords)
         nil t (("+/.<>=!?$%_&~^:" . "w")))))


(define-derived-mode yin-mode prog-mode "Yin"
  (yin-mode-variables))


(defgroup yin nil
  "Editing Yin code."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'lisp)


(defcustom yin-mode-hook nil
  "Normal hook run when entering `yin-mode'.
See `run-hooks'."
  :type 'hook
  :group 'yin)


(defcustom yin-program-name "yin"
  "Program invoked by the `run-yin' command."
  :type 'string
  :group 'yin)


(defvar calculate-lisp-indent-last-sexp)

;; FIXME this duplicates almost all of lisp-indent-function.
;; Extract common code to a subroutine.
(defun yin-indent-function (indent-point state)
  "Yin mode function for the value of the variable `lisp-indent-function'.
This behaves like the function `lisp-indent-function', except that:

i) it checks for a non-nil value of the property `yin-indent-function'
\(or the deprecated `yin-indent-hook'), rather than `lisp-indent-function'.

ii) if that property specifies a function, it is called with three
arguments (not two), the third argument being the default (i.e., current)
indentation."
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (if (and (elt state 2)
             (not (looking-at "\\sw\\|\\s_")))
        ;; car of form doesn't seem to be a symbol
        (progn
          (if (not (> (save-excursion (forward-line 1) (point))
                      calculate-lisp-indent-last-sexp))
              (progn (goto-char calculate-lisp-indent-last-sexp)
                     (beginning-of-line)
                     (parse-partial-sexp (point)
					 calculate-lisp-indent-last-sexp 0 t)))
          ;; Indent under the list or under the first sexp on the same
          ;; line as calculate-lisp-indent-last-sexp.  Note that first
          ;; thing on that line has to be complete sexp since we are
          ;; inside the innermost containing sexp.
          (backward-prefix-chars)
          (current-column))
      (let ((function (buffer-substring (point)
					(progn (forward-sexp 1) (point))))
	    method)
	(setq method (or (get (intern-soft function) 'yin-indent-function)
			 (get (intern-soft function) 'yin-indent-hook)))
	(cond ((or (eq method 'defun)
		   (and (null method)
			(> (length function) 3)
			(string-match "\\`def" function)))
	       (lisp-indent-defform state indent-point))
	      ((integerp method)
	       (lisp-indent-specform method state
				     indent-point normal-indent))
	      (method
		(funcall method state indent-point normal-indent)))))))


;;; Let is different in Yin
(defun would-be-symbol (string)
  (not (string-equal (substring string 0 1) "(")))

(defun next-sexp-as-string ()
  ;; Assumes that it is protected by a save-excursion
  (forward-sexp 1)
  (let ((the-end (point)))
    (backward-sexp 1)
    (buffer-substring (point) the-end)))

(defun yin-let-indent (state indent-point normal-indent)
  (skip-chars-forward " \t")
  (if (looking-at "[-a-zA-Z0-9+*/?!@$%^&_:~]")
      (lisp-indent-specform 2 state indent-point normal-indent)
    (lisp-indent-specform 1 state indent-point normal-indent)))

;; (put 'begin 'yin-indent-function 0), say, causes begin to be indented
;; like defun if the first form is placed on the next line, otherwise
;; it is indented like any other form (i.e. forms line up under first).

(put 'begin 'yin-indent-function 0)
(put 'lambda 'yin-indent-function 1)
(put 'let 'yin-indent-function 'yin-let-indent)

(provide 'yin-mode)
