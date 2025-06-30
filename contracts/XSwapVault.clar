
;; XSwapVault

;; title: sBTC-HashPor
;; Cross-chain Atomic Swap Contract
;; Enables secure token swaps between different blockchain networks

(use-trait ft-trait .ft-trait.ft-trait)

;; Error codes
(define-constant ERROR-SWAP-EXPIRED (err u1))
(define-constant ERROR-SWAP-NOT-FOUND (err u2))
(define-constant ERROR-UNAUTHORIZED-ACCESS (err u3))
(define-constant ERROR-SWAP-ALREADY-FINALIZED (err u4))
(define-constant ERROR-INVALID-TOKEN-AMOUNT (err u5))
(define-constant ERROR-INSUFFICIENT-TOKEN-BALANCE (err u6))
(define-constant ERROR-INVALID-CONTRACT (err u7))
(define-constant ERROR-INVALID-HASH (err u8))
(define-constant ERROR-INVALID-BLOCKCHAIN (err u9))
(define-constant ERROR-INVALID-ADDRESS (err u10))

;; Constants for validation
(define-constant VALID-BLOCKCHAIN-LENGTH u8)
(define-constant VALID-ADDRESS-LENGTH u42)
(define-constant MIN-SWAP-DURATION u1)
(define-constant MAX-SWAP-DURATION u1440)
(define-constant HASH-LENGTH u32)
(define-constant MAX-UINT u340282366920938463463374607431768211455)

;; Data storage
(define-map atomic-swaps
  { atomic-swap-identifier: (buff 32) }
  {
    swap-initiator: principal,
    swap-participant: (optional principal),
    token-contract-principal: principal,
    token-amount: uint,
    atomic-hash-lock: (buff 32),
    swap-expiration-height: uint,
    swap-current-status: (string-ascii 20),
    destination-blockchain: (string-ascii 8),
    destination-wallet-address: (string-ascii 42)
  }
)

(define-data-var atomic-swap-counter uint u0)

;; Read-only functions
(define-read-only (get-atomic-swap-details (atomic-swap-identifier (buff 32)))
  (map-get? atomic-swaps { atomic-swap-identifier: atomic-swap-identifier })
)

(define-read-only (verify-hash-preimage (provided-preimage (buff 32)) (stored-hash (buff 32)))
  (is-eq (sha256 provided-preimage) stored-hash)
)

;; Validation functions with strict checks
(define-private (validate-token-contract (token-contract <ft-trait>))
  (let 
    (
      (contract-principal (contract-of token-contract))
    )
    (match (contract-call? token-contract get-name)
      success (ok contract-principal)
      error ERROR-INVALID-CONTRACT)))

(define-private (validate-hash-lock (hash-lock (buff 32)))
  (begin
    (asserts! (is-eq (len hash-lock) HASH-LENGTH) ERROR-INVALID-HASH)
    (asserts! (not (is-eq hash-lock 0x0000000000000000000000000000000000000000000000000000000000000000)) ERROR-INVALID-HASH)
    (ok hash-lock)))

(define-private (validate-blockchain-name (blockchain-name (string-ascii 8)))
  (begin
    (asserts! (and 
      (>= (len blockchain-name) u1) 
      (<= (len blockchain-name) VALID-BLOCKCHAIN-LENGTH)
    ) ERROR-INVALID-BLOCKCHAIN)
    ;; Convert index-of? result to boolean
    (asserts! (is-some (index-of (list "bitcoin" "ethereum" "stacks") blockchain-name)) ERROR-INVALID-BLOCKCHAIN)
    (ok blockchain-name)))


(define-private (validate-wallet-address (wallet-address (string-ascii 42)))
  (begin
    ;; First validate length
    (asserts! (and 
      (>= (len wallet-address) u1) 
      (<= (len wallet-address) VALID-ADDRESS-LENGTH)
    ) ERROR-INVALID-ADDRESS)

    ;; Check prefix using string-ascii 2 for comparison
    (let ((address-prefix (unwrap! (slice? wallet-address u0 u2) ERROR-INVALID-ADDRESS)))
      ;; Convert the prefix to string-ascii 2 for comparison
      (asserts! (is-some (index-of (list (string-ascii-to-2 "0x") 
                                        (string-ascii-to-2 "bc") 
                                        (string-ascii-to-2 "SP")) 
                                  (string-ascii-to-2 address-prefix))) 
               ERROR-INVALID-ADDRESS))

    (ok wallet-address)))

    ;; Helper function to convert string-ascii to string-ascii 2
(define-private (string-ascii-to-2 (s (string-ascii 42)))
  (unwrap-panic (slice? s u0 u2)))

(define-private (validate-token-amount (amount uint))
  (begin
    (asserts! (> amount u0) ERROR-INVALID-TOKEN-AMOUNT)
    (asserts! (<= amount MAX-UINT) ERROR-INVALID-TOKEN-AMOUNT)
    (ok amount)))

(define-private (validate-swap-duration (duration uint))
  (begin
    (asserts! (>= duration MIN-SWAP-DURATION) ERROR-INVALID-TOKEN-AMOUNT)
    (asserts! (<= duration MAX-SWAP-DURATION) ERROR-INVALID-TOKEN-AMOUNT)
    (ok duration)))

(define-private (validate-expiration-height (current-height uint) (duration uint))
  (begin
    (let ((expiration-height (+ current-height duration)))
      (asserts! (<= expiration-height MAX-UINT) ERROR-INVALID-TOKEN-AMOUNT)
      (ok expiration-height))))

;; Private helper function
(define-private (generate-atomic-swap-identifier)
  (sha256 (concat 
    (unwrap-panic (to-consensus-buff? (var-get atomic-swap-counter)))
    (unwrap-panic (to-consensus-buff? stacks-block-height))
  )))
