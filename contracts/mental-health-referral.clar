;; Mental Health Services Referral Contract
;; Connects patients with counseling and psychiatric services

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-CAPACITY-FULL (err u104))
(define-constant ERR-INVALID-STATUS (err u105))

;; Data Variables
(define-data-var next-referral-id uint u1)
(define-data-var next-provider-id uint u1)
(define-data-var next-assessment-id uint u1)

;; Data Maps
(define-map mental-health-providers
  { provider-id: uint }
  {
    name: (string-ascii 100),
    specialty: (string-ascii 50),
    license-type: (string-ascii 30),
    location: (string-ascii 150),
    phone: (string-ascii 20),
    email: (string-ascii 100),
    accepts-insurance: bool,
    sliding-scale-available: bool,
    languages: (list 5 (string-ascii 20)),
    max-weekly-patients: uint,
    current-patient-load: uint,
    is-accepting-patients: bool,
    is-active: bool
  }
)

(define-map referral-requests
  { referral-id: uint }
  {
    patient-id: uint,
    referring-provider: (string-ascii 100),
    urgency-level: (string-ascii 20),
    service-type: (string-ascii 50),
    presenting-concerns: (string-ascii 300),
    preferred-provider-id: (optional uint),
    insurance-status: (string-ascii 30),
    preferred-language: (string-ascii 20),
    availability-notes: (string-ascii 200),
    status: (string-ascii 20),
    created-at: uint,
    assigned-provider-id: (optional uint),
    assignment-date: (optional uint),
    first-appointment-date: (optional uint)
  }
)

(define-map mental-health-assessments
  { assessment-id: uint }
  {
    patient-id: uint,
    referral-id: uint,
    assessment-date: uint,
    phq9-score: (optional uint),
    gad7-score: (optional uint),
    risk-assessment: (string-ascii 20),
    diagnosis-codes: (list 5 (string-ascii 10)),
    treatment-recommendations: (string-ascii 400),
    medication-needed: bool,
    therapy-frequency: (string-ascii 30),
    follow-up-date: uint,
    assessor-id: uint
  }
)

(define-map patient-mental-health-history
  { patient-id: uint }
  {
    referral-ids: (list 10 uint),
    total-referrals: uint,
    active-referrals: uint,
    last-assessment-date: uint,
    current-risk-level: (string-ascii 20),
    ongoing-treatment: bool
  }
)

(define-map provider-caseload
  { provider-id: uint }
  {
    active-patients: (list 50 uint),
    total-referrals-received: uint,
    average-wait-time: uint,
    specialties-served: (list 10 (string-ascii 50)),
    last-updated: uint
  }
)

;; Private Functions
(define-private (is-valid-urgency-level (urgency (string-ascii 20)))
  (or (is-eq urgency "routine") (is-eq urgency "urgent") (is-eq urgency "crisis"))
)

(define-private (calculate-risk-level (phq9 (optional uint)) (gad7 (optional uint)))
  (let (
    (phq9-risk (match phq9 score
      (if (>= score u20) "high"
        (if (>= score u15) "moderate"
          (if (>= score u10) "mild" "minimal"))) "unknown"))
    (gad7-risk (match gad7 score
      (if (>= score u15) "high"
        (if (>= score u10) "moderate"
          (if (>= score u5) "mild" "minimal"))) "unknown"))
  )
    (if (or (is-eq phq9-risk "high") (is-eq gad7-risk "high"))
      "high"
      (if (or (is-eq phq9-risk "moderate") (is-eq gad7-risk "moderate"))
        "moderate"
        "low"
      )
    )
  )
)

(define-private (find-best-provider-match
  (service-type (string-ascii 50))
  (insurance-status (string-ascii 30))
  (preferred-language (string-ascii 20))
  (urgency (string-ascii 20))
)
  ;; Simplified matching logic - in practice would be more sophisticated
  (ok u1) ;; Returns first available provider for now
)

;; Public Functions

;; Register a mental health provider
(define-public (register-mental-health-provider
  (name (string-ascii 100))
  (specialty (string-ascii 50))
  (license-type (string-ascii 30))
  (location (string-ascii 150))
  (phone (string-ascii 20))
  (email (string-ascii 100))
  (accepts-insurance bool)
  (sliding-scale-available bool)
  (languages (list 5 (string-ascii 20)))
  (max-weekly-patients uint)
)
  (let (
    (provider-id (var-get next-provider-id))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> max-weekly-patients u0) ERR-INVALID-INPUT)

    (map-set mental-health-providers
      { provider-id: provider-id }
      {
        name: name,
        specialty: specialty,
        license-type: license-type,
        location: location,
        phone: phone,
        email: email,
        accepts-insurance: accepts-insurance,
        sliding-scale-available: sliding-scale-available,
        languages: languages,
        max-weekly-patients: max-weekly-patients,
        current-patient-load: u0,
        is-accepting-patients: true,
        is-active: true
      }
    )

    ;; Initialize provider caseload
    (map-set provider-caseload
      { provider-id: provider-id }
      {
        active-patients: (list),
        total-referrals-received: u0,
        average-wait-time: u0,
        specialties-served: (list),
        last-updated: block-height
      }
    )

    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

;; Submit a mental health referral request
(define-public (submit-referral-request
  (patient-id uint)
  (referring-provider (string-ascii 100))
  (urgency-level (string-ascii 20))
  (service-type (string-ascii 50))
  (presenting-concerns (string-ascii 300))
  (preferred-provider-id (optional uint))
  (insurance-status (string-ascii 30))
  (preferred-language (string-ascii 20))
  (availability-notes (string-ascii 200))
)
  (let (
    (referral-id (var-get next-referral-id))
    (current-history (default-to
      { referral-ids: (list), total-referrals: u0, active-referrals: u0, last-assessment-date: u0, current-risk-level: "unknown", ongoing-treatment: false }
      (map-get? patient-mental-health-history { patient-id: patient-id })
    ))
  )
    (asserts! (> patient-id u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-urgency-level urgency-level) ERR-INVALID-INPUT)
    (asserts! (> (len presenting-concerns) u0) ERR-INVALID-INPUT)

    ;; Validate preferred provider if specified
    (match preferred-provider-id
      provider-id (asserts! (is-some (map-get? mental-health-providers { provider-id: provider-id })) ERR-NOT-FOUND)
      true
    )

    (map-set referral-requests
      { referral-id: referral-id }
      {
        patient-id: patient-id,
        referring-provider: referring-provider,
        urgency-level: urgency-level,
        service-type: service-type,
        presenting-concerns: presenting-concerns,
        preferred-provider-id: preferred-provider-id,
        insurance-status: insurance-status,
        preferred-language: preferred-language,
        availability-notes: availability-notes,
        status: "pending",
        created-at: block-height,
        assigned-provider-id: none,
        assignment-date: none,
        first-appointment-date: none
      }
    )

    ;; Update patient history
    (map-set patient-mental-health-history
      { patient-id: patient-id }
      {
        referral-ids: (unwrap! (as-max-len? (append (get referral-ids current-history) referral-id) u10) ERR-CAPACITY-FULL),
        total-referrals: (+ (get total-referrals current-history) u1),
        active-referrals: (+ (get active-referrals current-history) u1),
        last-assessment-date: (get last-assessment-date current-history),
        current-risk-level: (get current-risk-level current-history),
        ongoing-treatment: (get ongoing-treatment current-history)
      }
    )

    (var-set next-referral-id (+ referral-id u1))
    (ok referral-id)
  )
)

;; Assign referral to provider
(define-public (assign-referral-to-provider
  (referral-id uint)
  (provider-id uint)
)
  (let (
    (referral (unwrap! (map-get? referral-requests { referral-id: referral-id }) ERR-NOT-FOUND))
    (provider (unwrap! (map-get? mental-health-providers { provider-id: provider-id }) ERR-NOT-FOUND))
    (provider-caseload-data (unwrap! (map-get? provider-caseload { provider-id: provider-id }) ERR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status referral) "pending") ERR-INVALID-STATUS)
    (asserts! (get is-accepting-patients provider) ERR-CAPACITY-FULL)
    (asserts! (< (get current-patient-load provider) (get max-weekly-patients provider)) ERR-CAPACITY-FULL)

    ;; Update referral
    (map-set referral-requests
      { referral-id: referral-id }
      (merge referral {
        status: "assigned",
        assigned-provider-id: (some provider-id),
        assignment-date: (some block-height)
      })
    )

    ;; Update provider patient load
    (map-set mental-health-providers
      { provider-id: provider-id }
      (merge provider { current-patient-load: (+ (get current-patient-load provider) u1) })
    )

    ;; Update provider caseload
    (map-set provider-caseload
      { provider-id: provider-id }
      (merge provider-caseload-data {
        active-patients: (unwrap! (as-max-len? (append (get active-patients provider-caseload-data) (get patient-id referral)) u50) ERR-CAPACITY-FULL),
        total-referrals-received: (+ (get total-referrals-received provider-caseload-data) u1),
        last-updated: block-height
      })
    )

    (ok true)
  )
)

;; Conduct mental health assessment
(define-public (conduct-mental-health-assessment
  (patient-id uint)
  (referral-id uint)
  (phq9-score (optional uint))
  (gad7-score (optional uint))
  (diagnosis-codes (list 5 (string-ascii 10)))
  (treatment-recommendations (string-ascii 400))
  (medication-needed bool)
  (therapy-frequency (string-ascii 30))
  (follow-up-date uint)
)
  (let (
    (assessment-id (var-get next-assessment-id))
    (referral (unwrap! (map-get? referral-requests { referral-id: referral-id }) ERR-NOT-FOUND))
    (risk-level (calculate-risk-level phq9-score gad7-score))
  )
    (asserts! (is-eq (get patient-id referral) patient-id) ERR-INVALID-INPUT)
    (asserts! (is-some (get assigned-provider-id referral)) ERR-INVALID-STATUS)
    (asserts! (> follow-up-date block-height) ERR-INVALID-INPUT)

    ;; Validate PHQ-9 and GAD-7 scores if provided
    (match phq9-score score (asserts! (<= score u27) ERR-INVALID-INPUT) true)
    (match gad7-score score (asserts! (<= score u21) ERR-INVALID-INPUT) true)

    (map-set mental-health-assessments
      { assessment-id: assessment-id }
      {
        patient-id: patient-id,
        referral-id: referral-id,
        assessment-date: block-height,
        phq9-score: phq9-score,
        gad7-score: gad7-score,
        risk-assessment: risk-level,
        diagnosis-codes: diagnosis-codes,
        treatment-recommendations: treatment-recommendations,
        medication-needed: medication-needed,
        therapy-frequency: therapy-frequency,
        follow-up-date: follow-up-date,
        assessor-id: (unwrap! (get assigned-provider-id referral) ERR-INVALID-STATUS)
      }
    )

    ;; Update patient history
    (let (
      (current-history (unwrap! (map-get? patient-mental-health-history { patient-id: patient-id }) ERR-NOT-FOUND))
    )
      (map-set patient-mental-health-history
        { patient-id: patient-id }
        (merge current-history {
          last-assessment-date: block-height,
          current-risk-level: risk-level,
          ongoing-treatment: true
        })
      )
    )

    ;; Update referral status
    (map-set referral-requests
      { referral-id: referral-id }
      (merge referral { status: "assessed" })
    )

    (var-set next-assessment-id (+ assessment-id u1))
    (ok assessment-id)
  )
)

;; Schedule first appointment
(define-public (schedule-first-appointment
  (referral-id uint)
  (appointment-date uint)
)
  (let (
    (referral (unwrap! (map-get? referral-requests { referral-id: referral-id }) ERR-NOT-FOUND))
  )
    (asserts! (is-some (get assigned-provider-id referral)) ERR-INVALID-STATUS)
    (asserts! (> appointment-date block-height) ERR-INVALID-INPUT)

    (map-set referral-requests
      { referral-id: referral-id }
      (merge referral {
        status: "scheduled",
        first-appointment-date: (some appointment-date)
      })
    )
    (ok true)
  )
)

;; Read-only functions

;; Get mental health provider details
(define-read-only (get-mental-health-provider (provider-id uint))
  (map-get? mental-health-providers { provider-id: provider-id })
)

;; Get referral request details
(define-read-only (get-referral-request (referral-id uint))
  (map-get? referral-requests { referral-id: referral-id })
)

;; Get mental health assessment
(define-read-only (get-mental-health-assessment (assessment-id uint))
  (map-get? mental-health-assessments { assessment-id: assessment-id })
)

;; Get patient mental health history
(define-read-only (get-patient-mental-health-history (patient-id uint))
  (map-get? patient-mental-health-history { patient-id: patient-id })
)

;; Get provider caseload
(define-read-only (get-provider-caseload (provider-id uint))
  (map-get? provider-caseload { provider-id: provider-id })
)

;; Check provider availability
(define-read-only (check-provider-availability (provider-id uint))
  (match (map-get? mental-health-providers { provider-id: provider-id })
    provider (some {
      is-accepting-patients: (get is-accepting-patients provider),
      current-load: (get current-patient-load provider),
      max-capacity: (get max-weekly-patients provider),
      available-slots: (- (get max-weekly-patients provider) (get current-patient-load provider))
    })
    none
  )
)
