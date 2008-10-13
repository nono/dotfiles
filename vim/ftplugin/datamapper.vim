" Vim ftplugin file
" Language:    Datamapper
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 14, 2008
" Version:     0.1
" URL:         http://www.datamapper.org/

inorea <buffer> res include DataMapper::Resource

inorea <buffer> sti property :type, Discriminator
inorea <buffer> delat property :deleted_at, ParanoidDateTime
inorea <buffer> timestamps property :created_at, DateTime<cr>property :updated_at, DateTime
inorea <buffer> enum property :status, Enum[:new], :default => :new
inorea <buffer> flag property :levels, Flag[:admin]

inorea <buffer> vp validates_present
inorea <buffer> va validates_absent
inorea <buffer> via validates_is_accepted
inorea <buffer> vis validates_is_confirmed
inorea <buffer> vf validates_format
inorea <buffer> vl validates_length
inorea <buffer> vwm validates_with_method
inorea <buffer> vwb validates_with_block
inorea <buffer> vin validates_is_number
inorea <buffer> viu validates_is_unique
inorea <buffer> vw validates_within
