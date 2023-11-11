#!/bin/bash

set -e


install_dir_p="$(realpath 1)"
install_dir="${install_dir_p:-$HOME/nvim}"
shell="${2:-zsh}"
shell_file="$HOME/.${shell}rc"
bin_dir="$HOME/.local/bin"

nvim_release="v0.9.4"
nvim_file="nvim-linux64.tar.gz"
nvim_dir="${nvim_file%.tar.gz}"
nvim_checksum="dbf4eae83647ca5c3ce1cd86939542a7b6ae49cd78884f3b4236f4f248e5d447"

rg_release="13.0.0"
rg_file="ripgrep-${rg_release}-x86_64-unknown-linux-musl.tar.gz"
rg_dir="${rg_file%.tar.gz}"

fd_release="v8.7.1"
fd_file="fd-${fd_release}-x86_64-unknown-linux-gnu.tar.gz"
fd_dir="${fd_file%.tar.gz}"

nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh"
node_release="20"


mkdir -p "$bin_dir"
if ! echo $PATH | tr ':' '\n' | grep -qxF "$bin_dir"; then
    echo "WARN: ${bin_dir} is not part of ${PATH}!"
fi

mkdir -p "$install_dir"
cd "$install_dir"

# Install nvim.
# Download nvim file, overwriting potentially existing file.
wget -qO "${nvim_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_file}"
if [ "$(sha256sum "$nvim_file" | cut -d ' ' -f 1)" != "$nvim_checksum" ]; then
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
echo "alias vi='$install_dir/$nvim_dir/bin/nvim'" >> "$shell_file"
echo "alias vimdiff='$install_dir/$nvim_dir/bin/nvim -d'" >> "$shell_file"


# Install ripgrep.
# Download rg file, overwriting potentially existing file.
wget -qO "${rg_file}" "https://github.com/BurntSushi/ripgrep/releases/download/${rg_release}/${rg_file}"
# Remove potentially existing rg dir.
rm -rf "$rg_dir"
# Extract rg file to rg dir.
tar -xzf "$rg_file"
cp "$install_dir/$rg_dir/rg" "${bin_dir}"

# Install fd.
# Download fg file, overwriting potentially existing file.
wget -qO "${fd_file}" "https://github.com/sharkdp/fd/releases/download/${fd_release}/${fd_file}"
# Remove potentially existing fd dir.
rm -rf "$fd_dir"
# Extract fd file to fd dir.
tar -xzf "$fd_file"
cp "$install_dir/$fd_dir/fd" "${bin_dir}"

# install npm/node (required for nvim LSP support).
# The nvm script seems to require bash to be executed.
PROFILE=/dev/null bash -c "wget -qO- ${nvm_url} | bash"
if ! grep -q NVM_DIR "$shell_file"; then
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$shell_file"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm' >> "$shell_file"
fi
"${shell}" -c ". ${shell_file} && nvm install ${node_release}"

# Install neovim python module.
pip3 install -U pynvim

# Install nvim config.
nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
if cd "$nvim_config_dir"; then
    git pull --rebase
else
    git clone https://github.com/ro-i/kickstart.nvim.git "$nvim_config_dir"
fi
