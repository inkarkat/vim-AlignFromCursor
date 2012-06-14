" AlignFromCursor.vim: Perform :left / :right only for the text part right of the cursor.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher
"   - AlignFromCursor.vim autoload script
"   - vimscript #2136 repeat.vim autoload script (optional)
"
" Copyright: (C) 2006-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	010	15-Jun-2012	Implement analog :LeftAlignFromCursor and
"				<Leader>ln and <Leader>lp mappings, too.
"				Rename script to AlignFromCursor.vim.
"				Split off documentation and autoload script.
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

"- commands --------------------------------------------------------------------

command! -bar -nargs=? RightAlignFromCursor call setline(1, getline(1)) | call AlignFromCursor#Right(AlignFromCursor#GetTextWidth(<q-args>))
command! -bar -nargs=? LeftAlignFromCursor  call setline(1, getline(1)) | call  AlignFromCursor#Left(AlignFromCursor#GetTextWidth(<q-args>))


"- mappings --------------------------------------------------------------------

nnoremap <silent> <Plug>RightAlignFromCursor :<C-u>call setline(1, getline(1))<Bar>call AlignFromCursor#Right(AlignFromCursor#GetTextWidth(v:count))<Bar>silent! call repeat#set("\<lt>Plug>RightAlignFromCursor")<CR>
if ! hasmapto('<Plug>RightAlignFromCursor', 'n')
    nmap <silent> <Leader>ri <Plug>RightAlignFromCursor
endif
nnoremap <silent> <Plug>LeftAlignFromCursor :<C-u>call setline(1, getline(1))<Bar>call AlignFromCursor#Left(AlignFromCursor#GetTextWidth(v:count))<Bar>silent! call repeat#set("\<lt>Plug>LeftAlignFromCursor")<CR>
if ! hasmapto('<Plug>LeftAlignFromCursor', 'n')
    nmap <silent> <Leader>le <Plug>LeftAlignFromCursor
endif

nnoremap <silent> <Plug>RightAlignToPreviousLine :<C-u>call setline(1, getline(1))<Bar>call AlignFromCursor#RightToRelativeLine(-1)<Bar>silent! call repeat#set("\<lt>Plug>RightAlignToPreviousLine")<CR>
if ! hasmapto('<Plug>RightAlignToPreviousLine', 'n')
    nmap <silent> <Leader>rp <Plug>RightAlignToPreviousLine
endif
nnoremap <silent> <Plug>RightAlignToNextLine     :<C-u>call setline(1, getline(1))<Bar>call AlignFromCursor#RightToRelativeLine(1) <Bar>silent! call repeat#set("\<lt>Plug>RightAlignToNextLine")<CR>
if ! hasmapto('<Plug>RightAlignToNextLine', 'n')
    nmap <silent> <Leader>rn <Plug>RightAlignToNextLine
endif
nnoremap <silent> <Plug>LeftAlignToPreviousLine :<C-u>call setline(1, getline(1))<Bar>call AlignFromCursor#LeftToRelativeLine(-1)<Bar>silent! call repeat#set("\<lt>Plug>LeftAlignToPreviousLine")<CR>
if ! hasmapto('<Plug>LeftAlignToPreviousLine', 'n')
    nmap <silent> <Leader>lp <Plug>LeftAlignToPreviousLine
endif
nnoremap <silent> <Plug>LeftAlignToNextLine     :<C-u>call setline(1, getline(1))<Bar>call AlignFromCursor#LeftToRelativeLine(1) <Bar>silent! call repeat#set("\<lt>Plug>LeftAlignToNextLine")<CR>
if ! hasmapto('<Plug>LeftAlignToNextLine', 'n')
    nmap <silent> <Leader>ln <Plug>LeftAlignToNextLine
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
