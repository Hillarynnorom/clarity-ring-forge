;; RingForge - Digital Wedding/Event Invitation Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-rsvp (err u104))

;; Data Types
(define-non-fungible-token invitation uint)

(define-map invitations
    uint 
    {
        owner: principal,
        title: (string-utf8 100),
        description: (string-utf8 500),
        date: uint,
        location: (string-utf8 200),
        max-guests: uint,
        rsvp-deadline: uint
    }
)

(define-map guest-lists
    {invitation-id: uint, guest: principal}
    {
        rsvp-status: (string-ascii 20),
        plus-ones: uint,
        timestamp: uint
    }
)

(define-data-var last-id uint u0)

;; Private Functions
(define-private (is-owner (invitation-id uint))
    (let ((invitation (unwrap! (map-get? invitations invitation-id) err-not-found)))
        (is-eq tx-sender (get owner invitation))
    )
)

;; Public Functions
(define-public (create-invitation 
        (title (string-utf8 100))
        (description (string-utf8 500))
        (date uint)
        (location (string-utf8 200))
        (max-guests uint)
        (rsvp-deadline uint)
    )
    (let
        ((new-id (+ (var-get last-id) u1)))
        (try! (nft-mint? invitation new-id tx-sender))
        (map-set invitations new-id {
            owner: tx-sender,
            title: title,
            description: description,
            date: date,
            location: location,
            max-guests: max-guests,
            rsvp-deadline: rsvp-deadline
        })
        (var-set last-id new-id)
        (ok new-id)
    )
)

(define-public (update-invitation
        (invitation-id uint)
        (title (string-utf8 100))
        (description (string-utf8 500))
        (date uint)
        (location (string-utf8 200))
        (max-guests uint)
        (rsvp-deadline uint)
    )
    (if (is-owner invitation-id)
        (begin
            (map-set invitations invitation-id {
                owner: tx-sender,
                title: title,
                description: description,
                date: date,
                location: location,
                max-guests: max-guests,
                rsvp-deadline: rsvp-deadline
            })
            (ok true)
        )
        err-unauthorized
    )
)

(define-public (add-guest 
        (invitation-id uint)
        (guest principal)
    )
    (if (is-owner invitation-id)
        (begin
            (map-set guest-lists 
                {invitation-id: invitation-id, guest: guest}
                {
                    rsvp-status: "pending",
                    plus-ones: u0,
                    timestamp: block-height
                }
            )
            (ok true)
        )
        err-unauthorized
    )
)

(define-public (submit-rsvp
        (invitation-id uint)
        (status (string-ascii 20))
        (plus-ones uint)
    )
    (let (
        (guest-info (unwrap! (map-get? guest-lists {invitation-id: invitation-id, guest: tx-sender}) err-not-found))
        (invitation (unwrap! (map-get? invitations invitation-id) err-not-found))
    )
    (if (> block-height (get rsvp-deadline invitation))
        err-invalid-rsvp
        (begin
            (map-set guest-lists
                {invitation-id: invitation-id, guest: tx-sender}
                {
                    rsvp-status: status,
                    plus-ones: plus-ones,
                    timestamp: block-height
                }
            )
            (ok true)
        ))
    )
)

;; Read-only functions
(define-read-only (get-invitation (invitation-id uint))
    (ok (map-get? invitations invitation-id))
)

(define-read-only (get-guest-rsvp (invitation-id uint) (guest principal))
    (ok (map-get? guest-lists {invitation-id: invitation-id, guest: guest}))
)

(define-read-only (get-total-rsvps (invitation-id uint))
    (ok u0) ;; TODO: Implement counter logic
)