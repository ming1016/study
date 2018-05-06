;; The Yin Programming Language
;; bootstrapper #1


#lang typed/racket

(require/typed racket
               [string-split (String (U String Regexp) -> (Listof String))])

(require racket/pretty)

(provide (all-defined-out))


;; --------------- utilities ---------------
(define (abort who . args)
  (printf "~s: " who)
  (for-each display args)
  (display "\n")
  (error 'infer ""))


;; probs for debugging purposes
(define *debug* #t)
(define-syntax peek
  (syntax-rules ()
    [(_ args ...)
     (if *debug*
         (begin
           (printf "~s = ~s~n" 'args (unparse args))
           ...)
         (void))]))

(: flip ((Any Any -> Any) -> (Any Any -> Any)))
(define (flip f)
  (lambda (x y)
    (f y x)))

;; foldl of Racket has a strange flipped argument order
;; (yfoldl - 0 '(1 2 3 4))
(: yfoldl (All (a b) ((a b -> a) a (Listof b) -> a)))
(define (yfoldl f x ls)
  (cond
   [(null? ls) x]
   [else
    (yfoldl f (f x (first ls)) (rest ls))]))

;; more natural order of arguments for foldr
;; (yfoldr - '(1 2 3 4) 0)
(: yfoldr (All (a b) ((a b -> b) (Listof a) b -> b)))
(define (yfoldr f ls x)
  (cond
   [(null? ls) x]
   [else
    (f (first ls) (yfoldr f (rest ls) x))]))

(: start-with ((U String Symbol) Char -> Boolean))
(define (start-with s c)
  (cond
   [(symbol? s)
    (equal? c (string-ref (symbol->string s) 0))]
   [(string? s)
    (equal? c (string-ref s 0))]))

(: symbol-split (Symbol String -> (Listof Symbol)))
(define (symbol-split sym sep)
  (map string->symbol
       (string-split (symbol->string sym) sep)))

(: symbol-append (Symbol Symbol -> Symbol))
(define (symbol-append s1 s2)
  (string->symbol
   (string-append (symbol->string s1)
                  (symbol->string s2))))

(define (op? x)
  (memq x '(+ - * / < <= >= > = eq?)))


;; --------------- data structures ---------------
;; AST nodes

(define-type Node
  (U Const
     Sym
     Var
     Attr
     Fun
     App
     RecordDef
     VectorDef
     Def
     Import
     Assign
     Seq
     Return
     If
     Op))

(define-type Value
  (U Const
     Closure
     Record
     Vector
     Number
     Symbol
     String
     Boolean
     Node
     Void))

(struct: Const ([obj : (U Symbol Number String)])
         #:transparent)
(struct: Sym ([name : Symbol])
         #:transparent)
(struct: Var ([name : Symbol])
         #:transparent)
(struct: Attr ([value : Node]
               [attr : Var])
         #:transparent)
;; intermediate structure used for parsing Attr
(struct: SAttr ([value : Any]
                [attr : Any])
         #:transparent)
(struct: Fun ([param : Node]
              [body : Seq])
         #:transparent)
(struct: App ([fun : Node]
              [arg : Node])
         #:transparent)
(struct: RecordDef ([name : Node]
                    [fields : (Listof Node)])
         #:transparent)
(struct: VectorDef ([elems : (Listof Node)])
         #:transparent)
(struct: Def ([pattern : Node]
              [value : Node])
         #:transparent)
(struct: Import ([origin : Node]
                 [names : (Listof Var)])
         #:transparent)
(struct: Assign ([pattern : Node]
                 [value : Node])
         #:transparent)
(struct: Seq ([statements : (Listof Node)])
         #:transparent)
(struct: Return ([value : Node])
         #:transparent)
(struct: If ([test : Node]
             [then : Node]
             [else : Node])
         #:transparent)
(struct: Op ([op : Var]
             [e1 : Node]
             [e2 : Node])
         #:transparent)


;; interpreter's internal structures
(struct: Closure ([fun : FunValue]
                  [env : Env])
         #:transparent)
(struct: FunValue ([param : Value]
                   [body : Seq])
         #:transparent)
(struct: Record ([name : Node]
                 [fields : (Listof Node)]
                 [table : (HashTable Symbol Value)])
         #:transparent)
(struct: Vector ([elems : (Listof Value)])
         #:transparent)


;; --------------- parser and unparser ---------------
;; helper
(: def-form? (Any -> Boolean))
(define (def-form? x)
  (match x
    [(list ': _ _) #t]
    [other #f]))


;; preprocess and group attribute accesses
;; (f x).y => (SAttr (f x) y)
(: parse-attr (Any -> Any))
(define (parse-attr x)
  (cond
   [(symbol? x)
    (let ([segs (symbol-split x ".")])
      (yfoldl SAttr (first segs) (rest segs)))]
   [(null? x)
    '()]
   [(list? x)
    (let loop ([head (parse-attr (first x))]
               [tail (rest x)])
      (cond
       [(null? tail)
        (list head)]
       [(and (symbol? (first tail))
             (start-with (first tail) #\.))
        (let* ([segs (symbol-split (first tail) ".")]
               [head+ (yfoldl SAttr head segs)])
          (loop head+ (rest tail)))]
       [else
        (cons head
              (loop (parse-attr (first tail))
                    (rest tail)))]))]
   [else x]))


;; parse into record types
(: parse (Any -> Node))
(define (parse sexp)
  (let ([sexp (parse-attr sexp)])
    (match sexp
      [(? number? x) (Const x)]
      [(? string? x) (Const x)]
      [(? symbol? x)
       (Var x)]
      [(SAttr value (? symbol? attr))
       (Attr (parse value) (Var attr))]
      [`(quote ,(? symbol? x)) (Sym x)]
      [`(fun (,params ...) ,body ...)
       (Fun (parse `(rec ,@params)) (Seq (map parse body)))]
      [(list (? op? op) e1 e2)
       (Op (Var op) (parse e1) (parse e2))]
      [`(if ,test ,then ,else)
       (If (parse test) (parse then) (parse else))]
      [`(seq ,statements ...)
       (Seq (map parse statements))]
      [`(return ,value)
       (Return (parse value))]
      [`(: ,pattern ,value)
       (cond
        [(eq? pattern '_)
         (abort 'parse "_ is not allowed as a field name: " sexp)]
        [else
         (Def (parse pattern) (parse value))])]
      [`(<- ,pattern ,value)
       (Assign (parse pattern) (parse value))]
      [`(rec ,fields ...)
       (RecordDef (Var '_) (map parse fields))]
      [`(vec ,elems ...)
       (VectorDef (map parse elems))]
      [`(import ,origin (,(? symbol? names) ...))
       (Import (parse origin) (map Var (cast names (Listof Symbol))))]
      ;; application has no keywords, must stay last to avoid conflict
      [`(,f ,args ...)
       (cond
        [(andmap def-form? args)
         (App (parse f) (parse `(rec ,@args)))]
        [(andmap (negate def-form?) args)
         (App (parse f) (parse `(vec ,@args)))]
        [else
         (abort 'parse
                "application must either be all keyword args"
                " or all positional args, but got: " args)])]
      )))


;; unparse from records
(: unparse (Any -> Any))
(define (unparse t)
  (match t
    [(Const obj) obj]
    [(Var name) name]
    [(Attr value attr)
     `(attr ,(unparse value) ,(unparse attr))]
    [(Sym name) name]
    [(Fun x body)
     `(fun ,(unparse x) ,(unparse body))]
    [(App e1 e2)
     `(,(unparse e1) ,(unparse e2))]
    [(Op op e1 e2)
     `(,(unparse op) ,(unparse e1) ,(unparse e2))]
    [(RecordDef name fields)
     `(rec ,(unparse name) ,@(map unparse fields))]
    [(Record name fields table)
     (let ([fs (hash-map table
                         (lambda: ([k : Symbol] [v : Value])
                           `(: ,(unparse k) ,(unparse v))))])
       `(rec ,(unparse name) ,@fs))]
    [(VectorDef elems)
     `(vec ,@(map unparse elems))]
    [(Vector elems)
     `(vec ,@(map unparse elems))]
    [(Import origin names)
     `(import ,(unparse origin) ,(map unparse names))]
    [(Def pattern value)
     `(: ,(unparse pattern) ,(unparse value))]
    [(Assign pattern value)
     `(<- ,(unparse pattern) ,(unparse value))]
    [(Seq statements)
     (let ([sts (map unparse statements)])
       (cond
        [(= 1 (length sts))
         sts]
        [else
         `(seq ,@sts)]))]
    [(Return value)
     `(return ,(unparse value))]
    [(If test then else)
     `(if ,(unparse test) ,(unparse then) ,(unparse else))]
    [(Closure fun env)
     (unparse fun)]
    [other other]
    ))

;; (unparse (parse '((f 1).y 2)))


;; --------------- symbol table (environment) ---------------
;; environment is a linked list of hash tables
;; deliberately not using pure data structures
;; side effects make quite some things easier

(struct: Env ([table : (HashTable Symbol Value)]
              [parent : (Option Env)])
         #:transparent)

(: hash-none ( -> False))
(define hash-none (lambda () #f))

(define (empty-env) (Env (make-hasheq) #f))

(: env-extend (Env -> Env))
(define (env-extend env)
  (Env (make-hasheq) env))

(: env-put! (Env Symbol Value -> Void))
(define (env-put! env key value)
  (cond
   [(not (symbol? key))
    (abort 'lookup-local "only accept symbols, but got: " key)]
   [else
    (hash-set! (Env-table env) key value)]))

(: lookup-local (Symbol Env -> (Option Value)))
(define (lookup-local key env)
  (hash-ref (Env-table env) key hash-none))

(: lookup (Symbol Env -> (Option Value)))
(define (lookup key env)
  (let ([val (lookup-local key env)]
        [parent (Env-parent env)])
    (cond
     [val val]
     [parent
      (lookup key parent)]
     [else #f])))

(: find-defining-env (Symbol Env -> (Option Env)))
(define (find-defining-env key env)
  (let ([val (lookup-local key env)]
        [parent (Env-parent env)])
    (cond
     [val env]
     [parent
      (find-defining-env key parent)]
     [else #f])))

(define constants
  `(true false))

(define (env0) (empty-env))


;; ---------------- main interpreter -----------------
(: interp (Any -> Value))
(define (interp exp)
  (interp1 (parse exp) (env0)))


(: evaluate (Any -> Any))
(define (evaluate exp)
  (unparse (interp exp)))


(: interp1 (Node Env -> Value))
(define (interp1 exp env)
  (match exp
    [(Const obj) obj]
    [(Sym name) name]
    [(Var name)
     (cond
      [(memq name constants) name]
      [else
       (let ([val (lookup name env)])
         (cond
          [(not val)
           (abort 'interp "unbound variable: " name)]
          [else val]))])]
    [(Fun (? RecordDef? r) body)
     (Closure (FunValue (new-param r env) body) env)]
    [(App e1 e2)
     (let ([v1 (interp1 e1 env)]
           [v2 (interp1 e2 env)])
       (match v1
         [(Closure (FunValue pattern body) env1)
          (let ([env+ (env-extend env1)])
            (bind pattern v2 env+ 'param)
            (interp1 body env+))]))]
    [(Op op e1 e2)
     (let ([v1 (interp1 e1 env)]
           [v2 (interp1 e2 env)])
       (cond
        [(eq? (Var-name op) 'eq?)
         (eq? v1 v2)]
        [(and (real? v1) (real? v2))
         (case (Var-name op)
           [(+) (+ v1 v2)]
           [(-) (- v1 v2)]
           [(*) (* v1 v2)]
           [(/) (/ v1 v2)]
           [(>) (> v1 v2)]
           [(<) (< v1 v2)]
           [(>=) (>= v1 v2)]
           [(<=) (<= v1 v2)]
           [(=) (= v1 v2)]
           [else
            (abort 'interp "undefined operator on numbers: " op)])]
        [else
         (abort 'interp "can only operate on numbers, but got: " v1 "," v2)]))]
    [(If test then else)
     (let ([tv (interp1 test env)])
       (if tv
           (interp1 then env)
           (interp1 else env)))]
    [(Def pattern value)
     (let ([p (if (RecordDef? pattern)
                  (new-record pattern env #t)
                  pattern)]
           [v (interp1 value env)])
       (bind p v env 'def))]
    [(Assign lhs value)
     (let ([v (interp1 value env)])
       (match lhs
         [(Var x)
          (cond
           [(eq? x '_)
            (abort 'assign "wildcard can't be used in assignments")]
           [else
            (let ([env-def (find-defining-env x env)])
              (cond
               [env-def
                (env-put! env-def x v)]
               [else
                (abort 'assign
                       "lhs of assignment if not bound: "
                       (unparse lhs))]))])]
         [(Attr value attr)
          (let ([r (interp1 value env)])
            (cond
             [(Record? r)
              (record-set! r attr v)]
             [else
              (abort 'interp "trying to set fields of non-record: " r)]))]
         [(or (? VectorDef? lhs) (? RecordDef? lhs))
          (bind lhs (interp1 value env) env 'assign)]
         [other
          (abort 'interp "unable to assign to: " other)]))]
    [(Seq statements)
     (let loop ([statements statements])
       (let ([s0 (first statements)]
             [ss (rest statements)])
         (cond
          [(Return? s0)
           (interp1 (Return-value s0) env)]
          [(null? ss)
           (interp1 s0 env)]
          [else
           (interp1 s0 env)
           (loop ss)])))]
    [(? RecordDef? r)
     (new-record r env #f)]
    [(VectorDef elems)
     (let ([res (map (lambda: ([x : Node]) (interp1 x env)) elems)])
       (Vector res))]
    [(Attr value attr)
     (let ([r (interp1 value env)])
       (cond
        [(Record? r)
         (record-ref r attr)]
        [else
         (abort 'interp "trying to get fields of non-record: " r)]))]
    [(Import origin names)
     (let ([r (interp1 origin env)])
       (cond
        [(Record? r)
         (for ([name names])
           (env-put! env (Var-name name) (record-ref r name)))]
        [else
         (abort 'interp "trying to import from non-record: " r)]))]
    ))


(: record-ref (Record Var -> Value))
(define (record-ref record attr)
  (hash-ref (Record-table record) (Var-name attr)))

(: record-set! (Record Var Value -> Void))
(define (record-set! record attr value)
  (hash-set! (Record-table record) (Var-name attr) value))


;; general pattern binder
(: bind ((U Node Value) Value Env Symbol -> Void))
(define (bind v1 v2 env kind)
  (let ([kind2 (if (eq? kind 'param) 'def kind)])
    (match (list v1 v2)
      [(list (? RecordDef? r1) v2)
       (bind (new-record r1 env #t) v2 env kind)]
      ;; records
      [(list (Record name1 fields1 table1)
             (Record name2 fields2 table2))
       (hash-for-each table1
         (lambda: ([k1 : Symbol] [v1 : Value])
           (let ([v2 (hash-ref table2 k1 hash-none)])
             (cond
              [(and (eq? kind 'param) v2) ;; param binding
               (env-put! env k1 v2)]
              [(and (eq? kind 'param) v1) ;; default param
               (env-put! env k1 v1)]
              [v2 ;; non-param correspondence
               (bind v1 v2 env kind2)]
              [else
               (abort 'bind "unbound key in rhs: " k1)]))))]
      ;; vectors
      [(list (VectorDef names)
             (Vector values))
       (cond
        [(= (length names) (length values))
         (for ([name names]
               [value values])
           (bind name value env kind2))]
        [else
         (abort 'bind
                "incorrect number of arguments\n"
                " expected: " (length names)
                " got: " (length values))])]
      ;; positionally bind vector into record
      ;; necessary for positional arguments
      [(list (Record name fields table)
             (Vector elems))
       (cond
        [(= (length fields) (length elems))
         (for ([f fields]
               [value elems])
           (bind f value env kind2))]
        [else
         (abort 'bind
                "incorrect number of arguments\n"
                " expected: " (length fields)
                " got: " (length elems))])]
      ;; base case
      [(list (Def x y) v2)
       (bind x v2 env kind2)]
      [(list (Var x) v2)
       (cond
        [(eq? x '_) (void)] ;; non-binding wild cards
        [(eq? kind 'assign)
         (env-put! env x v2)]
        [(memq kind '(def param))
         (let ([existing (lookup-local x env)])
           (cond
            [existing
             (abort 'bind
                    "redefining: " x
                    " was defined as: " (unparse existing))]
            [else
             (env-put! env x v2)]))]
        [else
         (abort 'bind "illegal kind in bind: " kind)])])))


(: find-name (Node -> Var))
(define (find-name exp)
  (match exp
    [(? Var? vx) vx]
    [(Def (? Var? vx) value)
     vx]
    [other
     (abort 'find-name "only accepts Var and Def, but got: " exp)]))


(: new-record (RecordDef Env Boolean -> Record))
(define (new-record def env pattern?)
  (match def
    [(RecordDef name fields)
     (let: ([table : (HashTable Symbol Value) (make-hasheq)])
       (for ([f fields])
         (match f
           [(Def (Var x) value)
            (cond
             [pattern?
              (hash-set! table x value)]
             [else
              (hash-set! table x (interp1 value env))])]
           [other (void)]))
       (Record name fields table))]))


(: new-param (RecordDef Env -> Record))
(define (new-param def env)
  (match def
    [(RecordDef name fields)
     (let: ([table : (HashTable Symbol Value) (make-hasheq)])
       (for ([f fields])
         (match f
           [(Var x)
            (hash-set! table x #f)]
           [(Def (Var x) value)
            (hash-set! table x (interp1 value env))]
           [other (void)]))
       (Record name fields table))]))
