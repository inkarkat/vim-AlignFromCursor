" AlignFromCursor.vim: Perform :left / :right only for the text on and right of the cursor.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher
"   - AlignFromCursor.vim autoload script
"
" Copyright: (C) 2006-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.02.014	21-Mar-2014	Mappings beep when their application didn't
"				cause any change to the buffer.
"   2.00.013	08-Apr-2013	Refactor AlignFromCursor#MappingRelative()
"				invocation.
"				ENH: Add visual mode mappings for the relative
"				mappings that work on the selection and take the
"				[count]'th above / below line.
"				ENH: Add visual mode mappings for the align
"				mappings that work on the selection.
"				CHG: Make repeats of the mappings use the
"				previous width instead of just re-applying them
"				at the current cursor position. DWIM.
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

command! -bar -range -nargs=? RightAlignFromCursor call setline(<line1>, getline(<line1>)) | call AlignFromCursor#DoRange(<line1>, <line2>, virtcol('.'), function('AlignFromCursor#Right'), AlignFromCursor#GetTextWidth(<q-args>))
command! -bar -range -nargs=? LeftAlignFromCursor  call setline(<line1>, getline(<line1>)) | call AlignFromCursor#DoRange(<line1>, <line2>, virtcol('.'), function('AlignFromCursor#Left' ), AlignFromCursor#GetTextWidth(<q-args>))


"- mappings --------------------------------------------------------------------

" Align from cursor {{{1
nnoremap <silent> <Plug>RightAlignFromCursor :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#Mapping('AlignFromCursor#Right', v:count, "\<lt>Plug>RightAlignRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
nnoremap <silent> <Plug>LeftAlignFromCursor :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#Mapping('AlignFromCursor#Left',  v:count, "\<lt>Plug>LeftAlignRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>

if ! hasmapto('<Plug>RightAlignFromCursor', 'n')
    nmap <silent> <Leader>ri <Plug>RightAlignFromCursor
endif
if ! hasmapto('<Plug>LeftAlignFromCursor', 'n')
    nmap <silent> <Leader>le <Plug>LeftAlignFromCursor
endif

vnoremap <silent> <Plug>RightAlignFromCursor :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualMapping('AlignFromCursor#Right', AlignFromCursor#GetTextWidth(v:count, 1), "\<lt>Plug>RightAlignRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>LeftAlignFromCursor :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualMapping('AlignFromCursor#Left',  AlignFromCursor#GetTextWidth(v:count, 1), "\<lt>Plug>LeftAlignRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>

if ! hasmapto('<Plug>RightAlignFromCursor', 'x')
    xmap <silent> <Leader>ri <Plug>RightAlignFromCursor
endif
if ! hasmapto('<Plug>LeftAlignFromCursor', 'x')
    xmap <silent> <Leader>le <Plug>LeftAlignFromCursor
endif

" Repeats {{{2
nnoremap <silent> <Plug>LeftAlignRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#RepeatMapping('AlignFromCursor#Left',  v:count1, "\<lt>Plug>LeftAlignRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
nnoremap <silent> <Plug>RightAlignRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#RepeatMapping('AlignFromCursor#Right', v:count1, "\<lt>Plug>RightAlignRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>LeftAlignRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualRepeatMapping('AlignFromCursor#Left',  "\<lt>Plug>LeftAlignRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>RightAlignRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualRepeatMapping('AlignFromCursor#Right', "\<lt>Plug>RightAlignRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
"}}}2 }}}1


" Align to adjacent {{{1
nnoremap <silent> <Plug>RightAlignToPreviousLine :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#MappingRelative('AlignFromCursor#RightToRelativeLine', line('.'), v:count1, -1, "\<lt>Plug>RightAlignToRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
nnoremap <silent> <Plug>RightAlignToNextLine     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#MappingRelative('AlignFromCursor#RightToRelativeLine', line('.'), v:count1,  1, "\<lt>Plug>RightAlignToRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
nnoremap <silent> <Plug>LeftAlignToPreviousLine :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#MappingRelative('AlignFromCursor#LeftToRelativeLine',  line('.'), v:count1, -1, "\<lt>Plug>LeftAlignToRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
nnoremap <silent> <Plug>LeftAlignToNextLine     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#MappingRelative('AlignFromCursor#LeftToRelativeLine',  line('.'), v:count1,  1, "\<lt>Plug>LeftAlignToRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>

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


vnoremap <silent> <Plug>RightAlignToPreviousLine :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualMapping('AlignFromCursor#RightToRelativeLine', "'<", v:count1, -1, "\<lt>Plug>RightAlignToRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>RightAlignToNextLine     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualMapping('AlignFromCursor#RightToRelativeLine', "'>", v:count1,  1, "\<lt>Plug>RightAlignToRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>LeftAlignToPreviousLine :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualMapping('AlignFromCursor#LeftToRelativeLine', "'<", v:count1,  -1, "\<lt>Plug>LeftAlignToRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>LeftAlignToNextLine     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualMapping('AlignFromCursor#LeftToRelativeLine', "'>", v:count1,   1, "\<lt>Plug>LeftAlignToRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>

if ! hasmapto('<Plug>RightAlignToPreviousLine', 'x')
    xmap <silent> <Leader>rp <Plug>RightAlignToPreviousLine
endif
if ! hasmapto('<Plug>RightAlignToNextLine', 'x')
    xmap <silent> <Leader>rn <Plug>RightAlignToNextLine
endif
if ! hasmapto('<Plug>LeftAlignToPreviousLine', 'x')
    xmap <silent> <Leader>lp <Plug>LeftAlignToPreviousLine
endif
if ! hasmapto('<Plug>LeftAlignToNextLine', 'x')
    xmap <silent> <Leader>ln <Plug>LeftAlignToNextLine
endif

" Repeats {{{2
nnoremap <silent> <Plug>LeftAlignToRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#RepeatMapping('AlignFromCursor#LeftToLnum',  v:count1, "\<lt>Plug>LeftAlignToRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
nnoremap <silent> <Plug>RightAlignToRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#RepeatMapping('AlignFromCursor#RightToLnum', v:count1, "\<lt>Plug>RightAlignToRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>LeftAlignToRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualRepeatMapping('AlignFromCursor#LeftToLnum',  "\<lt>Plug>LeftAlignToRepeat" )<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
vnoremap <silent> <Plug>RightAlignToRepeat     :<C-u>
\call setline('.', getline('.'))<Bar>
\if ! AlignFromCursor#VisualRepeatMapping('AlignFromCursor#RightToLnum', "\<lt>Plug>RightAlignToRepeat")<Bar>execute "normal! \<lt>C-\>\<lt>C-n>\<lt>Esc>"<Bar>endif<CR>
"}}}2 }}}1

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
