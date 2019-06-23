;; Copyright 2019 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define nulls (make-bytevector 512 0))
(define zeros (make-bytevector 12 (char->integer #\0)))

(define (tar-poke-string! header at nbyte string)
  (let* ((bytes (string->utf8 string))
         (nnull (- nbyte (bytevector-length bytes))))
    (when (< nnull 1) (error "tar: string too long"))
    (bytevector-copy! header at bytes)
    (bytevector-copy! header (+ at (bytevector-length bytes)) nulls 0 nnull)))

(define (tar-poke-octal! header at nbyte number)
  (unless (integer? number) (error "tar: not an integer"))
  (when (< number 0) (error "tar: negative integer"))
  (let* ((bytes (string->utf8 (number->string number 8)))
         (nzero (- nbyte 1 (bytevector-length bytes))))
    (when (< nzero 0) (error "tar: number too big"))
    (bytevector-copy! header at zeros 0 nzero)
    (bytevector-copy! header (+ at nzero) bytes)
    (bytevector-u8-set! header (+ at nbyte -1) 0)))

(define (tar-header-checksum header)
  (let ((n (bytevector-length header)))
    (let loop ((i 0) (sum 0))
      (if (= i n)
          (truncate-remainder sum (expt 8 6))
          (loop (+ i 1) (+ sum (bytevector-u8-ref header i)))))))

(define (tar-write-file fake-path bytes)
  (let* ((header (make-bytevector 512 0))
         (nbyte (bytevector-length bytes))
         (nnull (- 512 (truncate-remainder nbyte 512)))
         (unix-time-now 0))
    (tar-poke-string! header 0 100 fake-path)
    (tar-poke-octal! header 100 8 #o644)
    (tar-poke-octal! header 108 8 0)
    (tar-poke-octal! header 116 8 0)
    (tar-poke-octal! header 124 12 nbyte)
    (tar-poke-octal! header 136 12 unix-time-now)
    (bytevector-copy! header 148 (make-bytevector 8 (char->integer #\space)))
    (bytevector-u8-set! header 156 (char->integer #\0))
    (tar-poke-string! header 157 100 "")
    (tar-poke-string! header 257 8 "ustar  ")
    (tar-poke-string! header 265 32 "root")
    (tar-poke-string! header 297 32 "root")
    (tar-poke-octal! header 148 7 (tar-header-checksum header))
    (write-bytevector header)
    (write-bytevector bytes)
    (write-bytevector nulls (current-output-port) 0 nnull)))

(define (tar-write-end)
  (write-bytevector nulls)
  (write-bytevector nulls))
