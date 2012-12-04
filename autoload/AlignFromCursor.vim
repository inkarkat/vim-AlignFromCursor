" AlignFromCursor.vim: Perform :left / :right only for the text part right of the cursor.
"
" DEPENDENCIES:
"   - EchoWithoutScrolling.vim autoload script (only for Vim 7.0 - 7.2)
"
" Copyright: (C) 2006-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.10.012	02-Aug-2012	ENH: Do not :retab the entire line (which also
"				affects leading indent and whitespace after the
"				area, just render the modified whitespace around
"				the cursor according to the buffer's indent
"				settings.
"   1.00.011	25-Jun-2012	BUG: Do not clobber the default register.
"	010	15-Jun-2012	Split off autoload script.
"	001	22-Jul-2006	file creation

function! s:IsNonWhitespaceAfterCursor()
    return search('\%#\s*\S', 'cn', line('.'))
endfunction
function! s:DeleteWhitespaceAroundCursor()
    " ... but only if there's still a non-whitespace after the cursor.
    if search('\%#\s\+\S', 'cn', line('.'))
	normal! "_diw
    elseif search('\%#.\s\+\S', 'cn', line('.'))
	normal! l"_diw
    elseif search('\s\%#\S', 'bn', line('.'))
	normal! h"_diw
    else
	return 0
    endif
    return 1
endfunction
if exists('*strdisplaywidth')
    function! s:GetWidthOfLine( lineNum )
	return strdisplaywidth(getline(a:lineNum))
    endfunction
    function! s:IsLineWidthSmallerThan( width )
	return strdisplaywidth(getline('.')) < a:width
    endfunction
else
    function! s:GetWidthOfLine( lineNum )
	return EchoWithoutScrolling#DetermineVirtColNum(getline(a:lineNum))
    endfunction
    function! s:IsLineWidthSmallerThan( width )
	return match(getline('.'), '\%>' . a:width . 'v$') == -1
    endfunction
endif
function! s:IsLineWidthLargerThan( width )
    return ! s:IsLineWidthSmallerThan(a:width + 1)
endfunction
function! s:GetWhitespaceAroundCursorScreenColumns()
    let l:originalCursorPos = getpos('.')
    if search('^\s*\%#', 'bcn', line('.'))
	let l:textBeforeCursorScreenColumn = 0
	normal! 0
    else
	if search('\S\s*\%#\s\|\S\s\+\%#\S', 'b', line('.'))
	    let l:textBeforeCursorScreenColumn = virtcol('.')
	    normal! l
	else
	    let l:textBeforeCursorScreenColumn = 0
	endif
    endif

    if search('\%#\s\+', 'ce', line('.'))
	let l:lastWhitespaceAfterCursorScreenColumn = virtcol('.')
    else
	let l:lastWhitespaceAfterCursorScreenColumn = 0
    endif
    call setpos('.', l:originalCursorPos)

    return [l:textBeforeCursorScreenColumn, l:lastWhitespaceAfterCursorScreenColumn]
endfunction
function! s:RenderedTabWidth( virtcol )
    let l:overflow = (a:virtcol - 1 + &l:tabstop) % &l:tabstop
    return a:virtcol + &l:tabstop - l:overflow
endfunction
function! s:RetabFromCursor()
    let l:originalLine = getline('.')
    let l:originalCursorVirtcol = virtcol('.')
    let [l:textBeforeCursorScreenColumn, l:lastWhitespaceAfterCursorScreenColumn] = s:GetWhitespaceAroundCursorScreenColumns()
    if l:lastWhitespaceAfterCursorScreenColumn == 0
	" There's no whitespace around the cursor, therefore, nothing to do.
	return
    endif

    let l:width = l:lastWhitespaceAfterCursorScreenColumn - l:textBeforeCursorScreenColumn
    if &l:expandtab
	" Replace the number of screen columns with the same number of spaces.
	let l:renderedWhitespace = repeat(' ', l:width)
    else
	" Replace the number of screen columns with the maximal amount of tabs
	" that fit into the width, followed by [0..'tabstop'[ spaces to get to the
	" exact width.
	let l:screenColumn = l:textBeforeCursorScreenColumn + 1
	let l:renderedWhitespace = ''
	while 1
	    let l:tabScreenColumn = s:RenderedTabWidth(l:screenColumn)
	    if l:tabScreenColumn <= l:lastWhitespaceAfterCursorScreenColumn + 1
		let l:renderedWhitespace .= "\t"
		let l:screenColumn = l:tabScreenColumn
	    else
		let l:renderedWhitespace .= repeat(' ', l:lastWhitespaceAfterCursorScreenColumn - l:screenColumn + 1)
		break
	    endif
	endwhile
    endif

    let l:renderedLine = substitute(l:originalLine, printf('\%%>%dv.*\%%<%dv.', l:textBeforeCursorScreenColumn, (l:lastWhitespaceAfterCursorScreenColumn + 1)), l:renderedWhitespace, '')
    call setline('.', l:renderedLine)
    execute 'normal!' l:originalCursorVirtcol . '|'
endfunction

function! AlignFromCursor#Right( width )
    if ! s:IsNonWhitespaceAfterCursor()
	" Nothing to do; there's only whitespace after the cursor.
	" The :right command also leaves whitespace-only lines alone.
	return
    endif

    " Deleting all whitespace between the left text (which is kept) and the
    " right text (which is right-aligned) serves two purposes:
    " 1. It reduces the width of lines that are longer than the desired width,
    "    so that either the width can then be increased again to reach the
    "    desired width, or the line is still longer and we've done all we could.
    "    (Analog to the :right command deleting all indent when trying to fit a
    "    long line into the desired width.)
    " 2. It avoids that <Tab> characters to the right of the cursor prevent
    "	 that the right-alignment stops short of the desired width because of a
    "	 jumping tabstop.
    call s:DeleteWhitespaceAroundCursor()

    " Insert a single <Space> until the desired width is reached. The indent is
    " corrected at the end, so that the proper <Tab> / <Space> characters are
    " used.
    let l:didInsert = 0
    while s:IsLineWidthSmallerThan(a:width)
	execute "normal! i \<Esc>"
	let l:didInsert = 1
    endwhile

    if s:IsLineWidthLargerThan(a:width) && l:didInsert
	" The last <Space> caused one following <Tab> to jump to the next
	" tabstop, and this caused the line to exceed the desired width. We
	" remove this last <Space>, so that the right-alignment command is
	" almost fulfilled, rather than overdoing it. The :right command also
	" behaves in this way.
	normal! "_x
    endif

    " Finally, change whitespace to spaces / tab / softtabstop based on buffer
    " settings.
    if l:didInsert
	call s:RetabFromCursor()
    endif
endfunction

function! AlignFromCursor#Left( width )
    " Deleting all whitespace between the left text (which is kept) and the
    " right text (which is left-aligned) serves two purposes:
    " 1. It reduces the width of lines that are longer than the desired width,
    "    so that either the width can then be increased again to reach the
    "    desired width, or the line is still longer and we've done all we could.
    "    (Analog to the :right command deleting all indent when trying to fit a
    "    long line into the desired width.)
    " 2. It avoids that <Tab> characters to the right of the cursor prevent
    "	 that the left-alignment stops short of the desired width because of a
    "	 jumping tabstop.
    call s:DeleteWhitespaceAroundCursor()

    " Calculate the number of screen columns that need to be filled with <Space>
    " characters. The indent is corrected at the end, so that the proper <Tab> /
    " <Space> characters are used.
    let l:difference = a:width - virtcol('.')

    if l:difference <= 0
	" The cursor position is already past the desired width. There's nothing
	" more we can do.
	return
    endif

    execute 'normal!' l:difference . "i \<Esc>g`["

    " Finally, change whitespace to spaces / tab / softtabstop based on buffer
    " settings.
    call s:RetabFromCursor()
endfunction

function! AlignFromCursor#DoRange( firstLine, lastLine, What, width )
    if a:firstLine == a:lastLine
	" Commonly, just the current line is processed.
	return call(a:What, [a:width])
    endif

    let l:cursorScreenColumn = virtcol('.')
    for l:line in range(a:firstLine, a:lastLine)
	execute l:line
	execute 'normal!' l:cursorScreenColumn . '|'
	call call(a:What, [a:width])
    endfor
endfunction


function! AlignFromCursor#GetTextWidth( width )
    let l:width = str2nr(a:width)
    if l:width == 0
	let l:width = &textwidth
	if l:width == 0
	    let l:width = 80
	endif
    endif
    return l:width
endfunction

function! s:LineNumFromOffset( offset )
    let l:lineNum = line('.') + a:offset
    if l:lineNum < 1 || l:lineNum > line('$')
	execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
	return -1
    endif
    return l:lineNum
endfunction
function! AlignFromCursor#RightToRelativeLine( offset )
    let l:lineNum = s:LineNumFromOffset(a:offset)
    if l:lineNum == -1 | return | endif
    call AlignFromCursor#Right(s:GetWidthOfLine(l:lineNum))
endfunction
function! AlignFromCursor#LeftToRelativeLine( offset )
    let l:lineNum = s:LineNumFromOffset(a:offset)
    if l:lineNum == -1 | return | endif
    call AlignFromCursor#Left(indent(l:lineNum) + 1)
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
