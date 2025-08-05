;; Health Screening Program Coordination Contract
;; Organizes blood pressure, diabetes, and cancer screenings

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-CAPACITY-FULL (err u104))
(define-constant ERR-INVALID-STATUS (err u105))

;; Data Variables
(define-data-var next-screening-id uint u1)
(define-data-var next-event-id uint u1)
(define-data-var next-result-id uint u1)

;; Data Maps
(define-map screening-events
  { event-id: uint }
  {
    event-name: (string-ascii 100),
    screening-type: (string-ascii 30),
    location: (string-ascii 150),
    event-date: uint,
    start-time: uint,
    end-time: uint,
    max-participants: uint,
    current-participants: uint,
    coordinator: principal,
    requirements: (string-ascii 200),
    is-active: bool
  }
)

(define-map screening-registrations
  { screening-id: uint }
  {
    patient-id: uint,
    event-id: uint,
    registration-date: uint,
    check-in-time: (optional uint),
    screening-completed: bool,
    follow-up-required: bool,
    notes: (string-ascii 200)
  }
)

(define-map screening-results
  { result-id: uint }
  {
    screening-id: uint,
    patient-id: uint,
    screening-type: (string-ascii 30),
    test-date: uint,
    blood-pressure-systolic: (optional uint),
    blood-pressure-diastolic: (optional uint),
    blood-glucose: (optional uint),
    cholesterol-total: (optional uint),
    bmi: (optional uint),
    risk-level: (string-ascii 20),
    recommendations: (string-ascii 300),
    follow-up-date: (optional uint)
  }
)

(define-map patient-screening-history
  { patient-id: uint }
  {
    screening-ids: (list 20 uint),
    last-screening-date: uint,
    total-screenings: uint,
    high-risk-flags: uint
  }
)

(define-map screening-statistics
  { event-id: uint }
  {
    total-registered: uint,
    total-completed: uint,
    high-risk-identified: uint,
    follow-ups-required: uint,
    average-age: uint
  }
)

;; Private Functions
(define-private (is-valid-future-date (date uint))
  (> date block-height)
)

(define-private (is-valid-time-range (start-time uint) (end-time uint))
  (and (>= start-time u6) (<= end-time u22) (< start-time end-time))
)

(define-private (calculate-bmi (weight uint) (height uint))
  (if (and (> weight u0) (> height u0))
    (some (/ (* weight u10000) (* height height)))
    none
  )
)

(define-private (determine-risk-level
  (systolic (optional uint))
  (diastolic (optional uint))
  (glucose (optional uint))
  (bmi (optional uint))
)
  (let (
    (high-bp (match systolic sys (match diastolic dia (or (>= sys u140) (>= dia u90)) false) false))
    (high-glucose (match glucose gluc (>= gluc u126) false))
    (high-bmi (match bmi b (>= b u30) false))
  )
    (if (or high-bp high-glucose high-bmi)
      "high"
      (if (or
        (match systolic sys (>= sys u120) false)
        (match glucose gluc (>= gluc u100) false)
        (match bmi b (>= b u25) false)
      )
        "moderate"
        "low"
      )
    )
  )
)

;; Public Functions

;; Create a new screening event
(define-public (create-screening-event
  (event-name (string-ascii 100))
  (screening-type (string-ascii 30))
  (location (string-ascii 150))
  (event-date uint)
  (start-time uint)
  (end-time uint)
  (max-participants uint)
  (requirements (string-ascii 200))
)
  (let (
    (event-id (var-get next-event-id))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len event-name) u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-future-date event-date) ERR-INVALID-INPUT)
    (asserts! (is-valid-time-range start-time end-time) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)

    (map-set screening-events
      { event-id: event-id }
      {
        event-name: event-name,
        screening-type: screening-type,
        location: location,
        event-date: event-date,
        start-time: start-time,
        end-time: end-time,
        max-participants: max-participants,
        current-participants: u0,
        coordinator: tx-sender,
        requirements: requirements,
        is-active: true
      }
    )

    ;; Initialize statistics
    (map-set screening-statistics
      { event-id: event-id }
      {
        total-registered: u0,
        total-completed: u0,
        high-risk-identified: u0,
        follow-ups-required: u0,
        average-age: u0
      }
    )

    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

;; Register for a screening event
(define-public (register-for-screening
  (patient-id uint)
  (event-id uint)
  (notes (string-ascii 200))
)
  (let (
    (screening-id (var-get next-screening-id))
    (event (unwrap! (map-get? screening-events { event-id: event-id }) ERR-NOT-FOUND))
    (current-history (default-to
      { screening-ids: (list), last-screening-date: u0, total-screenings: u0, high-risk-flags: u0 }
      (map-get? patient-screening-history { patient-id: patient-id })
    ))
  )
    (asserts! (> patient-id u0) ERR-INVALID-INPUT)
    (asserts! (get is-active event) ERR-INVALID-STATUS)
    (asserts! (< (get current-participants event) (get max-participants event)) ERR-CAPACITY-FULL)

    ;; Create registration
    (map-set screening-registrations
      { screening-id: screening-id }
      {
        patient-id: patient-id,
        event-id: event-id,
        registration-date: block-height,
        check-in-time: none,
        screening-completed: false,
        follow-up-required: false,
        notes: notes
      }
    )

    ;; Update event participant count
    (map-set screening-events
      { event-id: event-id }
      (merge event { current-participants: (+ (get current-participants event) u1) })
    )

    ;; Update patient history
    (map-set patient-screening-history
      { patient-id: patient-id }
      {
        screening-ids: (unwrap! (as-max-len? (append (get screening-ids current-history) screening-id) u20) ERR-CAPACITY-FULL),
        last-screening-date: (get last-screening-date current-history),
        total-screenings: (+ (get total-screenings current-history) u1),
        high-risk-flags: (get high-risk-flags current-history)
      }
    )

    ;; Update statistics
    (let (
      (current-stats (unwrap! (map-get? screening-statistics { event-id: event-id }) ERR-NOT-FOUND))
    )
      (map-set screening-statistics
        { event-id: event-id }
        (merge current-stats { total-registered: (+ (get total-registered current-stats) u1) })
      )
    )

    (var-set next-screening-id (+ screening-id u1))
    (ok screening-id)
  )
)

;; Check in for screening
(define-public (check-in-screening (screening-id uint))
  (let (
    (registration (unwrap! (map-get? screening-registrations { screening-id: screening-id }) ERR-NOT-FOUND))
  )
    (asserts! (is-none (get check-in-time registration)) ERR-ALREADY-EXISTS)

    (map-set screening-registrations
      { screening-id: screening-id }
      (merge registration { check-in-time: (some block-height) })
    )
    (ok true)
  )
)

;; Record screening results
(define-public (record-screening-results
  (screening-id uint)
  (blood-pressure-systolic (optional uint))
  (blood-pressure-diastolic (optional uint))
  (blood-glucose (optional uint))
  (cholesterol-total (optional uint))
  (weight (optional uint))
  (height (optional uint))
  (recommendations (string-ascii 300))
  (follow-up-date (optional uint))
)
  (let (
    (result-id (var-get next-result-id))
    (registration (unwrap! (map-get? screening-registrations { screening-id: screening-id }) ERR-NOT-FOUND))
    (patient-id (get patient-id registration))
    (event (unwrap! (map-get? screening-events { event-id: (get event-id registration) }) ERR-NOT-FOUND))
    (calculated-bmi (match weight w (match height h (calculate-bmi w h) none) none))
    (risk-level (determine-risk-level blood-pressure-systolic blood-pressure-diastolic blood-glucose calculated-bmi))
  )
    (asserts! (is-eq tx-sender (get coordinator event)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (get check-in-time registration)) ERR-INVALID-STATUS)

    ;; Record results
    (map-set screening-results
      { result-id: result-id }
      {
        screening-id: screening-id,
        patient-id: patient-id,
        screening-type: (get screening-type event),
        test-date: block-height,
        blood-pressure-systolic: blood-pressure-systolic,
        blood-pressure-diastolic: blood-pressure-diastolic,
        blood-glucose: blood-glucose,
        cholesterol-total: cholesterol-total,
        bmi: calculated-bmi,
        risk-level: risk-level,
        recommendations: recommendations,
        follow-up-date: follow-up-date
      }
    )

    ;; Update registration
    (map-set screening-registrations
      { screening-id: screening-id }
      (merge registration {
        screening-completed: true,
        follow-up-required: (is-some follow-up-date)
      })
    )

    ;; Update patient history
    (let (
      (current-history (unwrap! (map-get? patient-screening-history { patient-id: patient-id }) ERR-NOT-FOUND))
      (is-high-risk (is-eq risk-level "high"))
    )
      (map-set patient-screening-history
        { patient-id: patient-id }
        (merge current-history {
          last-screening-date: block-height,
          high-risk-flags: (if is-high-risk (+ (get high-risk-flags current-history) u1) (get high-risk-flags current-history))
        })
      )
    )

    ;; Update event statistics
    (let (
      (current-stats (unwrap! (map-get? screening-statistics { event-id: (get event-id registration) }) ERR-NOT-FOUND))
      (is-high-risk (is-eq risk-level "high"))
      (needs-follow-up (is-some follow-up-date))
    )
      (map-set screening-statistics
        { event-id: (get event-id registration) }
        (merge current-stats {
          total-completed: (+ (get total-completed current-stats) u1),
          high-risk-identified: (if is-high-risk (+ (get high-risk-identified current-stats) u1) (get high-risk-identified current-stats)),
          follow-ups-required: (if needs-follow-up (+ (get follow-ups-required current-stats) u1) (get follow-ups-required current-stats))
        })
      )
    )

    (var-set next-result-id (+ result-id u1))
    (ok result-id)
  )
)

;; Read-only functions

;; Get screening event details
(define-read-only (get-screening-event (event-id uint))
  (map-get? screening-events { event-id: event-id })
)

;; Get screening registration
(define-read-only (get-screening-registration (screening-id uint))
  (map-get? screening-registrations { screening-id: screening-id })
)

;; Get screening results
(define-read-only (get-screening-results (result-id uint))
  (map-get? screening-results { result-id: result-id })
)

;; Get patient screening history
(define-read-only (get-patient-screening-history (patient-id uint))
  (map-get? patient-screening-history { patient-id: patient-id })
)

;; Get event statistics
(define-read-only (get-event-statistics (event-id uint))
  (map-get? screening-statistics { event-id: event-id })
)

;; Check event capacity
(define-read-only (check-event-capacity (event-id uint))
  (match (map-get? screening-events { event-id: event-id })
    event (some {
      max-participants: (get max-participants event),
      current-participants: (get current-participants event),
      available-spots: (- (get max-participants event) (get current-participants event))
    })
    none
  )
)
