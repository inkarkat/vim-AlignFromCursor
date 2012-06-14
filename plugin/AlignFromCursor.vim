" AlignFromCursor.vim: Perform :left / :right only for the text part right of the cursor.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - vimscript #2136 repeat.vim autoload script (optional).
"   - EchoWithoutScrolling.vim autoload script (only for Vim 7.0 - 7.2).
"
" Copyright: (C) 2006-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	009	12-Dec-2011	FIX: Handle 'readonly' and 'nomodifiable'
"				buffers without function errors.
"	008	30-Aug-2011	BUG: Add forgotten s:GetTextWidth() to \ri
"				mapping.
"	007	03-Jul-2011	Add forgotten repetition for new mappings.
"	006	02-Jul-2011	Streamline implementation with the
"				strdisplaywidth() function that was introduced
"				in Vim 7.3.
"				Implement <Leader>rp and <Leader>rn mappings.
"	005	01-Feb-2009	Removed special handling "if &columns < &tw then
"				width = &columns", :right doesn't behave this
"				way, and what about vertical splits? What is it
"				for, anyway?
"				ENH: Can pass optional [width], like to :right.
"				Now requiring Vim 7.
"	004	01-Feb-2009	BF: Any (not just whitespace) char under cursor
"				was deleted when on a line longer than
"				&textwidth.
"				BF: Now only doing :retab if actually inserted
"				spaces, but not on long lines, so &modified
"				isn't set there.
"				ENH: Now also reducing long lines, either (up)
"				to alignment or by removing all whitespace
"				around the cursor and then giving up because it
"				still doesn't fit, like :right.
"				BF: By deleting all whitespace around the
"				cursor, alignment is now reached when there are
"				<Tab> characters right to the cursor, which
"				previously may have prevented this by jumping to
"				the next tabstop.
"	003	03-Sep-2008	Now handling <Tab>, double-width (^V and other
"				non-'isprint') and multi-byte characters by not
"				simply using the strlen() of the line, but
"				correctly calculating the virtual column length.
"				Now behaving like :right if the desired width
"				cannot be obtained exactly due to <Tab>s after
"				the cursor: Do not overflow the line, rather
"				stop short of the desired width.
"				Now using :.retab to convert inserted spaces
"				into tabs if the buffer settings say so.
"	002	13-Jun-2008	Added -bar to :RightAlignFromCursor.
"	0.01	22-Jul-2006	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_AlignFromCursor') || (v:version < 700)
    finish
endif
let g:loaded_AlignFromCursor = 1

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
function! s:RightAlignFromCursor( width )
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
function! s:LeftAlignFromCursor( width )
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

function! s:GetTextWidth( width )
    let l:width = str2nr(a:width)
    if l:width == 0
	let l:width = &textwidth
	if l:width == 0
	    let l:width = 80
	endif
    endif
    return l:width
endfunction

function! s:RightAlignToRelativeLine( offset )
    let l:lineNum = line('.') + a:offset
    if l:lineNum < 1 || l:lineNum > line('$')
	execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
	return
    endif

    call s:RightAlignFromCursor(s:GetWidthOfLine(l:lineNum))
endfunction

command! -bar -nargs=? RightAlignFromCursor call setline(1, getline(1)) | call <SID>RightAlignFromCursor(<SID>GetTextWidth(<q-args>))
command! -bar -nargs=? LeftAlignFromCursor  call setline(1, getline(1)) | call  <SID>LeftAlignFromCursor(<SID>GetTextWidth(<q-args>))
nnoremap <silent> <Plug>RightAlignFromCursor :<C-u>call setline(1, getline(1))<Bar>call <SID>RightAlignFromCursor(<SID>GetTextWidth(v:count))<Bar>silent! call repeat#set("\<lt>Plug>RightAlignFromCursor")<CR>
if ! hasmapto('<Plug>RightAlignFromCursor', 'n')
    nmap <silent> <Leader>ri <Plug>RightAlignFromCursor
endif
nnoremap <silent> <Plug>LeftAlignFromCursor :<C-u>call setline(1, getline(1))<Bar>call <SID>LeftAlignFromCursor(<SID>GetTextWidth(v:count))<Bar>silent! call repeat#set("\<lt>Plug>LeftAlignFromCursor")<CR>
if ! hasmapto('<Plug>LeftAlignFromCursor', 'n')
    nmap <silent> <Leader>le <Plug>LeftAlignFromCursor
endif

nnoremap <silent> <Plug>RightAlignToPreviousLine :<C-u>call setline(1, getline(1))<Bar>call <SID>RightAlignToRelativeLine(-1)<Bar>silent! call repeat#set("\<lt>Plug>RightAlignToPreviousLine")<CR>
if ! hasmapto('<Plug>RightAlignToPreviousLine', 'n')
    nmap <silent> <Leader>rp <Plug>RightAlignToPreviousLine
endif
nnoremap <silent> <Plug>RightAlignToNextLine     :<C-u>call setline(1, getline(1))<Bar>call <SID>RightAlignToRelativeLine(1) <Bar>silent! call repeat#set("\<lt>Plug>RightAlignToNextLine")<CR>
if ! hasmapto('<Plug>RightAlignToNextLine', 'n')
    nmap <silent> <Leader>rn <Plug>RightAlignToNextLine
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
