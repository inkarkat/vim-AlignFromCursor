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
"   1.11.012	05-Dec-2012	BUG: On repeat, the original [count] is
"				overridden by the align commands, causing e.g. a
"				toggling of right-align and align to column 1 on
"				repeated <Leader>ri. Need to save the original
"				v:count and pass that to repeat#set(). Doing
"				this in new wrapper functions
"				AlignFromCursor#Mapping() and
"				AlignFromCursor#MappingRelative().
"   1.00.011	01-Aug-2012	Use the current line for the no-op readonly /
"				nomodifiable check instead of line 1 to avoid
"				undo reporting "2 changes".
"				FIX: Actually handle [count] in the previous /
"				next mappings, as documented.
"	010	15-Jun-2012	Implement analog :LeftAlignFromCursor and
"				<Leader>ln and <Leader>lp mappings, too.
"				Rename script to AlignFromCursor.vim.
"				Split off documentation and autoload script.
"				Support [range] for commands.
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
let s:save_cpo = &cpo
set cpo&vim

"- commands --------------------------------------------------------------------

command! -bar -range -nargs=? RightAlignFromCursor call setline(<line1>, getline(<line1>)) | call AlignFromCursor#DoRange(<line1>, <line2>, function('AlignFromCursor#Right'), AlignFromCursor#GetTextWidth(<q-args>))
command! -bar -range -nargs=? LeftAlignFromCursor  call setline(<line1>, getline(<line1>)) | call AlignFromCursor#DoRange(<line1>, <line2>, function('AlignFromCursor#Left' ), AlignFromCursor#GetTextWidth(<q-args>))


"- mappings --------------------------------------------------------------------

nnoremap <silent> <Plug>RightAlignFromCursor :<C-u>
\call setline('.', getline('.'))<Bar>
\call AlignFromCursor#Mapping('AlignFromCursor#Right', v:count, "\<lt>Plug>RightAlignFromCursor")<CR>
nnoremap <silent> <Plug>LeftAlignFromCursor :<C-u>
\call setline('.', getline('.'))<Bar>
\call AlignFromCursor#Mapping('AlignFromCursor#Left', v:count, "\<lt>Plug>LeftAlignFromCursor")<CR>

if ! hasmapto('<Plug>RightAlignFromCursor', 'n')
    nmap <silent> <Leader>ri <Plug>RightAlignFromCursor
endif
if ! hasmapto('<Plug>LeftAlignFromCursor', 'n')
    nmap <silent> <Leader>le <Plug>LeftAlignFromCursor
endif


nnoremap <silent> <Plug>RightAlignToPreviousLine :<C-u>
\call setline('.', getline('.'))<Bar>
\call AlignFromCursor#MappingRelative('AlignFromCursor#RightToRelativeLine', -1, v:count1, "\<lt>Plug>RightAlignToPreviousLine")<CR>
nnoremap <silent> <Plug>RightAlignToNextLine     :<C-u>
\call setline('.', getline('.'))<Bar>
\call AlignFromCursor#MappingRelative('AlignFromCursor#RightToRelativeLine',  1, v:count1, "\<lt>Plug>RightAlignToNextLine")<CR>
nnoremap <silent> <Plug>LeftAlignToPreviousLine :<C-u>
\call setline('.', getline('.'))<Bar>
\call AlignFromCursor#MappingRelative('AlignFromCursor#LeftToRelativeLine', -1, v:count1, "\<lt>Plug>LeftAlignToPreviousLine")<CR>
nnoremap <silent> <Plug>LeftAlignToNextLine     :<C-u>
\call setline('.', getline('.'))<Bar>
\call AlignFromCursor#MappingRelative('AlignFromCursor#LeftToRelativeLine',  1, v:count1, "\<lt>Plug>LeftAlignToNextLine")<CR>

if ! hasmapto('<Plug>RightAlignToPreviousLine', 'n')
    nmap <silent> <Leader>rp <Plug>RightAlignToPreviousLine
endif
if ! hasmapto('<Plug>RightAlignToNextLine', 'n')
    nmap <silent> <Leader>rn <Plug>RightAlignToNextLine
endif
if ! hasmapto('<Plug>LeftAlignToPreviousLine', 'n')
    nmap <silent> <Leader>lp <Plug>LeftAlignToPreviousLine
endif
if ! hasmapto('<Plug>LeftAlignToNextLine', 'n')
    nmap <silent> <Leader>ln <Plug>LeftAlignToNextLine
endif

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
