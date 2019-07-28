# smart-f.zsh⛵️
Extended vi-mode f, F, t, and T key mapping for zsh.  
smart-f.zsh is a zsh plugin inspired by [clever-f.vim](https://github.com/rhysd/clever-f.vim)

## demo

## Installation
### zplug

```
zplug "zsh-users/zsh-completions"
```

## How to use
デフォルトのコマンドを上書きしています

find next char

```
Ctrl-X Ctrl-F {char}
```

emacs modeではfind next charだけしか無いですが、vi-modeではf, F, t, Tも実装されています

find prev char
```
# normal mode
f {char}
F {char}
t {char}
T {char}
```

## Remapping
i recommended to remap key

```
bindkey '^f' clever_f_next
bindkey '^F' clever_f_prev
```


