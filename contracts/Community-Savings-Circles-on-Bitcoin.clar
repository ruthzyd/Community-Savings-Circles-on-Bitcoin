;; title: Community-Savings-Circles-on-Bitcoin

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-circle-not-found (err u101))
(define-constant err-already-member (err u102))
(define-constant err-not-member (err u103))
(define-constant err-circle-full (err u104))
(define-constant err-circle-not-active (err u105))
(define-constant err-insufficient-contribution (err u106))
(define-constant err-already-contributed (err u107))
(define-constant err-not-payout-time (err u108))
(define-constant err-already-received-payout (err u109))
(define-constant err-circle-active (err u110))
(define-constant err-invalid-params (err u111))
(define-constant err-payout-failed (err u112))

(define-data-var circle-nonce uint u0)

(define-map circles
  uint
  {
    creator: principal,
    total-members: uint,
    max-members: uint,
    contribution-amount: uint,
    payout-interval: uint,
    start-block: uint,
    current-round: uint,
    is-active: bool,
    total-pool: uint
  }
)

(define-map circle-members
  { circle-id: uint, member: principal }
  {
    position: uint,
    has-contributed: bool,
    has-received-payout: bool,
    join-block: uint
  }
)

(define-map member-contributions
  { circle-id: uint, member: principal, round: uint }
  { amount: uint, contributed-at: uint }
)

(define-map circle-payouts
  { circle-id: uint, round: uint }
  { recipient: principal, amount: uint, paid-at: uint }
)

(define-read-only (get-circle (circle-id uint))
  (map-get? circles circle-id)
)

(define-read-only (get-member-info (circle-id uint) (member principal))
  (map-get? circle-members { circle-id: circle-id, member: member })
)

(define-read-only (get-contribution (circle-id uint) (member principal) (round uint))
  (map-get? member-contributions { circle-id: circle-id, member: member, round: round })
)

(define-read-only (get-payout-info (circle-id uint) (round uint))
  (map-get? circle-payouts { circle-id: circle-id, round: round })
)

(define-read-only (get-current-recipient (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) (err err-circle-not-found)))
      (current-round (get current-round circle))
    )
    (ok current-round)
  )
)

(define-read-only (get-next-payout-block (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) (err err-circle-not-found)))
      (start-block (get start-block circle))
      (interval (get payout-interval circle))
      (current-round (get current-round circle))
    )
    (ok (+ start-block (* interval (+ current-round u1))))
  )
)

(define-public (create-circle (max-members uint) (contribution-amount uint) (payout-interval uint))
  (let
    (
      (new-circle-id (+ (var-get circle-nonce) u1))
    )
    (asserts! (and (> max-members u1) (> contribution-amount u0) (> payout-interval u0)) err-invalid-params)
    (map-set circles new-circle-id {
      creator: tx-sender,
      total-members: u0,
      max-members: max-members,
      contribution-amount: contribution-amount,
      payout-interval: payout-interval,
      start-block: u0,
      current-round: u0,
      is-active: false,
      total-pool: u0
    })
    (var-set circle-nonce new-circle-id)
    (ok new-circle-id)
  )
)

(define-public (join-circle (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) err-circle-not-found))
      (member-info (map-get? circle-members { circle-id: circle-id, member: tx-sender }))
      (current-members (get total-members circle))
    )
    (asserts! (is-none member-info) err-already-member)
    (asserts! (< current-members (get max-members circle)) err-circle-full)
    (map-set circle-members
      { circle-id: circle-id, member: tx-sender }
      {
        position: current-members,
        has-contributed: false,
        has-received-payout: false,
        join-block: stacks-block-height
      }
    )
    (map-set circles circle-id (merge circle { total-members: (+ current-members u1) }))
    (ok true)
  )
)

(define-public (activate-circle (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) err-circle-not-found))
    )
    (asserts! (is-eq tx-sender (get creator circle)) err-owner-only)
    (asserts! (is-eq (get total-members circle) (get max-members circle)) err-invalid-params)
    (asserts! (not (get is-active circle)) err-circle-active)
    (map-set circles circle-id (merge circle { 
      is-active: true,
      start-block: stacks-block-height
    }))
    (ok true)
  )
)

(define-public (contribute (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) err-circle-not-found))
      (member-info (unwrap! (get-member-info circle-id tx-sender) err-not-member))
      (current-round (get current-round circle))
      (contribution-amount (get contribution-amount circle))
      (existing-contribution (map-get? member-contributions { 
        circle-id: circle-id, 
        member: tx-sender, 
        round: current-round 
      }))
    )
    (asserts! (get is-active circle) err-circle-not-active)
    (asserts! (is-none existing-contribution) err-already-contributed)
    (try! (stx-transfer? contribution-amount tx-sender (as-contract tx-sender)))
    (map-set member-contributions
      { circle-id: circle-id, member: tx-sender, round: current-round }
      { amount: contribution-amount, contributed-at: stacks-block-height }
    )
    (map-set circle-members
      { circle-id: circle-id, member: tx-sender }
      (merge member-info { has-contributed: true })
    )
    (map-set circles circle-id (merge circle { 
      total-pool: (+ (get total-pool circle) contribution-amount)
    }))
    (ok true)
  )
)

(define-public (claim-payout (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) err-circle-not-found))
      (member-info (unwrap! (get-member-info circle-id tx-sender) err-not-member))
      (current-round (get current-round circle))
      (member-position (get position member-info))
      (payout-amount (* (get contribution-amount circle) (get max-members circle)))
      (next-payout-block (+ (get start-block circle) (* (get payout-interval circle) (+ current-round u1))))
    )
    (asserts! (get is-active circle) err-circle-not-active)
    (asserts! (is-eq member-position current-round) err-not-payout-time)
    (asserts! (>= stacks-block-height next-payout-block) err-not-payout-time)
    (asserts! (not (get has-received-payout member-info)) err-already-received-payout)
    (asserts! (>= (get total-pool circle) payout-amount) err-insufficient-contribution)
    (try! (as-contract (stx-transfer? payout-amount tx-sender tx-sender)))
    (map-set circle-members
      { circle-id: circle-id, member: tx-sender }
      (merge member-info { has-received-payout: true })
    )
    (map-set circle-payouts
      { circle-id: circle-id, round: current-round }
      { recipient: tx-sender, amount: payout-amount, paid-at: stacks-block-height }
    )
    (map-set circles circle-id (merge circle {
      current-round: (+ current-round u1),
      total-pool: (- (get total-pool circle) payout-amount)
    }))
    (ok payout-amount)
  )
)

(define-public (advance-round (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) err-circle-not-found))
      (current-round (get current-round circle))
    )
    (asserts! (get is-active circle) err-circle-not-active)
    (asserts! (< (+ current-round u1) (get max-members circle)) err-invalid-params)
    (map-set circles circle-id (merge circle { current-round: (+ current-round u1) }))
    (ok true)
  )
)

(define-read-only (is-contribution-complete (circle-id uint) (round uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) (err err-circle-not-found)))
    )
    (ok true)
  )
)

(define-read-only (get-circle-balance (circle-id uint))
  (let
    (
      (circle (unwrap! (get-circle circle-id) (err err-circle-not-found)))
    )
    (ok (get total-pool circle))
  )
)
