syn match qfFileName /^[^│]*/ nextgroup=qfSeparatorRight
syn match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote
syn match qfError / .*$/ contained
syn match qfWarning / .*$/ contained
syn match qfInfo / .*$/ contained
syn match qfNote / .*$/ contained

hi def link qfFileName Directory
hi def link qfSeparatorRight Delimiter
hi def link qfError DiagnosticError
hi def link qfWarning DiagnosticWarn
hi def link qfInfo DiagnosticInfo
hi def link qfNote DiagnosticHint
