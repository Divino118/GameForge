;; GameForge Smart Contract 
;; Description: Gaming Currency Exchange

;; Constants
(define-constant platform-master tx-sender)
(define-constant error-access-violation (err u100))
(define-constant error-gamer-not-registered (err u101))
(define-constant error-insufficient-game-coins (err u102))
(define-constant error-invalid-coin-amount (err u103))
(define-constant error-coin-exchange-failed (err u104))
(define-constant error-operation-not-allowed (err u105))
(define-constant error-invalid-conversion-rate (err u106))
(define-constant error-gamer-already-registered (err u107))
(define-constant error-invalid-player-data (err u108))
(define-constant error-exchange-maintenance (err u109))

;; State Variables
(define-data-var coin-conversion-rate uint u0)
(define-data-var exchange-fee-basis-points uint u150) ;; 1.5% exchange fee, expressed in basis points
(define-data-var maintenance-mode-status bool false) ;; Emergency maintenance functionality

;; Mappings
(define-map gaming-coin-wallets principal uint)
(define-map player-profiles 
  principal 
  { gamer-tag: (string-ascii 55), 
    player-id: (string-ascii 22) })
(define-map rate-moderators principal bool)

;; Read-only Queries
(define-read-only (get-coin-wallet-balance (gamer principal))
  (default-to u0 (map-get? gaming-coin-wallets gamer)))

(define-read-only (get-player-profile (gamer principal))
  (map-get? player-profiles gamer))

(define-read-only (get-current-conversion-rate)
  (ok (var-get coin-conversion-rate)))

(define-read-only (is-rate-moderator (gamer principal))
  (default-to false (map-get? rate-moderators gamer)))

(define-read-only (is-exchange-in-maintenance)
  (var-get maintenance-mode-status))

;; Private Validation Methods
(define-private (validate-gamer-tag (tag (string-ascii 55)))
  (and (> (len tag) u0) (<= (len tag) u55)))

(define-private (validate-player-id (identifier (string-ascii 22)))
  (and (> (len identifier) u0) (<= (len identifier) u22)))

;; Public Methods
(define-public (create-player-profile (gamer-tag (string-ascii 55)) (player-id (string-ascii 22)))
  (begin
    (asserts! (is-none (get-player-profile tx-sender)) error-gamer-already-registered)
    (asserts! (validate-gamer-tag gamer-tag) error-invalid-player-data)
    (asserts! (validate-player-id player-id) error-invalid-player-data)
    (ok (map-set player-profiles tx-sender {gamer-tag: gamer-tag, player-id: player-id}))))

(define-public (load-gaming-coins (amount uint))
  (let ((current-balance (get-coin-wallet-balance tx-sender)))
    (asserts! (> amount u0) error-invalid-coin-amount)
    (ok (map-set gaming-coin-wallets tx-sender (+ current-balance amount)))))

(define-public (exchange-coins (recipient principal) (amount uint))
  (let
    (
      (sender-balance (get-coin-wallet-balance tx-sender))
      (exchange-fee (/ (* amount (var-get exchange-fee-basis-points)) u10000))
      (total-deduction (+ amount exchange-fee))
      (current-rate (var-get coin-conversion-rate))
    )
    (asserts! (not (var-get maintenance-mode-status)) error-exchange-maintenance)
    (asserts! (is-some (get-player-profile tx-sender)) error-gamer-not-registered)
    (asserts! (is-some (get-player-profile recipient)) error-gamer-not-registered)
    (asserts! (>= sender-balance total-deduction) error-insufficient-game-coins)
    (asserts! (> current-rate u0) error-invalid-conversion-rate)
    (try! (stx-transfer? amount tx-sender recipient))
    (try! (stx-transfer? exchange-fee tx-sender platform-master))
    (map-set gaming-coin-wallets tx-sender (- sender-balance total-deduction))
    (ok (/ (* amount current-rate) u100000000)))) ;; Returns converted amount with assumed 8 decimals

(define-public (withdraw-gaming-coins (amount uint))
  (let ((gamer-balance (get-coin-wallet-balance tx-sender)))
    (asserts! (>= gamer-balance amount) error-insufficient-game-coins)
    (try! (as-contract (stx-transfer? amount platform-master tx-sender)))
    (ok (map-set gaming-coin-wallets tx-sender (- gamer-balance amount)))))

(define-public (update-conversion-rate (new-rate uint))
  (begin
    (asserts! (is-rate-moderator tx-sender) error-operation-not-allowed)
    (asserts! (> new-rate u0) error-invalid-conversion-rate)
    (ok (var-set coin-conversion-rate new-rate))))

;; Emergency maintenance mode
(define-public (set-maintenance-mode (maintenance-status bool))
  (begin
    (asserts! (is-eq tx-sender platform-master) error-access-violation)
    (ok (var-set maintenance-mode-status maintenance-status))))

;; Administrator Functions
(define-public (update-exchange-fee (new-fee-basis-points uint))
  (begin
    (asserts! (is-eq tx-sender platform-master) error-access-violation)
    (asserts! (<= new-fee-basis-points u10000) error-invalid-coin-amount) ;; Cap at 100%
    (ok (var-set exchange-fee-basis-points new-fee-basis-points))))

(define-public (add-rate-moderator (gamer principal))
  (begin
    (asserts! (is-eq tx-sender platform-master) error-access-violation)
    (asserts! (is-none (map-get? rate-moderators gamer)) error-invalid-player-data)
    (ok (map-set rate-moderators gamer true))))

(define-public (remove-rate-moderator (gamer principal))
  (begin
    (asserts! (is-eq tx-sender platform-master) error-access-violation)
    (asserts! (is-some (map-get? rate-moderators gamer)) error-invalid-player-data)
    (ok (map-delete rate-moderators gamer))))