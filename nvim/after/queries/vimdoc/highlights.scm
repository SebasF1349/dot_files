;; extends

((word) @health.success
  (#any-of? @health.success "Ok" "OK"))

((word) @health.warning
        (#any-of? @health.warning "Warning" "WARNING"))
 
((word) @health.error
  (#any-of? @health.error "Error" "ERROR" "Deprecated" "DEPRECATED"))
