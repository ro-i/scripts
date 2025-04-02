#!/bin/bash

set -e

NVIMRC=$(cat <<EOF
vim.opt.number = true
vim.opt.scrolloff = 5

vim.opt.mouse = 'a'

vim.opt.breakindent = true
vim.opt.copyindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.inccommand = 'nosplit'

vim.cmd [[
let data_dir = stdpath('data') . '/site'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source \$MYVIMRC
endif
]]

do
  local Plug = vim.fn['plug#']
  vim.call('plug#begin')
  Plug('llvm/llvm.vim')
  Plug('folke/tokyonight.nvim')
  vim.call('plug#end')
end

-- Color schemes should be loaded after plug#end().
vim.cmd('silent! colorscheme tokyonight-storm')
EOF
)

usage () {
    echo "usage: $0 [-i INSTALL_DIR] [-s TARGET_SHELL]"
}


install_dir="$HOME/nvim"
shell="bash"
shell_file="$HOME/.${shell}rc"
files_target_dir="$HOME/.local"

nvim_release="nightly" # "v0.9.4"
nvim_file="nvim-linux-x86_64.tar.gz"
nvim_dir="${nvim_file%.tar.gz}"
nvim_checksum_file="shasum.txt"

while getopts "hi:s:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        i)
            install_dir="$(realpath "$OPTARG")"
            ;;
        s)
            shell="$OPTARG"
            shell_file="$HOME/.${shell}rc"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Create necessary distribution target directories in $HOME if they don't already exist.
for directory in bin lib man share; do
    mkdir -p "$files_target_dir/$directory"
done
# We also need the necessary subdirectory in man.
mkdir -p "$files_target_dir/man/man1"

if ! echo "$PATH" | tr ':' '\n' | grep -qxF "$files_target_dir/bin"; then
    echo "WARN: $files_target_dir/bin is not part of ${PATH}!"
fi

mkdir -p "$install_dir"
cd "$install_dir"

# Install nvim.
# Download nvim file, overwriting potentially existing file.
echo "Retrieving ${nvim_file} ..."
wget -qO "${nvim_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_file}"
echo "Retrieving ${nvim_checksum_file} ..."
wget -qO "${nvim_checksum_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_checksum_file}"
if ! grep "$nvim_file" "$nvim_checksum_file" | sha256sum -c; then
    echo "ERROR: checksum mismatch"
    exit 1
fi
# Remove potentially existing nvim dir.
rm -rf "$nvim_dir"
# Extract nvim file to nvim dir.
tar -xzf "$nvim_file"
# Remove old shell aliases.
sed -i '/^alias vi=/d' "$shell_file"
sed -i '/^alias vimdiff=/d' "$shell_file"
# Insert new shell aliases.
echo "alias vi='nvim'" >> "$shell_file"
echo "alias vimdiff='nvim -d'" >> "$shell_file"
# Distribute files.
for directory in bin lib share; do
    mkdir -p "$files_target_dir/$directory"
    cp -a "$nvim_dir/$directory/"* "$files_target_dir/$directory/"
done

# Install nvim config.
nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
mkdir -p "$nvim_config_dir"
echo "$NVIMRC" > "$nvim_config_dir/test.lua"
