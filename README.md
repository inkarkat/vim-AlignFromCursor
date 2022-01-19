ALIGN FROM CURSOR
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

This plugin offers commands and mappings that align only the text to the right
of the cursor, and keep the text to the left unmodified, unlike the built-in
:left and :right, which always work on the entire line.
This is useful e.g. for right-aligning the "-- Author" attribution in a
fortune, the help tags definitions in this help file, or to left-align a
comment to a particular column.
The alignment width defaults to 'textwidth', can be passed as a [count] to the
mappings, and there are mappings that take the actual width from adjacent
previous / next lines.

### RELATED WORKS

- The Align plugin ([vimscript #294](http://www.vim.org/scripts/script.php?script_id=294)) offers a general-purpose :Align command
  and many mappings for text alignment along various characters, but those are
  more specialized for certain syntax fragments and do not consider the
  current cursor position like this plugin.
- The Tabular plugin (https://github.com/godlygeek/tabular) is similar to the
  Align plugin.
- The vim-easy-align plugin ([vimscript #4520](http://www.vim.org/scripts/script.php?script_id=4520)) is also similar to Align, and
  asserts it's easy to use.
- right\_align ([vimscript #3728](http://www.vim.org/scripts/script.php?script_id=3728)) has a :RightAlign command that aligns to
  'textwidth' in full increments of 'shiftwidth'.

USAGE
------------------------------------------------------------------------------

    [width]<Leader>le
    :[range]LeftAlignFromCursor [width]
                            Left-align the text on and right of the cursor to
                            [width] columns (default 'textwidth' or 80 when
                            'textwidth' is 0). Cp. :left.
                            Applies to all lines in [range], based on the current
                            cursor position.
                            In visual mode: Applies to the selected text, based on
                            the leftmost selected column.

    [count]<Leader>lp       Left-align the text on and right of the cursor to the
    [count]<Leader>ln       indent of the [count]'th previous / next unfolded line.
                            In visual mode: Left-align the selected text to the
                            indent of the [count]'th unfolded line above / below
                            the visual selection.

    [width]<Leader>ri
    :[range]RightAlignFromCursor [width]
                            Right-align the text on and right of the cursor to
                            [width] columns (default 'textwidth' or 80 when
                            'textwidth' is 0). Cp. :right.
                            Applies to all lines in [range], based on the current
                            cursor position.
                            In visual mode: Applies to the selected text, based on
                            the leftmost selected column.

    [count]<Leader>rp       Right-align the text on and right of the cursor to the
    [count]<Leader>rn       width of the [count]'th previous / next unfolded line.
                            In visual mode: Right-align the selected text to the
                            width of the [count]'th unfolded line above / below
                            the visual selection.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-AlignFromCursor
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim AlignFromCursor*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.016 or
  higher.
- IndentTab.vim ([vimscript #3848](http://www.vim.org/scripts/script.php?script_id=3848)) plugin (optional)
- repeat.vim ([vimscript #2136](http://www.vim.org/scripts/script.php?script_id=2136)) plugin (optional)
- visualrepeat.vim ([vimscript #3848](http://www.vim.org/scripts/script.php?script_id=3848)) plugin (optional)

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

If you want to use different mappings, map your keys to the
&lt;Plug&gt;(Left|Right)Align... mapping targets _before_ sourcing the script (e.g.
in your vimrc):

    nmap <silent> <Leader>ri <Plug>RightAlignFromCursor
    nmap <silent> <Leader>le <Plug>LeftAlignFromCursor
    xmap <silent> <Leader>ri <Plug>RightAlignFromCursor
    xmap <silent> <Leader>le <Plug>LeftAlignFromCursor
    nmap <silent> <Leader>rp <Plug>RightAlignToPreviousLine
    nmap <silent> <Leader>rn <Plug>RightAlignToNextLine
    nmap <silent> <Leader>lp <Plug>LeftAlignToPreviousLine
    nmap <silent> <Leader>ln <Plug>LeftAlignToNextLine
    xmap <silent> <Leader>rp <Plug>RightAlignToPreviousLine
    xmap <silent> <Leader>rn <Plug>RightAlignToNextLine
    xmap <silent> <Leader>lp <Plug>LeftAlignToPreviousLine
    xmap <silent> <Leader>ln <Plug>LeftAlignToNextLine

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-AlignFromCursor/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 2.02    29-Dec-2016
- Improve internal efficiency.
- Extract AlignFromCursor#GetRetabbedFromCol() and expose for reuse.
- BUG: :LeftAlignFromCursor adds one character too few if the first
  left-aligned character is double width (e.g. ^X unprintable or Kanji
  character).

##### 2.01    29-Jan-2014
- Support the IndentTab setting provided by the optional IndentTab plugin
  ([vimscript #4243](http://www.vim.org/scripts/script.php?script_id=4243)). I.e. align with spaces when there's text before the
  cursor.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.016!__

##### 2.00    19-Jul-2013
- Use unfolded lines for the relative [count] in &lt;Leader&gt;lp / &lt;Leader&gt;ln /
  &lt;Leader&gt;rp / &lt;Leader&gt;rn. This is consistent with other Vim commands and
  allows benefitting from 'relativenumber'. When addressing a folded line, the
  indent of the first contained line is used.
- ENH: Add visual mode &lt;Leader&gt;lp / &lt;Leader&gt;ln / &lt;Leader&gt;rp / &lt;Leader&gt;rn
  mappings that work on the selection and take the [count]'th above / below
  line.
- CHG: Make repeats of the mappings use the previous width instead of just
  re-applying them at the current cursor position. DWIM.
- BUG: Don't delete whitespace immediately after the cursor position if the
  cursor rests on a non-whitespace character. This makes the alignment _after_
  the cursor position, not _from_ it. (Though this was a nice DWIM feature
  when on the last character of a word; but it makes it impossible to do an
  actual align from there, and is inconsistent.)
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)).

__You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.004 (or higher)!__

##### 1.12    10-Jan-2013
- Fix slowness of :RightAlignFromCursor in connection with plugins like
recover.vim, caused by the repeated triggers of InsertEnter / InsertLeave
events inserting a single space.

##### 1.11    06-Dec-2012
- BUG: On repeat, the original [count] is overridden by the align commands,
causing e.g. a toggling of right-align and align to column 1 on repeated
&lt;Leader&gt;ri.

##### 1.10    02-Aug-2012
- ENH: Do not :retab the entire line (which also affects leading indent and
whitespace after the area, just render the modified whitespace around the
cursor according to the buffer's indent settings.

##### 1.00    01-Aug-2012
- First published version.

##### 0.01    22-Jul-2006
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2006-2022 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
