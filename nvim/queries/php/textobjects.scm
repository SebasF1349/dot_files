; extends

(string) @quote.outer
(string_content) @quote.inner
(escape_sequence) @quote.inner

(arguments ( ["("] . (_) @_start (_)? @_end . [")"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer
; ((_) ( ["("] . (_) @_start (_)? @_end . [")"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer
