;; extends

((word) @comment.warning
  (#any-of? @comment.warning "Warning" "WARNING"))

((word) @comment.note
  (#any-of? @comment.note "Ok" "OK"))
 
((word) @comment.error
  (#any-of? @comment.error "Error" "ERROR" "Deprecated" "DEPRECATED"))
