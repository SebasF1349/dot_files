syntax match diffRemoved /\<D\>/ containedin=fugitiveUntrackedModifier,fugitiveUnstagedModifier,fugitiveStagedModifier
syntax match diffChanged /\<M\>/ containedin=fugitiveUntrackedModifier,fugitiveUnstagedModifier,fugitiveStagedModifier
syntax match diffAdded /\<A\>/ containedin=fugitiveUntrackedModifier,fugitiveUnstagedModifier,fugitiveStagedModifier
syntax match diffOldFile /\<R\>/ containedin=fugitiveUntrackedModifier,fugitiveUnstagedModifier,fugitiveStagedModifier
syntax match diffNewFile /[?]/ containedin=fugitiveUntrackedModifier,fugitiveUnstagedModifier,fugitiveStagedModifier
