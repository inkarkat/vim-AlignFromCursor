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
"	010	15-Jun-2012	Split off autoload script.
"	001	22-Jul-2006	file creation

function! s:IsNonWhitespaceAfterCursor()
    return search('\%#\s*\S', 'cn', line('.'))
endfunction
function! s:DeleteWhitespaceAroundCursor()
    " ... but only if there's still a non-whitespace after the cursor.
    if search('\%#\s\+\S', 'cn', line('.'))
	normal! diw
    elseif search('\%#.\s\+\S', 'cn', line('.'))
	normal! ldiw
    elseif search('\s\%#\S', 'bn', line('.'))
	normal! hdiw
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
	normal! x
    endif

    " Finally, change whitespace to spaces / tab / softtabstop based on buffer
    " settings. Note: This doesn't just change the just inserted spaces, but the
    " entire line!
    if l:didInsert
	.retab!
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
    " settings. Note: This doesn't just change the just inserted spaces, but the
    " entire line!
    .retab!
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
