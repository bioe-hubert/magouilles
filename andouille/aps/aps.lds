SECTIONS
{
  .text _text_link_adrs_ : 
   AT ( _text_sect_adrs_ )
    { _startcode = . ; *(.text) ; _endcode = . ; }
  .data _data_link_adrs_ : 
   AT ( _data_sect_adrs_ )
    { _startdata = . ; *(.data) ; _enddata = . ; }
}

