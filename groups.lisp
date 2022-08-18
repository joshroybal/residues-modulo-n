;;; Common Lisp group theory package
(defpackage :groups
  (:use :common-lisp)
  (:export :additive-group
           :multiplicative-group
	   :print-cayley-table
	   :report))
(in-package :groups)

(defun index (n)
  (do ((i (1- n) (1- i))
       (loc nil (cons i loc)))
      ((< i 0) loc)))

(defun enumerate (a b)
  (do ((i b (1- i))
       (loc nil (cons i loc)))
      ((< i a) loc)))

(defun order (group) (length (car group)))

;;; apply those SICP lectures on layers of abstraction
(defmacro operation-modulo-n (op n)
  "Macro constructs operation (e.g. * or +) modulo n."
  `(lambda (args) (mod (reduce #',op args) ,n)))
;; e.g.
;; (funcall (operation-modulo-n + 10) '(5 7)) => 2
;; (funcall (operation-modulo-n * 10) '(5 7)) => 5

;; (defun exponentiate (proc k ident n modulus)
;;   (if (zerop n)
;;       ident
;;       (mod
;;        (funcall proc k (exponentiate proc k ident (1- n) modulus))
;;        modulus)))
;;; e.g.
;;; (exponentiate #'+ 5 0 3 10) => 5
;;; (exponentiate #'* 2 1 10 10) => 4
(defun exponentiate (op x n)
  "Procedure implements exponentiation defined by group theory operation."
  (do ((i 1 (1+ i))
       (acc x (funcall op x acc)))
      ((equal i n) acc)))

(defun additive-group (n)
  "Procedure returns additive-group modulo n."
  (cons (index n) (operation-modulo-n + n)))

(defun divisors (n)
  "Procedure constructs list of divisors of n."
  (do ((k n (1- k))
       (loc nil (if (zerop (rem n k)) (cons k loc) loc)))
      ((zerop k) loc)))

;;; if this function returns nil then n is prime
(defun proper-divisors (n)
  "Procedure returns list of proper divisors of n."
  (butlast (cdr (divisors n))))

(defun coprime-p (x y)
  "Procedure predicate true when x and y are coprimes."
  (if (= (gcd x y) 1)
      t
      nil))

(defun residues (n)
  "Procedure returns list of co-primes of n."
  (do ((i n (1- i))
       (loc nil (if (coprime-p i n) (cons i loc) loc)))
      ((zerop i) loc)))

(defun multiplicative-group (n)
  "Procedure returns multiplicative group modulo n."
  (cons (residues n) (operation-modulo-n * n)))

;; (defun i-group ()
;;   "Procedure generates cyclic group generated by square root of -1."
;;   (do ((i 0 (1+ i))
;;        (loc nil (cons (expt (sqrt -1) i) loc)))
;;       ((and (> i 1) (equal (car loc) 1))
;;        (cons (butlast (reverse loc)) #'(lambda (x) (reduce #'* x))))))

(defun generate (element group)
  "Procedure generates subgroup generated by element of group."
  (let ((operation (cdr group)))
    (do ((loc
	  (list element)
	  (cons (funcall operation (list element (car loc))) loc)))
	((equal (car loc) (caar group)) (reverse loc)))))

(defun subgroups (group)
  "Function returns list of subgroups generated by elements of group."
  (do ((in (reverse (car group)) (cdr in))
       (out nil (cons (generate (car in) group) out)))
      ((null in) out)))

;; (defun distinct-subgroups (group)
;;   (remove-duplicates
;;    (mapcar #'(lambda (x) (sort x #'<)) (subgroups group))
;;    :test #'equalp))

(defun distinct-subgroups (group)
  "Function removes duplicate sets from list of subgroups of group."
  (remove-duplicates
   (subgroups group)
   :test #'(lambda (x y) (null (set-exclusive-or x y)))))

(defun associative-p (group)
  "Procedure predicate is true when group is Abelian."
  (let ((elements (car group)) (op (cdr group)))
    (dolist (a elements)
      (dolist (b elements)
	(when (not (equalp (funcall op (list a b)) (funcall op (list a b))))
	  (return-from associative-p nil))))
    t))

(defun cyclic-p (group)
  "Procedure predicate is true when group is cyclic."
  (progn
    (dolist (element (car group))
      (when (equal (length (generate element group)) (length (car group)))
	(return-from cyclic-p t)))
    nil))

;;; pretty print Cayley Table auxiliary procedures
(defun get-field-width (g)
  (let ((estrs (mapcar #'write-to-string (car g))))
    (1+ (reduce #'max (mapcar #'length estrs)))))

(defun numeric-format-string (field-width)
  (concatenate 'string "~" (write-to-string field-width) "d"))

(defun symbol-format-string (field-width)
  (concatenate 'string "~" (write-to-string field-width) "@a"))

(defun print-cayley-table (g str)
  "Procedure pretty-prints Cayley Table of group g, str is op symbol."
  (let* ((elements (car g))
	 (operation (cdr g))
	 (width (get-field-width g))
	 (dfmt (numeric-format-string width))
	 (afmt (symbol-format-string width)))
    (progn
      (format t "~%~%")
      (format t "~&Cayley Table")
      (format t "~&")
      (format t afmt str)
      (dolist (e elements)
	(format t dfmt e))
      (dolist (i elements)
	(progn
	  (format t "~&")
	  (format t dfmt i)
	  (dolist (j elements)
	    (format t dfmt (funcall operation (list i j))))))
      'done)))

(defun report (group symbol-string operation-string)
  "Procedure displays information about group."
  (let ((elements (car group))
	(order (order group)))
    (progn
      (format t "~&~a = ~S" symbol-string elements)
      (format t "~&|~a| = ~d" symbol-string order)
      ;;; print group Cayley Table
      (print-cayley-table group operation-string)
      ;;; determine whetner group is Abelian
      (format t "~%~%")
      (if (associative-p group)
	  (format t "~&~a is Abelian." symbol-string)
	  (format t "~&~a is not Abelian." symbol-string))
      ;;;determine whether group is cyclic
      (if (cyclic-p group)
	  (format t "~&~a is cyclic." symbol-string)
	  (format t "~&~a is not cyclic." symbol-string))
      ;;; generate subgroups
      (format t "~%~%")
      (format t "~&cyclic subgroups")
      (let ((sg (subgroups group)))
	(progn
	  (dolist (g sg)
	    (format t "~&<~d> = ~S" (car g) g))
	  (format t "~%~%")
	  (dolist (g sg)
	    (progn
	      (format t "~&|<~d>| = ~d" (car g) (length g))
	      ;; maybe add dfmt as in table later
	      (format t " ~a|~a|/|<~d>| = ~d"
		      #\tab symbol-string (car g) (/ order (length g)))
	      ))))
      (format t "~%~%")
      (format t "~&distict cyclic subgroups")
      (let ((dsg (distinct-subgroups group)))
	(progn
	  (dolist (sg dsg)
	    (format t "~&~S" sg))
	  (format t "~%~%")
	  (format t "~&no. of distinct subgroups = ~d" (length dsg))))
      (let ((d (divisors order)))
	(progn
	  (format t "~&divisors of |~a| = ~S" symbol-string d)
	  (format t "~&no. of divisors of |~a| = ~d" symbol-string (length d))))
      'done)))
