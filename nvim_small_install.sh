#!/bin/bash

set -e

NVIMRC=$(cat <<EOF
vim.opt.scrolloff = 5

vim.opt.breakindent = true
vim.opt.copyindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.inccommand = 'nosplit'

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

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
  Plug('nvim-lua/plenary.nvim') -- dependency for telescope
  Plug('nvim-telescope/telescope.nvim', { ['branch'] = '0.1.x' })
  vim.call('plug#end')

  local tb = require('telescope.builtin')
  vim.keymap.set('n', '<leader>f', tb.find_files)
  vim.keymap.set('n', '<leader><leader>', builtin.buffers)
end

vim.cmd('colorscheme vim')
EOF
)

files_target_dir="$HOME/.local"

nvim_release="nightly" # "v0.9.4"
nvim_file="nvim-linux-x86_64.tar.gz"
nvim_dir="${nvim_file%.tar.gz}"
nvim_checksum_file="shasum.txt"

while getopts "c" opt; do
    case $opt in
        c)
            install_nvimrc=1
            ;;
        *)
            exit 1
            ;;
    esac
done

if ! echo "$PATH" | tr ':' '\n' | grep -qxF "$files_target_dir/bin"; then
    echo "WARN: $files_target_dir/bin is not part of ${PATH}!"
fi

echo "Retrieving ${nvim_file} ..."
wget -qO "${nvim_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_file}"
echo "Retrieving ${nvim_checksum_file} ..."
wget -qO "${nvim_checksum_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_checksum_file}"
if ! grep "$nvim_file" "$nvim_checksum_file" | sha256sum -c; then
    echo "ERROR: checksum mismatch"
    exit 1
fi
# Extract nvim file to nvim dir.
tar -xzf "$nvim_file"
# Distribute files.
for directory in bin lib share; do
    mkdir -p "$files_target_dir/$directory"
    cp -a "$nvim_dir/$directory/"* "$files_target_dir/$directory/"
done
# Cleanup downloaded files.
rm -r "$nvim_dir" "$nvim_file" "$nvim_checksum_file"

# Install nvim config.
if [[ -n $install_nvimrc ]]; then
  nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  mkdir -p "$nvim_config_dir"
  echo "$NVIMRC" > "$nvim_config_dir/init.lua"
fi
