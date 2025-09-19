
;; title: ElectricGrid
;; version: 1.0.0
;; summary: Synthetic assets smart contract for smart grid and energy storage infrastructure
;; description: Provides exposure to grid capacity, energy storage, and renewable energy assets

;; traits
;;

;; token definitions
(define-fungible-token grid-token)
(define-fungible-token energy-token)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-funds (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-unauthorized (err u105))

;; Grid parameters
(define-constant min-grid-capacity u1000)
(define-constant max-grid-capacity u1000000)
(define-constant base-energy-rate u100) ;; Base rate per MWh in microSTX

;; data vars
(define-data-var total-grid-capacity uint u0)
(define-data-var total-energy-stored uint u0)
(define-data-var energy-price-per-mwh uint base-energy-rate)
(define-data-var contract-paused bool false)

;; data maps
(define-map grid-nodes
  { node-id: uint }
  {
    owner: principal,
    capacity: uint,
    efficiency-rating: uint, ;; Percentage (0-100)
    location: (string-ascii 50),
    is-active: bool,
    last-updated: uint
  }
)

(define-map energy-storage
  { storage-id: uint }
  {
    owner: principal,
    capacity: uint,
    current-stored: uint,
    storage-type: (string-ascii 20), ;; "battery", "pumped-hydro", "compressed-air"
    efficiency: uint, ;; Percentage (0-100)
    is-operational: bool
  }
)

(define-map user-balances
  { user: principal }
  {
    grid-tokens: uint,
    energy-tokens: uint,
    staked-capacity: uint
  }
)

(define-map node-counter principal uint)
(define-map storage-counter principal uint)

;; public functions

;; Initialize a new grid node
(define-public (create-grid-node (capacity uint) (efficiency-rating uint) (location (string-ascii 50)))
  (let
    (
      (node-id (+ (default-to u0 (map-get? node-counter tx-sender)) u1))
    )
    (asserts! (not (var-get contract-paused)) (err u999))
    (asserts! (and (>= capacity min-grid-capacity) (<= capacity max-grid-capacity)) err-invalid-amount)
    (asserts! (<= efficiency-rating u100) err-invalid-amount)

    (map-set grid-nodes
      { node-id: node-id }
      {
        owner: tx-sender,
        capacity: capacity,
        efficiency-rating: efficiency-rating,
        location: location,
        is-active: true,
        last-updated: block-height
      }
    )

    (map-set node-counter tx-sender node-id)
    (var-set total-grid-capacity (+ (var-get total-grid-capacity) capacity))

    ;; Mint grid tokens based on capacity
    (try! (ft-mint? grid-token capacity tx-sender))

    (ok node-id)
  )
)

;; Create energy storage facility
(define-public (create-energy-storage (capacity uint) (storage-type (string-ascii 20)) (efficiency uint))
  (let
    (
      (storage-id (+ (default-to u0 (map-get? storage-counter tx-sender)) u1))
    )
    (asserts! (not (var-get contract-paused)) (err u999))
    (asserts! (> capacity u0) err-invalid-amount)
    (asserts! (<= efficiency u100) err-invalid-amount)

    (map-set energy-storage
      { storage-id: storage-id }
      {
        owner: tx-sender,
        capacity: capacity,
        current-stored: u0,
        storage-type: storage-type,
        efficiency: efficiency,
        is-operational: true
      }
    )

    (map-set storage-counter tx-sender storage-id)

    ;; Mint energy tokens based on storage capacity
    (try! (ft-mint? energy-token (/ (* capacity efficiency) u100) tx-sender))

    (ok storage-id)
  )
)

;; Store energy in a storage facility
(define-public (store-energy (storage-id uint) (amount uint))
  (let
    (
      (storage-data (unwrap! (map-get? energy-storage { storage-id: storage-id }) err-not-found))
      (current-stored (get current-stored storage-data))
      (capacity (get capacity storage-data))
      (efficiency (get efficiency storage-data))
      (effective-amount (/ (* amount efficiency) u100))
    )
    (asserts! (not (var-get contract-paused)) (err u999))
    (asserts! (is-eq (get owner storage-data) tx-sender) err-unauthorized)
    (asserts! (get is-operational storage-data) err-unauthorized)
    (asserts! (<= (+ current-stored effective-amount) capacity) err-invalid-amount)

    (map-set energy-storage
      { storage-id: storage-id }
      (merge storage-data { current-stored: (+ current-stored effective-amount) })
    )

    (var-set total-energy-stored (+ (var-get total-energy-stored) effective-amount))

    ;; Mint energy tokens for stored energy
    (try! (ft-mint? energy-token effective-amount tx-sender))

    (ok effective-amount)
  )
)

;; Release energy from storage
(define-public (release-energy (storage-id uint) (amount uint))
  (let
    (
      (storage-data (unwrap! (map-get? energy-storage { storage-id: storage-id }) err-not-found))
      (current-stored (get current-stored storage-data))
      (efficiency (get efficiency storage-data))
      (effective-amount (/ (* amount efficiency) u100))
    )
    (asserts! (not (var-get contract-paused)) (err u999))
    (asserts! (is-eq (get owner storage-data) tx-sender) err-unauthorized)
    (asserts! (get is-operational storage-data) err-unauthorized)
    (asserts! (<= effective-amount current-stored) err-insufficient-funds)

    ;; Burn energy tokens
    (try! (ft-burn? energy-token effective-amount tx-sender))

    (map-set energy-storage
      { storage-id: storage-id }
      (merge storage-data { current-stored: (- current-stored effective-amount) })
    )

    (var-set total-energy-stored (- (var-get total-energy-stored) effective-amount))

    (ok effective-amount)
  )
)

;; Trade grid tokens for energy tokens
(define-public (trade-grid-for-energy (grid-amount uint))
  (let
    (
      (energy-amount (/ (* grid-amount (var-get energy-price-per-mwh)) u100))
    )
    (asserts! (not (var-get contract-paused)) (err u999))
    (asserts! (> grid-amount u0) err-invalid-amount)

    ;; Burn grid tokens and mint energy tokens
    (try! (ft-burn? grid-token grid-amount tx-sender))
    (try! (ft-mint? energy-token energy-amount tx-sender))

    (ok energy-amount)
  )
)

;; Update energy price (owner only)
(define-public (update-energy-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-amount)
    (var-set energy-price-per-mwh new-price)
    (ok true)
  )
)

;; Pause/unpause contract (owner only)
(define-public (set-contract-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused paused)
    (ok true)
  )
)

;; Update grid node status
(define-public (update-node-status (node-id uint) (is-active bool))
  (let
    (
      (node-data (unwrap! (map-get? grid-nodes { node-id: node-id }) err-not-found))
    )
    (asserts! (is-eq (get owner node-data) tx-sender) err-unauthorized)

    (map-set grid-nodes
      { node-id: node-id }
      (merge node-data {
        is-active: is-active,
        last-updated: block-height
      })
    )

    (ok true)
  )
)

;; read only functions

;; Get grid node information
(define-read-only (get-grid-node (node-id uint))
  (map-get? grid-nodes { node-id: node-id })
)

;; Get energy storage information
(define-read-only (get-energy-storage (storage-id uint))
  (map-get? energy-storage { storage-id: storage-id })
)

;; Get user token balances
(define-read-only (get-user-balance (user principal))
  {
    grid-tokens: (ft-get-balance grid-token user),
    energy-tokens: (ft-get-balance energy-token user)
  }
)

;; Get total grid capacity
(define-read-only (get-total-grid-capacity)
  (var-get total-grid-capacity)
)

;; Get total energy stored
(define-read-only (get-total-energy-stored)
  (var-get total-energy-stored)
)

;; Get current energy price
(define-read-only (get-energy-price)
  (var-get energy-price-per-mwh)
)

;; Get contract status
(define-read-only (get-contract-status)
  {
    is-paused: (var-get contract-paused),
    total-grid-capacity: (var-get total-grid-capacity),
    total-energy-stored: (var-get total-energy-stored),
    energy-price: (var-get energy-price-per-mwh),
    owner: contract-owner
  }
)

;; Calculate grid efficiency
(define-read-only (calculate-grid-efficiency (node-id uint))
  (match (map-get? grid-nodes { node-id: node-id })
    node-data (some (get efficiency-rating node-data))
    none
  )
)

;; Get storage utilization percentage
(define-read-only (get-storage-utilization (storage-id uint))
  (match (map-get? energy-storage { storage-id: storage-id })
    storage-data
      (let
        (
          (capacity (get capacity storage-data))
          (stored (get current-stored storage-data))
        )
        (if (> capacity u0)
          (some (/ (* stored u100) capacity))
          none
        )
      )
    none
  )
)

;; private functions

;; Validate storage type
(define-private (is-valid-storage-type (storage-type (string-ascii 20)))
  (or
    (is-eq storage-type "battery")
    (or
      (is-eq storage-type "pumped-hydro")
      (is-eq storage-type "compressed-air")
    )
  )
)

