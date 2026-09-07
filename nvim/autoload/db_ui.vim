function! db_ui#get_conn_info(...)
  let l:db_key_name = a:0 > 0 ? a:1 : get(b:, 'dbui_db_key_name', '')
  let l:url = get(b:, 'db', '')
  
  if empty(l:url) && !empty(l:db_key_name)
    let l:url = get(get(g:, 'dbs', {}), l:db_key_name, '')
  endif

  let l:parsed = !empty(l:url) ? db#url#parse(l:url) : {'scheme': ''}
  
  " Use buffer cache first
  let l:tables = get(b:, 'mini_dbui_tables', [])
  
  " Fallback to executing the adapter call if buffer cache is empty
  if empty(l:tables) && !empty(l:url)
    try
      let l:raw_tables = db#adapter#dispatch(l:url, 'tables')
      for l:tbl in l:raw_tables
        let l:clean = trim(l:tbl)
        if !empty(l:clean) && l:clean !~# '^[-+|]\+' && l:clean !~? '^table' && l:clean !~? '^row'
          call add(l:tables, l:clean)
        endif
      endfor
    catch
      let l:tables = []
    endtry
  endif

  return {
        \ 'url': l:url,
        \ 'conn': l:url,
        \ 'tables': l:tables,
        \ 'schemas': [],
        \ 'scheme': get(l:parsed, 'scheme', ''),
        \ 'connected': !empty(l:url),
        \ }
endfunction
