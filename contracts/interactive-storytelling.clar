(define-fungible-token story-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-voting-ended (err u103))
(define-constant err-insufficient-tokens (err u104))
(define-constant err-invalid-option (err u105))
(define-constant err-voting-not-ended (err u106))
(define-constant err-already-executed (err u107))
(define-constant err-no-winner (err u108))

(define-data-var story-count uint u0)
(define-data-var vote-count uint u0)
(define-data-var total-token-supply uint u1000000)

(define-map stories uint {
  title: (string-ascii 100),
  creator: principal,
  current-chapter: uint,
  is-active: bool,
  created-at: uint
})

(define-map plot-votes uint {
  story-id: uint,
  chapter: uint,
  option-a: (string-ascii 200),
  option-b: (string-ascii 200),
  option-c: (string-ascii 200),
  votes-a: uint,
  votes-b: uint,
  votes-c: uint,
  voting-end: uint,
  is-executed: bool,
  winning-option: (optional uint)
})

(define-map user-votes {vote-id: uint, user: principal} {
  option: uint,
  tokens-used: uint,
  voted-at: uint
})

(define-map user-token-balance principal uint)

(define-map story-chapters {story-id: uint, chapter: uint} {
  content: (string-ascii 500),
  choices-made: (optional uint),
  timestamp: uint
})

(define-public (initialize-tokens (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? story-token amount tx-sender))
    (map-set user-token-balance tx-sender amount)
    (ok amount)))

(define-public (transfer-tokens (amount uint) (recipient principal))
  (let ((sender-balance (default-to u0 (map-get? user-token-balance tx-sender))))
    (asserts! (>= sender-balance amount) err-insufficient-tokens)
    (try! (ft-transfer? story-token amount tx-sender recipient))
    (map-set user-token-balance tx-sender (- sender-balance amount))
    (map-set user-token-balance recipient 
      (+ (default-to u0 (map-get? user-token-balance recipient)) amount))
    (ok amount)))

(define-public (create-story (title (string-ascii 100)))
  (let ((new-story-id (+ (var-get story-count) u1)))
    (map-set stories new-story-id {
      title: title,
      creator: tx-sender,
      current-chapter: u0,
      is-active: true,
      created-at: stacks-block-height
    })
    (var-set story-count new-story-id)
    (ok new-story-id)))

(define-public (add-chapter-content (story-id uint) (chapter uint) (content (string-ascii 500)))
  (let ((story (unwrap! (map-get? stories story-id) err-not-found)))
    (asserts! (is-eq (get creator story) tx-sender) err-owner-only)
    (map-set story-chapters {story-id: story-id, chapter: chapter} {
      content: content,
      choices-made: none,
      timestamp: stacks-block-height
    })
    (ok chapter)))

(define-public (create-plot-vote 
  (story-id uint) 
  (chapter uint) 
  (option-a (string-ascii 200)) 
  (option-b (string-ascii 200)) 
  (option-c (string-ascii 200))
  (voting-duration uint))
  (let ((story (unwrap! (map-get? stories story-id) err-not-found))
        (new-vote-id (+ (var-get vote-count) u1)))
    (asserts! (is-eq (get creator story) tx-sender) err-owner-only)
    (asserts! (get is-active story) err-not-found)
    (map-set plot-votes new-vote-id {
      story-id: story-id,
      chapter: chapter,
      option-a: option-a,
      option-b: option-b,
      option-c: option-c,
      votes-a: u0,
      votes-b: u0,
      votes-c: u0,
      voting-end: (+ stacks-block-height voting-duration),
      is-executed: false,
      winning-option: none
    })
    (var-set vote-count new-vote-id)
    (ok new-vote-id)))

(define-public (vote-on-plot (vote-id uint) (option uint) (token-amount uint))
  (let ((vote-data (unwrap! (map-get? plot-votes vote-id) err-not-found))
        (user-balance (default-to u0 (map-get? user-token-balance tx-sender)))
        (vote-key {vote-id: vote-id, user: tx-sender}))
    (asserts! (is-none (map-get? user-votes vote-key)) err-already-voted)
    (asserts! (<= stacks-block-height (get voting-end vote-data)) err-voting-ended)
    (asserts! (>= user-balance token-amount) err-insufficient-tokens)
    (asserts! (and (>= option u1) (<= option u3)) err-invalid-option)
    (asserts! (> token-amount u0) err-insufficient-tokens)
    
    (map-set user-votes vote-key {
      option: option,
      tokens-used: token-amount,
      voted-at: stacks-block-height
    })
    
    (map-set user-token-balance tx-sender (- user-balance token-amount))
    
    (map-set plot-votes vote-id
      (if (is-eq option u1)
        (merge vote-data {votes-a: (+ (get votes-a vote-data) token-amount)})
        (if (is-eq option u2)
          (merge vote-data {votes-b: (+ (get votes-b vote-data) token-amount)})
          (merge vote-data {votes-c: (+ (get votes-c vote-data) token-amount)}))))
    
    (ok token-amount)))

(define-public (execute-vote-result (vote-id uint))
  (let ((vote-data (unwrap! (map-get? plot-votes vote-id) err-not-found))
        (story-data (unwrap! (map-get? stories (get story-id vote-data)) err-not-found)))
    (asserts! (> stacks-block-height (get voting-end vote-data)) err-voting-not-ended)
    (asserts! (not (get is-executed vote-data)) err-already-executed)
    (asserts! (is-eq tx-sender (get creator story-data)) err-owner-only)
    
    (let ((votes-a (get votes-a vote-data))
          (votes-b (get votes-b vote-data))
          (votes-c (get votes-c vote-data))
          (winning-option (if (and (>= votes-a votes-b) (>= votes-a votes-c))
                            u1
                            (if (>= votes-b votes-c) u2 u3))))
      
      (map-set plot-votes vote-id 
        (merge vote-data {
          is-executed: true,
          winning-option: (some winning-option)
        }))
      
      (map-set story-chapters {story-id: (get story-id vote-data), chapter: (get chapter vote-data)}
        (merge (default-to {content: "", choices-made: none, timestamp: u0} 
                 (map-get? story-chapters {story-id: (get story-id vote-data), chapter: (get chapter vote-data)}))
               {choices-made: (some winning-option)}))
      
      (map-set stories (get story-id vote-data)
        (merge story-data {current-chapter: (+ (get current-chapter story-data) u1)}))
      
      (ok winning-option))))

(define-public (claim-vote-refund (vote-id uint))
  (let ((vote-data (unwrap! (map-get? plot-votes vote-id) err-not-found))
        (vote-key {vote-id: vote-id, user: tx-sender})
        (user-vote (unwrap! (map-get? user-votes vote-key) err-not-found)))
    (asserts! (> stacks-block-height (get voting-end vote-data)) err-voting-not-ended)
    (asserts! (get is-executed vote-data) err-not-found)
    
    (let ((winning-option (unwrap! (get winning-option vote-data) err-no-winner))
          (user-option (get option user-vote))
          (tokens-used (get tokens-used user-vote)))
      
      (if (is-eq user-option winning-option)
        (begin
          (map-set user-token-balance tx-sender 
            (+ (default-to u0 (map-get? user-token-balance tx-sender)) tokens-used))
          (ok tokens-used))
        (ok u0)))))

(define-public (deactivate-story (story-id uint))
  (let ((story (unwrap! (map-get? stories story-id) err-not-found)))
    (asserts! (is-eq (get creator story) tx-sender) err-owner-only)
    (map-set stories story-id (merge story {is-active: false}))
    (ok story-id)))

(define-read-only (get-story (story-id uint))
  (map-get? stories story-id))

(define-read-only (get-plot-vote (vote-id uint))
  (map-get? plot-votes vote-id))

(define-read-only (get-user-vote (vote-id uint) (user principal))
  (map-get? user-votes {vote-id: vote-id, user: user}))

(define-read-only (get-token-balance (user principal))
  (default-to u0 (map-get? user-token-balance user)))

(define-read-only (get-chapter-content (story-id uint) (chapter uint))
  (map-get? story-chapters {story-id: story-id, chapter: chapter}))

(define-read-only (get-story-count)
  (var-get story-count))

(define-read-only (get-vote-count)
  (var-get vote-count))

(define-read-only (get-vote-results (vote-id uint))
  (match (map-get? plot-votes vote-id)
    vote-data (ok {
      votes-a: (get votes-a vote-data),
      votes-b: (get votes-b vote-data),
      votes-c: (get votes-c vote-data),
      total-votes: (+ (+ (get votes-a vote-data) (get votes-b vote-data)) (get votes-c vote-data)),
      winning-option: (get winning-option vote-data),
      is-executed: (get is-executed vote-data)
    })
    err-not-found))

(define-read-only (is-voting-active (vote-id uint))
  (match (map-get? plot-votes vote-id)
    vote-data (<= stacks-block-height (get voting-end vote-data))
    false))
