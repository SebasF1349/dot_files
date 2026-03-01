syntax match gitGraphReviewHeader /\*[ |]*\zs\x\{7,\} - .*(.*)/ contains=@NoSpell
syntax match gitGraphReviewHash /\x\{7,\} \@=/ contained containedin=gitGraphReviewHeader contains=@NoSpell
syntax match gitGraphReviewAuthor /(\d.\{-\}) - .*/ contained containedin=gitGraphReviewHeader contains=@NoSpell
syntax match gitGraphReviewDate /(\d.\{-\})/ contained containedin=gitGraphReviewAuthor contains=@NoSpell

syntax match gitGraphReviewTitleHeader /⤷ \zs[^:]\+:\ze/ contains=@NoSpell

syntax match gitGraphReviewFiles /^[|\/\\_* ]\{-\}[|\/\\_ ]\{-\}\s\zs\d\{1,\}\s\d\{1,\}\s.*[\\\/].*/ contains=@NoSpell
syntax match gitGraphReviewFilesDiffs /\d\{1,\}\s\d\{1,\}\s/ contained containedin=gitGraphReviewFiles contains=@NoSpell
syntax match gitGraphReviewFilesFile /.*[\\\/]\zs.*/ contained containedin=gitGraphReviewFiles contains=@NoSpell

hi def link gitGraphReviewHash Keyword
hi def link gitGraphReviewTitleHeader Label
hi def link gitGraphReviewAuthor Identifier 
hi def link gitGraphReviewDate Comment

hi def link gitGraphReviewFilesDiffs String
hi def link gitGraphReviewFilesFile diffFile
