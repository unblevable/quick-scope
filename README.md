# quick-scope
An always-on highlight for a unique character in every word on a line to help
you use <kbd>f</kbd>, <kbd>F</kbd> and family.

![screencast3](https://cloud.githubusercontent.com/assets/723755/8230149/6ecbed28-158b-11e5-9474-89e846e7682c.gif)

This plugin should help you get to any word on a line in two or three
keystrokes with Vim's built-in <kbd>f&lt;char&gt;</kbd> (which moves your cursor to
<kbd>&lt;char&gt;</kbd>).

+ [Overview](#overview)
  + [Features](#features)
  + [Benefits](#benefits)
+ [Installation](#installation)
+ [Options](#options)
  + [Highlight on key press](#highlight-on-key-press)
  + [Customize colors](#customize-colors)
  + [Toggle highlighting](#toggle-highlighting)
  + [Disable on long lines](#disable-plugin-on-long-lines)
  + [Blacklist buftypes](#blacklist-buftypes)
  + [Customize Accepted Characters](#accepted-characters)
  + [Lazy Highlight](#lazy-highlight)
+ [Moving Across a Line](#moving-across-a-line)
  + [Character motions](#character-motions)
  + [Other motions](#other-motions)

## Overview
When moving across a line, the <kbd>f</kbd>, <kbd>F</kbd>, <kbd>t</kbd> and
<kbd>T</kbd> motions combined with <kbd>;</kbd> and <kbd>,</kbd> should be your
go-to options for [many reasons](#advantages). Quick-scope fixes their only
drawback: it is difficult to consistently choose the right characters to
target.

### Features
+ Quick-scope highlights the first occurrences of characters to the left and
  right of your cursor (**green** in the screencast), once per word, every time
  your cursor moves.

  ![screencast0](https://cloud.githubusercontent.com/assets/723755/8228892/5cf6798e-1580-11e5-8ed4-379d676e7dba.gif)

+ If a word does not contain a first occurrence of a character but contains a
  second occurrence of a character, that character is highlighted in another
  color (**blue** in the screencast).

  ![screencast1](https://cloud.githubusercontent.com/assets/723755/8228897/6603ab28-1580-11e5-82cc-b048e3801edb.gif)

+ Quick-scope takes extra measures to avoid bombarding you with superfluous
  colors:
  + It ignores special characters since they are easy to eye and tend to only
    appear once or twice on a line.

    ![screencast2](https://cloud.githubusercontent.com/assets/723755/8229126/1abf997c-1582-11e5-872c-eff92386abca.gif)

  + By default, it samples colors from your active color scheme for its
    highlighting.

    ![screencast3](https://cloud.githubusercontent.com/assets/723755/8230149/6ecbed28-158b-11e5-9474-89e846e7682c.gif)

### Benefits
+ Highlighting is done automatically.
  + You already know what character to target before pressing any keys.
  + No more guesswork or slowing down to reason about the character motions.
+ This plugin neither introduces new motions nor overrides built-in ones.
  + You don't have to learn any new commands or mappings.
  + This helps you to become a better user of vanilla Vim.

## Installation
Use your favorite plugin manager.
```vim
" Your .vimrc

Plug 'unblevable/quick-scope'       " Plug
NeoBundle 'unblevable/quick-scope'  " xor NeoBundle
Plugin 'unblevable/quick-scope'     " xor Vundle
```
```sh
$ git clone https://github.com/unblevable/quick-scope ~/.vim/bundle/quick-scope # xor Pathogen
```

## Options
### Highlight on key press
```vim
" Your .vimrc

" Trigger a highlight in the appropriate direction when pressing these keys:
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Trigger a highlight only when pressing f and F.
let g:qs_highlight_on_keys = ['f', 'F']
```

### Customize colors
Quick-scope directly makes use of highlight groups called `QuickScopePrimary`
and `QuickScopeSecondary`. By default `QuickScopePrimary` is linked to the
`Function` group and `QuickScopeSecondary` is linked to the `Define` group. You
can customize them by adding your own `:highlight` commands.
```vim
" Your .vimrc
highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
```

However, it is recommended to put them in an `autocmd` so that they are updated
if and when the colorscheme changes. To achieve this you should put the
following block before you set `colorscheme <colorsname>` (**Note:** if you do
it after you will not see your colors).
```vim
" Your .vimrc

augroup qs_colors
  autocmd!
  autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
  autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
augroup END
```

### Toggle highlighting
Turn the highlighting on and off with a user command:
```
:QuickScopeToggle
```
Or create a custom mapping for the toggle.
```vim
" Your .vimrc

" Map the leader key + q to toggle quick-scope's highlighting in normal/visual mode.
" Note that you must use nmap/xmap instead of their non-recursive versions (nnoremap/xnoremap).
nmap <leader>q <plug>(QuickScopeToggle)
xmap <leader>q <plug>(QuickScopeToggle)
```

Setting `g:qs_enable` equal to zero will start the plugin disabled. (default: 1)
```vim
" Your .vimrc

let g:qs_enable=0
```

Additionally, setting the buffer local variable `b:qs_local_disable` will have
the same effect on a specific buffer.
```vim
let b:qs_local_disable=1
```

### Disable plugin on long lines
Turn off this plugin when the length of line is longer than `g:qs_max_chars`.
(default: 1000)
```vim
" Your .vimrc

let g:qs_max_chars=80
```

### Blacklist buftypes

Setting `g:qs_buftype_blacklist` to a list of buffer types disables the plugin when
entering certain `buftype`'s. For example, to disable this plugin when for terminals and
floating windows without filetypes set, put the following in your `vimrc`:

```vim
let g:qs_buftype_blacklist = ['terminal', 'nofile']
```

### Accepted Characters
The option `g:qs_accepted_chars` is a list of characters that quick-scope will
highlight. (default: a list of `a-z, A-Z, 0-9`)
```vim
" Your .vimrc

let g:qs_accepted_chars = [ 'a', 'b', ... etc ]
```

### Lazy Highlight
The option `g:qs_lazy_highlight` can be used to change the vanilla highlight
mode autocmd event from `CursorMoved` to `CursorHold`. This option is provided
to reduce the slowdown caused by vanilla highlight mode in large terminals.
(default: `0`)
```vim
" Your .vimrc

let g:qs_lazy_highlight = 1
```

## Moving Across a Line
This section provides a detailed look at the most common and useful options for
moving your cursor across a line in Vim. When you are aware of the existing
tools available to you and their trade-offs, you can better understand the
benefits of this plugin.

### Character motions

I unofficially refer to <kbd>f</kbd>, <kbd>F</kbd>, <kbd>t</kbd>, <kbd>T</kbd>,
<kbd>;</kbd> and <kbd>,</kbd> as the **character motions**. They form your
swiss army knife for moving across a line:

#### Advantages
+ The motions are easy to reason about. Simply choose a character and then move
  your cursor to it. (And with quick-scope, the best characters to choose are
  always identified for you.)
+ They are versatile. You can usually move your cursor to any word on a line in
  a single motion.
+ Yet they are also precise. You specify an exact location to move your cursor.
+ The key combinations are quick to execute and efficient in terms of number of
  key presses. It should only take 2 or 3 key presses to move your cursor to
  where you want it to be.
+ The <kbd>f</kbd> key in particular sits comfortably on home row of the
  keyboard.
+ Vim includes a set of two dedicated keys, <kbd>;</kbd> and <kbd>,</kbd>, just
  to make it easier to repeat the character motions and offset bad character
  targets.

#### Reference
*You can also consult Vim's excellent help docs for information about any
command using `:h <command>`.*
```
f<char> moves your cursor to the first occurrence of <char> to the right.

fg
It's just like the story of the grasshopper and the octopus.
^ > > > > > > > > > > > > > > > ^

```
```
F<char> moves your cursor to the first occurrence of <char> to the left.

Fl
All year long, the grasshopper kept burying acorns for winter,
         ^ < < < < < < < < < < ^
```
<kbd>t</kbd> and <kbd>T</kbd> can be just as useful. Notice how <kbd>tf</kbd>
is the most optimal way to reach the word `off` in the example below.
```
t<char> moves your cursor right before the first occurrence of <char> to the right.

tf
while the octopus mooched off his girlfriend and watched TV.
      ^ > > > > > > > > > ^
```
```
T<char> moves your cursor right before the first occurrence of <char> to the left.

Ts
But then the winter came, and the grasshopper died, and the octopus ate all his acorns.
                                       ^ < < < < ^
```
The character motions can take a preceding `count`, but in practice, Vim users
tend to use the <kbd>;</kbd> and <kbd>,</kbd> to repeat a character motion any
number of times.
```
; repeats the last character motion in the original direction.

fa;;
And also he got a racecar.
^ > ^
And also he got a racecar.
    ^ > > > > > ^
```
```
, repeats the last character motion in the opposite direction.

fs,
Is any of this getting through to you?
   ^ > > > > ^
Is any of this getting through to you?
 ^ < < < < < ^
```

### Other motions
+ Note that many of Vim's motions can take a preceding `count`, e.g.
  <kbd>2w</kbd> moves your cursor two words to the right. However, in most
  cases I would advise you **not** to use a `count`:
  + The number keys tend to be awkward to reach.
  + It is silly to waste time counting things before using a motion.
  + There are probably more effective ways to get to where you want in one or
    two keystrokes anyway (usually with <kbd>f</kbd> and co. or simply by
    repeating the motion).

+ <kbd>b</kbd>, <kbd>B</kbd>, <kbd>w</kbd>, <kbd>W</kbd>, <kbd>ge</kbd>,
  <kbd>gE</kbd>, <kbd>e</kbd>, <kbd>E</kbd>

  The word motions. They are usually the optimal choices for moving your cursor
  a distance of one or two words. (See `:h word` for Vim's definition of a
  word.) Take advantage of the fact that some of these keys ignore special
  characters or target the beginning or end of words.

+ <kbd>0</kbd>, <kbd>^</kbd>, <kbd>$</kbd>

  These keys let you skip to the beginning or end of a line. They are
  especially useful for repositioning your cursor for another motion on long
  lines.

  You might want to map <kbd>0</kbd> to <kbd>^</kbd> because <kbd>^</kbd> tends
  to be the preferred functionality but <kbd>0</kbd> is easier to reach.
  ```vim
  " Your .vimrc

  " Move across wrapped lines like regular lines
  noremap 0 ^ " Go to the first non-blank character of a line
  noremap ^ 0 " Just in case you need to go to the very beginning of a line
  ```

+ <kbd>h</kbd>, <kbd>l</kbd>

  Try to avoid spamming these keys at all costs, but bear in mind that they
  *are* the most optimal ways to move your cursor one or two spaces.

+ <kbd>?</kbd>, <kbd>/</kbd>

  The search keys. They are overkill for moving across a line.
  + Much of their behavior overlaps with that of the superior character
    motions.
  + <kbd>/</kbd> + `pattern` + <kbd>Return</kbd> amounts to a wildly
    inefficient number of keystrokes.
  + Searches pollute your buffer with lingering highlights.

+ <kbd>(</kbd>, <kbd>)</kbd>

  These keys let you move across sentences. (See `:h sentence` for Vim's
  definition of a sentence.) They can also be convenient when working with
  programming languages that occasionally have `!` or `?` at the end of words,
  e.g. Ruby and Elixir.
