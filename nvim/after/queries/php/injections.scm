; inherits: php

((echo_statement
    (_
        (string_content) @injection.content))
(#set! injection.language "html"))

((member_call_expression
    name: (name) @method_name
    arguments: (arguments
      (argument
        [
          (_ (string_content) @injection.content)
          (_ (_ (string_content) @injection.content))
          (_ (_ (_ (string_content) @injection.content)))
        ])))
  (#eq? @method_name "registerJs")
  (#set! injection.language "javascript"))
