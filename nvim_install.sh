#!/bin/sh

set -e


install_dir="${1:-$HOME/nvim}"
shell_file="$HOME/.bashrc"

nvim_release="v0.9.4"
nvim_file="nvim-linux64.tar.gz"
nvim_dir="${nvim_file%.tar.gz}"
nvim_checksum="dbf4eae83647ca5c3ce1cd86939542a7b6ae49cd78884f3b4236f4f248e5d447"

rg_release="13.0.0"
rg_file="ripgrep-${rg_release}-arm-unknown-linux-gnueabihf.tar.gz"
rg_dir="${rg_file%.tar.gz}"


mkdir -p "$install_dir" && cd "$install_dir"

wget -q "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_file}"
tar -xzf "$nvim_file"
echo "alias vi='$install_dir/$nvim_dir/bin/nvim'" >> "$shell_file"

checksum=$(sha256sum nvim-linux64.tar.gz | cut -d ' ' -f 1)

if [ "$checksum" != "$nvim_checksum" ]; then
    echo "checksum mismatch"
    exit 1
fi

wget -q "https://github.com/BurntSushi/ripgrep/releases/download/${rg_release}/${rg_file}"
tar -xzf "$rg_file"
echo "alias rg='$install_dir/$rg_dir/rg'" >> "$shell_file"

git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
