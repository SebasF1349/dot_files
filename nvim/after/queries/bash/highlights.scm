;; extends

; 1. Capture the entire curl command
(command
  name: (command_name
    (word) @curl.program
    (#eq? @curl.program "curl"))) @curl.command

; 2. Capture URLs
((command
    name: (command_name
      (word) @curl.program
      (#eq? @curl.program "curl"))
    argument: (word) @url)
  (#match? @url "^https?://"))

; 3. Capture HTTP method values (GET, POST, etc.)
((command
    name: (command_name
      (word) @curl.program
      (#eq? @curl.program "curl"))
    argument: (word) @http.method)
  (#match? @http.method "^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)$"))

; 4. Capture all flags (any argument starting with -)
((command
    name: (command_name
      (word) @curl.program
      (#eq? @curl.program "curl"))
    argument: (word) @flag)
  (#match? @flag "^-"))

; 5. Capture string arguments (headers, data, etc.)
((command
    name: (command_name
      (word) @curl.program
      (#eq? @curl.program "curl"))
    argument: (string) @string.value))

; 6. Capture raw string arguments
((command
    name: (command_name
      (word) @curl.program
      (#eq? @curl.program "curl"))
    argument: (raw_string) @string.value))
