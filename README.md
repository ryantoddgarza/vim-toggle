# toggle.vim

## Usage

`+` toggles the value under the cursor in normal or visual mode. `Control-T` toggles the value under the cursor in insert-mode.

Known values are:

```
true    <->    false
on      <->    off
yes     <->    no
+       <->    -
>       <->    <
define  <->    undef
||      <->    &&
|       <->    &
```

String case is preserved as in Python `True / False`.

If the cursor is positioned on a number, the function looks for a `+` or `-` sign in front of that number and toggles it or prepends a `-` to numbers without a sign.

Toggle ignores unknown values.

### Custom mapping

Set custom mapping in _vimrc_.

```vim
imap {new_map} <Plug>ToggleI
nmap {new_map} <Plug>ToggleN
vmap {new_map} <Plug>ToggleV
```

## Installation

Install using your favorite package manager, or use Vim 8's native package support.

```sh
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git https://github.com/ryantoddgarza/vim-toggle.git
```
