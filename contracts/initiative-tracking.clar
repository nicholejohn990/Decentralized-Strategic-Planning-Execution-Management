;; Initiative Tracking Contract
;; Tracks strategic initiatives within plans

(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INITIATIVE_NOT_FOUND (err u301))
(define-constant ERR_PLAN_NOT_FOUND (err u302))
(define-constant ERR_INVALID_PROGRESS (err u303))

;; Data variables
(define-data-var next-initiative-id uint u1)

;; Data maps
(define-map initiatives uint {
    plan-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 300),
    owner: principal,
    progress: uint,
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint
})

(define-map initiative-milestones uint (list 5 {
    milestone: (string-ascii 100),
    completed: bool,
    completed-at: (optional uint)
}))

;; Read-only functions
(define-read-only (get-initiative (initiative-id uint))
    (map-get? initiatives initiative-id)
)

(define-read-only (get-initiative-milestones (initiative-id uint))
    (map-get? initiative-milestones initiative-id)
)

(define-read-only (get-current-initiative-id)
    (var-get next-initiative-id)
)

;; Public functions
(define-public (create-initiative
    (plan-id uint)
    (title (string-ascii 100))
    (description (string-ascii 300))
    (milestones (list 5 (string-ascii 100))))
    (let ((initiative-id (var-get next-initiative-id)))
        (map-set initiatives initiative-id {
            plan-id: plan-id,
            title: title,
            description: description,
            owner: tx-sender,
            progress: u0,
            status: "active",
            created-at: block-height,
            updated-at: block-height
        })
        (map-set initiative-milestones initiative-id
            (map create-milestone-entry milestones))
        (var-set next-initiative-id (+ initiative-id u1))
        (ok initiative-id)
    )
)

(define-public (update-progress (initiative-id uint) (new-progress uint))
    (let ((initiative (unwrap! (get-initiative initiative-id) ERR_INITIATIVE_NOT_FOUND)))
        (asserts! (is-eq (get owner initiative) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (<= new-progress u100) ERR_INVALID_PROGRESS)
        (map-set initiatives initiative-id
            (merge initiative {
                progress: new-progress,
                updated-at: block-height,
                status: (if (is-eq new-progress u100) "completed" "active")
            }))
        (ok true)
    )
)

(define-public (complete-milestone (initiative-id uint) (milestone-index uint))
    (let ((initiative (unwrap! (get-initiative initiative-id) ERR_INITIATIVE_NOT_FOUND)))
        (asserts! (is-eq (get owner initiative) tx-sender) ERR_UNAUTHORIZED)
        ;; Milestone completion logic would be implemented here
        (ok true)
    )
)

;; Private functions
(define-private (create-milestone-entry (milestone (string-ascii 100)))
    {
        milestone: milestone,
        completed: false,
        completed-at: none
    }
)
