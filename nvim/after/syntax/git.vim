"syn match GA /\[\w\+\]/ contained
"syntax region gitAuthor start=+\[+ end=+\]+
"syn region gitGraphReview start=/\%(^[|\/\\_ ]*\*[|\/\\_ ]\{-\} commit\%( \x\{4,\}\)\{1,\}\%(\s*(.*)\)\=$\)\@=/ end=/^\%([|\/\\_ ]*$\)\@=/ contains=@NoSpell
"syn match gitcommitHeader	"\%(^. \)\@<=\S.*[:：]\%(\n^$\)\@!$" contained containedin=gitcommitComment

syntax match gitGraphReview /^[|\/\\_ ]\{-\}\*[|\/\\_ ]\{-\} \zs\x\{7,\} .* \[.*\]\@=/ contains=@NoSpell
syntax match gitGraphReviewHash /\x\{7,\} \@=/ contained containedin=gitGraphReview,gitGraphReviewHeader contains=@NoSpell
syntax match gitGraphReviewHeader /\x\{7,\}\s*(.\{-\})/ contained containedin=gitGraphReview contains=@NoSpell
"syntax match gitGraphReviewRef /\x\{7,\}\s*\zs(.\{-\})\ze \@=/ contained containedin=gitGraphReview contains=@NoSpell
" FAILS: with more than one match per line
syntax region gitGraphReviewRef start=/(/ end=/)/ contained containedin=gitGraphReviewHeader contains=@NoSpell
"syntax match gitGraphReviewRef /(.\{-\})/ contained containedin=gitGraphReview contains=@NoSpell
" FAILS: with more than one match per line
"syntax match gitGraphReviewType /\S*[:：] \@=/ contained containedin=gitGraphReview contains=@NoSpell
syntax match gitGraphReviewType /fix\|feat\|refactor\|change\|chore\|clean/ contained containedin=gitGraphReview contains=@NoSpell
syntax match gitGraphReviewAuthor /\[[^[]*\]/ contained containedin=gitGraphReview contains=@NoSpell
"syn match  gitKeyword /^[*|\/\\_ ]\+\zscommit \@=/ contained containedin=gitGraph nextgroup=gitHashAbbrev skipwhite contains=@NoSpell

syntax match gitGraphReviewFiles /^[|\/\\_* ]\{-\}[|\/\\_ ]\{-\}\s\zs\d\{1,\}\s\d\{1,\}\s.*[\\\/].*/ contains=@NoSpell
syntax match gitGraphReviewFilesDiffs /\d\{1,\}\s\d\{1,\}\s/ contained containedin=gitGraphReviewFiles contains=@NoSpell
syntax match gitGraphReviewFilesFile /.*[\\\/]\zs\S*\.\S*/ contained containedin=gitGraphReviewFiles contains=@NoSpell

hi def link gitGraphReviewHash gitHash
hi def link gitGraphReviewRef Underlined
hi def link gitGraphReviewType Label
hi def link gitGraphReviewAuthor String

hi def link gitGraphReviewFilesDiffs String
hi def link gitGraphReviewFilesFile diffFile
"hi def link gitGraphReviewFiles String

"syn match qfFileName /^[^│]*/ nextgroup=qfSeparatorLeft
"syn match qfSeparatorLeft /│/ contained nextgroup=qfLineNr
"syn match qfLineNr /[^│]*/ contained nextgroup=qfSeparatorRight
"syn match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote
"syn match qfError / E .*$/ contained
"syn match qfWarning / W .*$/ contained
"syn match qfInfo / I .*$/ contained
"syn match qfNote / [NH] .*$/ contained
"
"hi def link qfFileName Directory
"hi def link qfSeparatorLeft Delimiter
"hi def link qfSeparatorRight Delimiter
"hi def link qfLineNr LineNr
"hi def link qfError DiagnosticError
"hi def link qfWarning DiagnosticWarn
"hi def link qfInfo DiagnosticInfo
"hi def link qfNote DiagnosticHint
