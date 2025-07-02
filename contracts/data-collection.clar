;; Data Collection Contract
;; Handles secure collection and storage of customer behavior data

(define-constant err-unauthorized (err u200))
(define-constant err-invalid-data (err u201))
(define-constant err-data-exists (err u202))
(define-constant err-not-found (err u203))

(define-data-var next-data-id uint u1)

(define-map behavior-data
  { data-id: uint }
  {
    customer-hash: (buff 32),
    behavior-type: (string-ascii 30),
    timestamp: uint,
    data-hash: (buff 32),
    collector: principal,
    verified: bool
  }
)

(define-map customer-data-count
  { customer-hash: (buff 32) }
  { count: uint }
)

(define-public (collect-behavior-data
  (customer-hash (buff 32))
  (behavior-type (string-ascii 30))
  (data-hash (buff 32)))
  (let ((data-id (var-get next-data-id)))
    (asserts! (> (len behavior-type) u0) err-invalid-data)
    (asserts! (> (len data-hash) u0) err-invalid-data)

    (map-set behavior-data
      { data-id: data-id }
      {
        customer-hash: customer-hash,
        behavior-type: behavior-type,
        timestamp: block-height,
        data-hash: data-hash,
        collector: tx-sender,
        verified: false
      }
    )

    (match (map-get? customer-data-count { customer-hash: customer-hash })
      count-data
      (map-set customer-data-count
        { customer-hash: customer-hash }
        { count: (+ (get count count-data) u1) }
      )
      (map-set customer-data-count
        { customer-hash: customer-hash }
        { count: u1 }
      )
    )

    (var-set next-data-id (+ data-id u1))
    (ok data-id)
  )
)

(define-public (verify-data (data-id uint))
  (match (map-get? behavior-data { data-id: data-id })
    data-entry
    (begin
      (map-set behavior-data
        { data-id: data-id }
        (merge data-entry { verified: true })
      )
      (ok true)
    )
    err-not-found
  )
)

(define-read-only (get-behavior-data (data-id uint))
  (map-get? behavior-data { data-id: data-id })
)

(define-read-only (get-customer-data-count (customer-hash (buff 32)))
  (default-to { count: u0 } (map-get? customer-data-count { customer-hash: customer-hash }))
)

(define-read-only (get-total-data-points)
  (- (var-get next-data-id) u1)
)
