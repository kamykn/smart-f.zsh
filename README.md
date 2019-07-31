# smart-f.zsh⛵️
Extended Vi mode f, F, t, and T key mapping for zsh.  
Read a character from the keyboard, and move to the next (or prev) occurrence of it in the BUFFER.  
smart-f.zsh is a zsh plugin inspired by [clever-f.vim](https://github.com/rhysd/clever-f.vim).

## Demo

## Installation
### zplug

```
zplug "zsh-users/zsh-completions"
```

## Usage
### f (Emacs mode)
Finding character and move to the next in the BUFFER (for [Emacs mode](http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html)).

```
# This is overriding default Emacs mode command
Ctrl-X Ctrl-F {char}
```

### f, F, t and T (Vi mode)
In vi mode `f`,` F`, `t` and` T` are overridden (for [Vi mode](http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html)).

```
# (for normal mode)
# Finding character and move to the next.
f {char}

# Finding character and move to the previous.
F {char}

# Finding character and move to the position just before the next.
t {char}

# Finding character and move to the position just before the previous.
T {char}
```

## Remapping
You can remap shortcut key.

```
# Finding character and move to the next.
bindkey '^F' smart_f_next

# Finding character and move to the previous.
bindkey '^B' smart_f_prev
```

