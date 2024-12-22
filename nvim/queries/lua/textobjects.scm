; extends

; (string) @quote.outer
; (string_content) @quote.inner
((comment) @comment.inner
  (#offset! @comment.inner 0 2))

(string
    (["'" "\""] .
    (_) @_start (_)? @_end .
    ["'" "\""])
    (#make-range! "quote.inner" @_start @_end)
) @quote.outer

; another try, but with weird results
(
    ["(" "[" "<" "{"] @_a_start .
    (_) @_start (_)? @_end .
    [")" "]" ">" "}"] @_a_end
    (#make-range! "bracket.inner" @_start @_end)
    (#make-range! "bracket.outer" @_a_start @_a_end)
) @bracket.outer

; (arguments ( ["("] . (_) @_start (_)? @_end . [")"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer
;
; (table_constructor ( ["{"] . (_) @_start (_)? @_end . ["}"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer
;
; (field ( ["["] . (_) @_start (_)? @_end . ["]"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer ; doesn't exists node for outer

; (parameters) @bracket.outer
; (parameters name: (identifier) @bracket.inner)
;
; (table_constructor) @bracket.outer
; (table_constructor (","(field (string))) @bracket.inner)
