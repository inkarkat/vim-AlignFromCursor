" AlignFromCursor.vim: Perform :left / :right only for the text on and right of the cursor.
"
" DEPENDENCIES:
"   - ingo/compat.vim autoload script
"   - ingo/cursor.vim autoload script
"   - ingo/folds.vim autoload script
"   - ingo/mbyte/virtcol.vim autoload script
"   - IndentTab/Info.vim autoload script (optional)
"   - vimscript #2136 repeat.vim autoload script (optional)
"   - visualrepeat.vim (vimscript #3848) autoload script (optional)
"
" Copyright: (C) 2006-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.02.019	21-Mar-2014	Replace implementation of
"				s:GetWhitespaceAroundCursorScreenColumns() with
"				a more efficient one (at least when a native
"				strdisplaywidth() is available) that does not
"				need to move around the buffer.
"				Extract AlignFromCursor#GetRetabbedFromCol() and
"				expose for reuse.
"				Determine and return success state from all
"				functions.
"   2.01.018	11-Dec-2013	Use ingo#cursor#Set().
"   2.01.017	23-Sep-2013	Support the IndentTab setting provided by the
"				optional IndentTab plugin (vimscript #4243).
"				I.e. align with spaces when there's text before
"				the cursor.
"   2.00.016	16-Jul-2013	BUG: Don't delete whitespace immediately after
"				the cursor position if the cursor rests on a
"				non-whitespace character. This makes the
"				alignment _after_ the cursor position, not
"				_from_ it.
"   2.00.015	08-Apr-2013	Use visible lines (with the help of
"				ingo#folds#NextVisibleLine()) for the relative
"				mappings.
"				Use ingo#compat#strdisplaywidth() to avoid the
"				direct dependency to EchoWithoutScrolling.vim.
"				Refactor s:LineNumFromOffset(),
"				AlignFromCursor#MappingRelative(), and the
"				called targets to take separate count and
"				direction.
"				ENH: Add visual mode mappings through
"				AlignFromCursor#VisualMapping().
"   1.12.014	10-Jan-2013	Fix slowness of :RightAlignFromCursor in
"				connection with plugins like recover.vim, caused
"				by the repeated triggers of InsertEnter /
"				InsertLeave events inserting a single space.
"				Use setline() in new s:InsertSpaces() function
"				to avoid any such events. This function also
"				automatically keeps the cursor position, and
"				avoids clobbering the ". register.
"   1.11.013	05-Dec-2012	BUG: On repeat, the original [count] is
"				overridden by the align commands, causing e.g. a
"				toggling of right-align and align to column 1 on
"				repeated <Leader>ri. Need to save the original
"				v:count and pass that to repeat#set(). Doing
"				this in new wrapper functions
"				AlignFromCursor#Mapping() and
"				AlignFromCursor#MappingRelative().
"   1.10.012	02-Aug-2012	ENH: Do not :retab the entire line (which also
"				affects leading indent and whitespace after the
"				area, just render the modified whitespace around
"				the cursor according to the buffer's indent
"				settings.
"   1.00.011	25-Jun-2012	BUG: Do not clobber the default register.
"	010	15-Jun-2012	Split off autoload script.
"	001	22-Jul-2006	file creation
let s:save_cpo = &cpo
set cpo&vim

function! s:IsNonWhitespaceAfterCursor()
    return search('\%#\s*\S', 'cn', line('.'))
endfunction
function! s:DeleteWhitespaceAroundCursor()
    " ... but only if there's still a non-whitespace after the cursor.
    if search('\%#\s\+\S', 'cn', line('.'))
	normal! "_diw
    elseif search('\s\%#\S', 'bn', line('.'))
	normal! h"_diw
    else
	return 0
    endif

    return 1
endfunction
if exists('*strdisplaywidth')
    function! s:IsLineWidthSmallerThan( width )
	return strdisplaywidth(getline('.')) < a:width
    endfunction
else
    function! s:IsLineWidthSmallerThan( width )
	return match(getline('.'), '\%>' . a:width . 'v$') == -1
    endfunction
endif
function! s:IsLineWidthLargerThan( width )
    return ! s:IsLineWidthSmallerThan(a:width + 1)
endfunction
function! s:GetWhitespaceAroundCursorScreenColumns( line, cursorCol )
    let l:textBeforeCursorCol = match(a:line, printf('\s\+\%%%dc\|\%%%dc\s', a:cursorCol, a:cursorCol))
    if l:textBeforeCursorCol == -1
	return [0, 0]
    endif

    let l:lastWhitespaceAfterCursorCol = matchend(a:line, printf('\%%%dc\s\+\|\s\ze\%%%dc\S', a:cursorCol, a:cursorCol))
    if l:lastWhitespaceAfterCursorCol == -1
	return [0, 0]
    endif

    return [ingo#compat#strdisplaywidth(strpart(a:line, 0, l:textBeforeCursorCol)), ingo#compat#strdisplaywidth(strpart(a:line, 0, l:lastWhitespaceAfterCursorCol))]
endfunction
function! s:RenderedTabWidth( virtcol )
    let l:overflow = (a:virtcol - 1 + &l:tabstop) % &l:tabstop
    return a:virtcol + &l:tabstop - l:overflow
endfunction
function! AlignFromCursor#GetRetabbedFromCol( line, col )
    let [l:textBeforeCursorScreenColumn, l:lastWhitespaceAfterCursorScreenColumn] = s:GetWhitespaceAroundCursorScreenColumns(a:line, a:col)
    if l:lastWhitespaceAfterCursorScreenColumn == 0
	" There's no whitespace around the cursor, therefore, nothing to do.
	return a:line
    endif

    let l:width = l:lastWhitespaceAfterCursorScreenColumn - l:textBeforeCursorScreenColumn

    " Integrate with the IndentTab plugin.
    let l:isIndentTab = 0
    silent! let l:isIndentTab = IndentTab#Info#IndentTab()

    if &l:expandtab || l:isIndentTab && strpart(a:line, 0, a:col - 1) =~# '\S'
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

    return substitute(a:line,
    \   printf('\%%>%dv.*\%%<%dv.',
    \       l:textBeforeCursorScreenColumn,
    \       (l:lastWhitespaceAfterCursorScreenColumn + 1)
    \   ),
    \   l:renderedWhitespace,
    \   ''
    \)
endfunction
function! s:RetabFromCursor()
    let l:originalCursorVirtcol = virtcol('.')
    call setline('.', AlignFromCursor#GetRetabbedFromCol(getline('.'), col('.')))
    call ingo#cursor#Set(0, l:originalCursorVirtcol)
endfunction
function! s:InsertSpaces( num )
    let l:line = getline('.')
    let l:col = col('.')
    call setline('.', strpart(l:line, 0, l:col - 1) . repeat(' ', a:num) . strpart(l:line, l:col - 1))
endfunction

function! AlignFromCursor#Right( width )
    if ! s:IsNonWhitespaceAfterCursor()
	" Nothing to do; there's only whitespace after the cursor.
	" The :right command also leaves whitespace-only lines alone.
	return 0
    endif

    let l:originalLine = getline('.')

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
	call s:InsertSpaces(1)
	let l:didInsert = 1
    endwhile

    if ! l:didInsert
	return 0
    endif

    if s:IsLineWidthLargerThan(a:width)
	" The last <Space> caused one following <Tab> to jump to the next
	" tabstop, and this caused the line to exceed the desired width. We
	" remove this last <Space>, so that the right-alignment command is
	" almost fulfilled, rather than overdoing it. The :right command also
	" behaves in this way.
	normal! "_x
    endif

    " Finally, change whitespace to spaces / tab / softtabstop based on buffer
    " settings.
    call s:RetabFromCursor()

    return (getline('.') !=# l:originalLine)
endfunction

function! AlignFromCursor#Left( width )
    let l:originalLine = getline('.')

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
	return 0
    endif

    call s:InsertSpaces(l:difference)

    " Finally, change whitespace to spaces / tab / softtabstop based on buffer
    " settings.
    call s:RetabFromCursor()

    return (getline('.') !=# l:originalLine)
endfunction

function! AlignFromCursor#DoRange( firstLine, lastLine, screenCol, What, ... )
    if a:firstLine == a:lastLine
	" Commonly, just the current line is processed.
	return call(a:What, a:000)
    endif

    let l:isSuccess = 0
    for l:line in range(a:firstLine, a:lastLine)
	call ingo#cursor#Set(l:line, a:screenCol)
	if call(a:What, a:000)
	    let l:isSuccess = 1
	endif
    endfor

    return l:isSuccess
endfunction


function! AlignFromCursor#GetTextWidth( width, ... )
    let l:width = str2nr(a:width)
    if l:width == 0
	let l:width = &textwidth
	if l:width == 0
	    let l:width = 80
	endif
    endif

    if a:0
	" Store for repeating the mapping.
	let s:repeatValue = l:width
    endif

    return l:width
endfunction

function! s:LineNumFromOffset( lnum, count, direction )
    let l:lineNum = ingo#folds#RelativeWindowLine(a:lnum, a:count, a:direction, -1)
    if l:lineNum < 1 || l:lineNum > line('$')
	execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
	return -1
    endif
    return l:lineNum
endfunction
function! AlignFromCursor#RightToLnum( lnum )
    return AlignFromCursor#Right(ingo#compat#strdisplaywidth(getline(a:lnum)))
endfunction
function! AlignFromCursor#RightToRelativeLine( lnum, count, direction )
    let s:repeatValue = s:LineNumFromOffset(a:lnum, a:count, a:direction)
    if s:repeatValue == -1 | return | endif
    return AlignFromCursor#RightToLnum(s:repeatValue)
endfunction
function! AlignFromCursor#LeftToLnum( lnum )
    return AlignFromCursor#Left(indent(a:lnum) + 1)
endfunction
function! AlignFromCursor#LeftToRelativeLine( lnum, count, direction )
    let s:repeatValue = s:LineNumFromOffset(a:lnum, a:count, a:direction)
    if s:repeatValue == -1 | return | endif
    return AlignFromCursor#LeftToLnum(s:repeatValue)
endfunction


function! s:Repeat( repeatMapping, repeatCount )
    silent! call       repeat#set(a:repeatMapping, a:repeatCount)

    " In the repetition of the visual mode mappings, there's no use for a count.
    silent! call visualrepeat#set(a:repeatMapping, -1)
endfunction
function! AlignFromCursor#Mapping( Func, count, repeatMapping )
    let l:isSuccess = call(a:Func, [AlignFromCursor#GetTextWidth(a:count, 1)])

    " The count given to the normal mode mapping is for overriding 'textwidth',
    " but when repeating, the count specifies the number of lines to apply it
    " to. Therefore, don't store it here.
    call s:Repeat(a:repeatMapping, 1)

    return l:isSuccess
endfunction
function! AlignFromCursor#MappingRelative( Func, lnum, count, direction, repeatMapping )
    let l:isSuccess = call(a:Func, [a:lnum, a:count, a:direction])

    " The count given to the normal mode mapping is for selecting the reference
    " line, but when repeating, the count specifies the number of lines to apply
    " it to. Therefore, don't store it here.
    call s:Repeat(a:repeatMapping, 1)

    return l:isSuccess
endfunction

function! s:GetVisualScreenColumn()
    " Use the start of the blockwise selection, or else align from the beginning
    " of the lines.
    return (visualmode() ==# "\<C-v>" ?
    \   ingo#mbyte#virtcol#GetVirtStartColOfCurrentCharacter(line("'<"), col("'<")) :
    \   1
    \)
endfunction
function! AlignFromCursor#VisualMapping( What, ... )
    let l:isSuccess = call(function('AlignFromCursor#DoRange'), [
    \   line("'<"), line("'>"), s:GetVisualScreenColumn(),
    \   a:What
    \] + a:000[0:-2])

    " When repeating the visual mapping in normal mode, default to the same
    " number of lines.
    call s:Repeat(a:000[-1], (line("'>") - line("'<") + 1))

    return l:isSuccess
endfunction


let s:repeatValue = 0
function! AlignFromCursor#RepeatMapping( What, count, repeatMapping )
    let l:isSuccess = AlignFromCursor#DoRange(
    \   line('.'), line('.') + a:count - 1, virtcol('.'),
    \   a:What, s:repeatValue
    \)

    call s:Repeat(a:repeatMapping, a:count)

    return l:isSuccess
endfunction
function! AlignFromCursor#VisualRepeatMapping( What, repeatMapping )
    let l:isSuccess = AlignFromCursor#DoRange(
    \   line("'<"), line("'>"), s:GetVisualScreenColumn(),
    \   a:What, s:repeatValue
    \)

    " When repeating the visual mapping in normal mode, default to the same
    " number of lines.
    call s:Repeat(a:repeatMapping, (line("'>") - line("'<") + 1))

    return l:isSuccess
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
