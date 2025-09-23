;; title: CommInternet
;; version: 1.0.0
;; summary: Community-Owned Internet Infrastructure DAO
;; description: A DAO for funding and managing local community internet infrastructure

(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_INVALID_AMOUNT (err u403))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_VOTED (err u405))
(define-constant ERR_VOTING_ENDED (err u406))
(define-constant ERR_NOT_MEMBER (err u407))
(define-constant ERR_ALREADY_MEMBER (err u408))
(define-constant ERR_PROPOSAL_ACTIVE (err u409))
(define-constant ERR_INSUFFICIENT_VOTES (err u410))
(define-constant ERR_SYSTEM_PAUSED (err u411))
(define-constant ERR_ALREADY_VOTED_PAUSE (err u412))
(define-constant ERR_NOT_VOTED_PAUSE (err u413))
(define-constant ERR_STILL_PAUSED (err u414))

(define-constant MIN_MEMBERSHIP_FEE u100000000)
(define-constant VOTING_PERIOD u144)
(define-constant MIN_QUORUM u51)
(define-constant MAX_PAUSE_DURATION u1008)
(define-constant PAUSE_QUORUM u3)

(define-data-var contract-owner principal tx-sender)
(define-data-var total-members uint u0)
(define-data-var total-funds uint u0)
(define-data-var proposal-count uint u0)
(define-data-var profit-pool uint u0)
(define-data-var paused-until uint u0)
(define-data-var pause-vote-count uint u0)

(define-map members principal {
    stake: uint,
    voting-power: uint,
    joined-at: uint,
    is-active: bool
})

(define-map proposals uint {
    proposer: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    amount: uint,
    recipient: principal,
    votes-for: uint,
    votes-against: uint,
    created-at: uint,
    voting-ends: uint,
    executed: bool,
    proposal-type: (string-utf8 20)
})

(define-map votes {proposal-id: uint, voter: principal} bool)

(define-map pause-votes principal bool)

(define-map infrastructure uint {
    id: uint,
    location: (string-utf8 100),
    type: (string-utf8 50),
    cost: uint,
    status: (string-utf8 20),
    manager: principal
})

(define-data-var infrastructure-count uint u0)


(define-public (join-dao (amount uint))
    (let ((caller tx-sender))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (>= amount MIN_MEMBERSHIP_FEE) ERR_INVALID_AMOUNT)
        (asserts! (is-none (map-get? members caller)) ERR_ALREADY_MEMBER)
        (try! (stx-transfer? amount caller (as-contract tx-sender)))
        (map-set members caller {
            stake: amount,
            voting-power: (/ amount u100000000),
            joined-at: stacks-block-height,
            is-active: true
        })
        (var-set total-members (+ (var-get total-members) u1))
        (var-set total-funds (+ (var-get total-funds) amount))
        (ok true)
    )
)

(define-public (leave-dao)
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER))
          (refund-amount (/ (get stake member-data) u2)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (get is-active member-data) ERR_NOT_MEMBER)
        (try! (as-contract (stx-transfer? refund-amount tx-sender caller)))
        (map-delete members caller)
        (var-set total-members (- (var-get total-members) u1))
        (var-set total-funds (- (var-get total-funds) refund-amount))
        (ok refund-amount)
    )
)

(define-public (add-funds (amount uint))
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (stx-transfer? amount caller (as-contract tx-sender)))
        (map-set members caller (merge member-data {
            stake: (+ (get stake member-data) amount),
            voting-power: (/ (+ (get stake member-data) amount) u100000000)
        }))
        (var-set total-funds (+ (var-get total-funds) amount))
        (ok true)
    )
)

(define-public (create-proposal (title (string-utf8 100)) (description (string-utf8 500)) (amount uint) (recipient principal) (proposal-type (string-utf8 20)))
    (let ((caller tx-sender)
          (proposal-id (+ (var-get proposal-count) u1))
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= amount (var-get total-funds)) ERR_INSUFFICIENT_FUNDS)
        (map-set proposals proposal-id {
            proposer: caller,
            title: title,
            description: description,
            amount: amount,
            recipient: recipient,
            votes-for: u0,
            votes-against: u0,
            created-at: stacks-block-height,
            voting-ends: (+ stacks-block-height VOTING_PERIOD),
            executed: false,
            proposal-type: proposal-type
        })
        (var-set proposal-count proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote-proposal (proposal-id uint) (vote-for bool))
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER))
          (proposal-data (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
          (voting-power (get voting-power member-data)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
        (asserts! (<= stacks-block-height (get voting-ends proposal-data)) ERR_VOTING_ENDED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: caller})) ERR_ALREADY_VOTED)
        (map-set votes {proposal-id: proposal-id, voter: caller} vote-for)
        (if vote-for
            (map-set proposals proposal-id (merge proposal-data {
                votes-for: (+ (get votes-for proposal-data) voting-power)
            }))
            (map-set proposals proposal-id (merge proposal-data {
                votes-against: (+ (get votes-against proposal-data) voting-power)
            }))
        )
        (ok true)
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let ((proposal-data (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
          (total-votes (+ (get votes-for proposal-data) (get votes-against proposal-data)))
          (total-voting-power (get-total-voting-power)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (> stacks-block-height (get voting-ends proposal-data)) ERR_PROPOSAL_ACTIVE)
        (asserts! (not (get executed proposal-data)) ERR_PROPOSAL_ACTIVE)
        (asserts! (>= (/ (* total-votes u100) total-voting-power) MIN_QUORUM) ERR_INSUFFICIENT_VOTES)
        (asserts! (> (get votes-for proposal-data) (get votes-against proposal-data)) ERR_INSUFFICIENT_VOTES)
        (try! (as-contract (stx-transfer? (get amount proposal-data) tx-sender (get recipient proposal-data))))
        (map-set proposals proposal-id (merge proposal-data {executed: true}))
        (var-set total-funds (- (var-get total-funds) (get amount proposal-data)))
        (ok true)
    )
)

(define-public (add-infrastructure (location (string-utf8 100)) (infra-type (string-utf8 50)) (cost uint) (manager principal))
    (let ((caller tx-sender)
          (infra-id (+ (var-get infrastructure-count) u1)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        (map-set infrastructure infra-id {
            id: infra-id,
            location: location,
            type: infra-type,
            cost: cost,
            status: u"planning",
            manager: manager
        })
        (var-set infrastructure-count infra-id)
        (ok infra-id)
    )
)

(define-public (update-infrastructure-status (infra-id uint) (new-status (string-utf8 20)))
    (let ((caller tx-sender)
          (infra-data (unwrap! (map-get? infrastructure infra-id) ERR_PROPOSAL_NOT_FOUND)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (or (is-eq caller (var-get contract-owner)) (is-eq caller (get manager infra-data))) ERR_NOT_AUTHORIZED)
        (map-set infrastructure infra-id (merge infra-data {status: new-status}))
        (ok true)
    )
)

(define-public (distribute-profits (amount uint))
    (let ((caller tx-sender))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (is-eq caller (var-get contract-owner)) ERR_NOT_AUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (var-set profit-pool (+ (var-get profit-pool) amount))
        (ok true)
    )
)

(define-public (claim-profit-share)
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER))
          (total-voting-power (get-total-voting-power))
          (member-voting-power (get voting-power member-data))
          (profit-share (/ (* (var-get profit-pool) member-voting-power) total-voting-power)))
        (asserts! (not (is-paused)) ERR_SYSTEM_PAUSED)
        (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
        (asserts! (> profit-share u0) ERR_INSUFFICIENT_FUNDS)
        (try! (as-contract (stx-transfer? profit-share tx-sender caller)))
        (var-set profit-pool (- (var-get profit-pool) profit-share))
        (ok profit-share)
    )
)

(define-read-only (get-member-info (member principal))
    (map-get? members member)
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-infrastructure (infra-id uint))
    (map-get? infrastructure infra-id)
)

(define-read-only (get-dao-stats)
    {
        total-members: (var-get total-members),
        total-funds: (var-get total-funds),
        proposal-count: (var-get proposal-count),
        profit-pool: (var-get profit-pool),
        infrastructure-count: (var-get infrastructure-count)
    }
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes {proposal-id: proposal-id, voter: voter}))
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-total-voting-power)
    (var-get total-members)
)

(define-public (is-dao-member (member principal))
    (match (map-get? members member)
        member-data (ok (get is-active member-data))
        (ok false)
    )
)

(define-public (vote-to-pause)
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER))
          (current-votes (var-get pause-vote-count)))
        (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
        (asserts! (is-none (map-get? pause-votes caller)) ERR_ALREADY_VOTED_PAUSE)
        (map-set pause-votes caller true)
        (var-set pause-vote-count (+ current-votes u1))
        (if (>= (+ current-votes u1) PAUSE_QUORUM)
            (var-set paused-until (+ stacks-block-height MAX_PAUSE_DURATION))
            true
        )
        (ok true)
    )
)

(define-public (clear-pause-vote)
    (let ((caller tx-sender)
          (member-data (unwrap! (map-get? members caller) ERR_NOT_MEMBER)))
        (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
        (asserts! (is-some (map-get? pause-votes caller)) ERR_NOT_VOTED_PAUSE)
        (asserts! (is-eq (var-get paused-until) u0) ERR_STILL_PAUSED)
        (map-delete pause-votes caller)
        (var-set pause-vote-count (- (var-get pause-vote-count) u1))
        (ok true)
    )
)

(define-public (unpause)
    (begin
        (asserts! (>= stacks-block-height (var-get paused-until)) ERR_STILL_PAUSED)
        (var-set paused-until u0)
        (var-set pause-vote-count u0)
        (ok true)
    )
)

(define-read-only (is-paused)
    (< u0 (var-get paused-until))
)

(define-read-only (get-pause-status)
    {
        paused-until: (var-get paused-until),
        current-votes: (var-get pause-vote-count),
        required-votes: PAUSE_QUORUM,
        max-duration: MAX_PAUSE_DURATION
    }
)

(define-read-only (has-voted-pause (voter principal))
    (is-some (map-get? pause-votes voter))
)
