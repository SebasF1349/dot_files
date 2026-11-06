;; extends

; Capture the entire curl command
(command
  name: (command_name
    (word) @curl.program
    (#eq? @curl.program "curl"))) @curl.command

; Capture strings
(command
  name: (command_name (word) @_c)
  argument: [(string) (raw_string)] @curl.string
  (#eq? @_c "curl"))

; Capture flags
; short: -s, -X, -XPOST (attached values included), but not a lone "-"
(command
  name: (command_name (word) @_c)
  argument: (word) @curl.flag
  (#eq? @_c "curl")
  (#lua-match? @curl.flag "^%-[^-]")
  (#set! priority 110))

; long: --header, --silent, ...  (a bare "--" is excluded)
(command
  name: (command_name (word) @_c)
  argument: (word) @curl.flag
  (#eq? @_c "curl")
  (#lua-match? @curl.flag "^%-%-.")
  (#set! priority 110))

; Capture HTTP method values (GET, POST, etc.)
(command
  name: (command_name (word) @_c)
  argument: (word) @_flag
  .
  argument: (word) @http.method
  (#eq? @_c "curl")
  (#any-of? @_flag "-X" "--request")
  (#any-of? @http.method "GET" "POST" "PUT" "DELETE" "PATCH" "HEAD" "OPTIONS")
  (#set! priority 120))

; Capture URLs
; bare: https://example.com/x
(command
  name: (command_name (word) @_c)
  argument: (word) @curl.url
  (#eq? @_c "curl")
  (#lua-match? @curl.url "^https?://")
  (#set! priority 120))

; quoted ('...' or "..."); capturing the whole node also covers strings
; that contain expansions, e.g. "https://api.example.com/$ID"
(command
  name: (command_name (word) @_c)
  argument: [(string) (raw_string)] @curl.url
  (#eq? @_c "curl")
  (#lua-match? @curl.url "^%p?https?://")
  (#set! priority 120))
