; extends

(string_literal) @quote.outer
(string_content) @quote.inner
(escape_sequence) @quote.inner

(arguments ( ["("] . (_) @_start (_)? @_end . [")"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer
; ((_) ( ["("] . (_) @_start (_)? @_end . [")"])(#make-range! "bracket.inner" @_start @_end)) @bracket.outer

(scoped_identifier) @quote.inner
        body: (ordered_field_declaration_list ; [232, 12] - [232, 19]
