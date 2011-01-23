" Only do the rest when the FileType autocommand has not been triggered yet.
if did_filetype()
    finish
endif

if getline(1) =~ '^#!.*\<node\>'
    setfiletype javascript
endif
