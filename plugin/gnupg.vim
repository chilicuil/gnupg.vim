" Name:    gnupg.vim
" Last Change: 2012 May 31
" Maintainer:  James McCoy <vega.james@gmail.com>
" Original Author:  Markus Braun <markus.braun@krawel.de>
" Summary: Vim plugin for transparent editing of gpg encrypted files.
" License: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License
"          as published by the Free Software Foundation; either version
"          2 of the License, or (at your option) any later version.
"          See http://www.gnu.org/copyleft/gpl-2.0.txt
"
" Section: Documentation {{{1
"
" Description: {{{2
"
"   This script implements transparent editing of gpg encrypted files. The
"   filename must have a ".gpg", ".pgp" or ".asc" suffix. When opening such
"   a file the content is decrypted, when opening a new file the script will
"   ask for the recipients of the encrypted file. The file content will be
"   encrypted to all recipients before it is written. The script turns off
"   viminfo, swapfile, and undofile to increase security.
"
" Installation: {{{2
"
"   Copy the gnupg.vim file to the $HOME/.vim/plugin directory.
"   Refer to ':help add-plugin', ':help add-global-plugin' and ':help
"   runtimepath' for more details about Vim plugins.
"
"   From "man 1 gpg-agent":
"
"   ...
"   You should always add the following lines to your .bashrc or whatever
"   initialization file is used for all shell invocations:
"
"        GPG_TTY=`tty`
"        export GPG_TTY
"
"   It is important that this environment variable always reflects the out‐
"   put of the tty command. For W32 systems this option is not required.
"   ...
"
"   Most distributions provide software to ease handling of gpg and gpg-agent.
"   Examples are keychain or seahorse.
"
" Commands: {{{2
"
"   :GPGEditRecipients
"     Opens a scratch buffer to change the list of recipients. Recipients that
"     are unknown (not in your public key) are highlighted and have
"     a prepended "!". Closing the buffer makes the changes permanent.
"
"   :GPGViewRecipients
"     Prints the list of recipients.
"
"   :GPGEditOptions
"     Opens a scratch buffer to change the options for encryption (symmetric,
"     asymmetric, signing). Closing the buffer makes the changes permanent.
"     WARNING: There is no check of the entered options, so you need to know
"     what you are doing.
"
"   :GPGViewOptions
"     Prints the list of options.
"
" Variables: {{{2
"
"   g:GPGExecutable
"     If set used as gpg executable, otherwise the system chooses what is run
"     when "gpg" is called. Defaults to "gpg".
"
"   g:GPGUseAgent
"     If set to 0 a possible available gpg-agent won't be used. Defaults to 1.
"
"   g:GPGPreferSymmetric
"     If set to 1 symmetric encryption is preferred for new files. Defaults to 0.
"
"   g:GPGPreferArmor
"     If set to 1 armored data is preferred for new files. Defaults to 0
"     unless a "*.asc" file is being edited.
"
"   g:GPGPreferSign
"     If set to 1 signed data is preferred for new files. Defaults to 0.
"
"   g:GPGDefaultRecipients
"     If set, these recipients are used as defaults when no other recipient is
"     defined. This variable is a Vim list. Default is unset.
"
"   g:GPGUsePipes
"     If set to 1, use pipes instead of temporary files when interacting with
"     gnupg.  When set to 1, this can cause terminal-based gpg agents to not
"     display correctly when prompting for passwords.  Defaults to 0.
"
"   g:GPGHomedir
"     If set, specifies the directory that will be used for GPG's homedir.
"     This corresponds to gpg's --homedir option.  This variable is a Vim
"     string.
"
" Known Issues: {{{2
"
"   In some cases gvim can't decrypt files

"   This is caused by the fact that a running gvim has no TTY and thus gpg is
"   not able to ask for the passphrase by itself. This is a problem for Windows
"   and Linux versions of gvim and could not be solved unless a "terminal
"   emulation" is implemented for gvim. To circumvent this you have to use any
"   combination of gpg-agent and a graphical pinentry program:
"
"     - gpg-agent only:
"         you need to provide the passphrase for the needed key to gpg-agent
"         in a terminal before you open files with gvim which require this key.
"
"     - pinentry only:
"         you will get a popup window every time you open a file that needs to
"         be decrypted.
"
"     - gpgagent and pinentry:
"         you will get a popup window the first time you open a file that
"         needs to be decrypted.
"
" Credits: {{{2
"
"   - Mathieu Clabaut for inspirations through his vimspell.vim script.
"   - Richard Bronosky for patch to enable ".pgp" suffix.
"   - Erik Remmelzwaal for patch to enable windows support and patient beta
"     testing.
"   - Lars Becker for patch to make gpg2 working.
"   - Thomas Arendsen Hein for patch to convert encoding of gpg output.
"   - Karl-Heinz Ruskowski for patch to fix unknown recipients and trust model
"     and patient beta testing.
"   - Giel van Schijndel for patch to get GPG_TTY dynamically.
"   - Sebastian Luettich for patch to fix issue with symmetric encryption an set
"     recipients.
"   - Tim Swast for patch to generate signed files.
"   - James Vega for patches for better '*.asc' handling, better filename
"     escaping and better handling of multiple keyrings.
"
" Section: Plugin header {{{1

" guard against multiple loads {{{2
if (exists("g:loaded_gnupg") || &cp || exists("#GnuPG"))
  finish
endif
let g:loaded_gnupg = '2.5'
let g:GPGInitRun = 0

" check for correct vim version {{{2
if (v:version < 702)
  echohl ErrorMsg | echo 'plugin gnupg.vim requires Vim version >= 7.2' | echohl None
  finish
endif

" Section: Autocmd setup {{{1
augroup GnuPG
  autocmd!
  " decription
  autocmd BufReadCmd                             *.\(gpg\|asc\|pgp\) call gnupg#GPGInit(1)
  autocmd BufReadCmd                             *.\(gpg\|asc\|pgp\) call gnupg#GPGDecrypt(1)
  autocmd BufReadCmd                             *.\(gpg\|asc\|pgp\) call gnupg#GPGBufReadPost()
  autocmd FileReadCmd                            *.\(gpg\|asc\|pgp\) call gnupg#GPGInit(0)
  autocmd FileReadCmd                            *.\(gpg\|asc\|pgp\) call gnupg#GPGDecrypt(0)

  " convert all text to encrypted text before writing
  autocmd BufWriteCmd                            *.\(gpg\|asc\|pgp\) call gnupg#GPGBufWritePre()
  autocmd BufWriteCmd,FileWriteCmd               *.\(gpg\|asc\|pgp\) call gnupg#GPGInit(0)
  autocmd BufWriteCmd,FileWriteCmd               *.\(gpg\|asc\|pgp\) call gnupg#GPGEncrypt()

  " cleanup on leaving vim
  autocmd VimLeave                               *.\(gpg\|asc\|pgp\) call gnupg#GPGCleanup()
augroup END

" Section: Constants {{{1
let g:GPGMagicString = "\t \t"
let g:GPGkeyPattern = '\%(0x\)\=[[:xdigit:]]\{8,16}'

" Section: Highlight setup {{{1
highlight default link GPGWarning WarningMsg
highlight default link GPGError ErrorMsg
highlight default link GPGHighlightUnknownRecipient ErrorMsg

" Section: Commands {{{1
command! GPGViewRecipients call gnupg#GPGViewRecipients()
command! GPGEditRecipients call gnupg#GPGEditRecipients()
command! GPGViewOptions call gnupg#GPGViewOptions()
command! GPGEditOptions call gnupg#GPGEditOptions()

" Section: Menu {{{1
if (has("menu"))
  amenu <silent> Plugin.GnuPG.View\ Recipients :GPGViewRecipients<CR>
  amenu <silent> Plugin.GnuPG.Edit\ Recipients :GPGEditRecipients<CR>
  amenu <silent> Plugin.GnuPG.View\ Options :GPGViewOptions<CR>
  amenu <silent> Plugin.GnuPG.Edit\ Options :GPGEditOptions<CR>
endif

" vim600: set foldmethod=marker foldlevel=0 :
