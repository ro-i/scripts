#!/bin/bash

set -e


usage () {
    echo "usage: $0 [-i INSTALL_DIR] [-s TARGET_SHELL]"
}


install_dir="$HOME/nvim"
shell="zsh"
shell_file="$HOME/.${shell}rc"
files_target_dir="$HOME/.local"

nvim_release="nightly" # "v0.9.4"
nvim_file="nvim-linux64.tar.gz"
nvim_dir="${nvim_file%.tar.gz}"
nvim_checksum_file="nvim-linux64.tar.gz.sha256sum"

rg_release="13.0.0"
rg_file="ripgrep-${rg_release}-x86_64-unknown-linux-musl.tar.gz"
rg_dir="${rg_file%.tar.gz}"

fd_release="v8.7.1"
fd_file="fd-${fd_release}-x86_64-unknown-linux-gnu.tar.gz"
fd_dir="${fd_file%.tar.gz}"

nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh"
node_release="20"


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
wget -qO "${nvim_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_file}"
wget -qO "${nvim_checksum_file}" "https://github.com/neovim/neovim/releases/download/${nvim_release}/${nvim_checksum_file}"
if ! sha256sum -c "$nvim_checksum_file"; then
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
for directory in bin lib man share; do
    mkdir -p "$files_target_dir/$directory"
    cp -a "$nvim_dir/$directory/"* "$files_target_dir/$directory/"
done


# Install ripgrep.
# Download rg file, overwriting potentially existing file.
wget -qO "${rg_file}" "https://github.com/BurntSushi/ripgrep/releases/download/${rg_release}/${rg_file}"
# Remove potentially existing rg dir.
rm -rf "$rg_dir"
# Extract rg file to rg dir.
tar -xzf "$rg_file"
cp "$install_dir/$rg_dir/rg" "$files_target_dir/bin/"
cp "$install_dir/$rg_dir/doc/rg.1" "$files_target_dir/man/man1/"

# Install fd.
# Download fg file, overwriting potentially existing file.
wget -qO "${fd_file}" "https://github.com/sharkdp/fd/releases/download/${fd_release}/${fd_file}"
# Remove potentially existing fd dir.
rm -rf "$fd_dir"
# Extract fd file to fd dir.
tar -xzf "$fd_file"
cp "$install_dir/$fd_dir/fd" "$files_target_dir/bin/"
cp "$install_dir/$fd_dir/fd.1" "$files_target_dir/man/man1/"

# install npm/node (required for nvim LSP support).
# The nvm script seems to require bash to be executed.
PROFILE=/dev/null bash -c "wget -qO- ${nvm_url} | bash"
if ! grep -q NVM_DIR "$shell_file"; then
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$shell_file"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm' >> "$shell_file"
fi
"${shell}" -c ". ${shell_file} && . ${NVM_DIR}/nvm.sh && nvm install ${node_release}"

# Install neovim python module.
pip3 install -U pynvim

# Install nvim config.
nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
if cd "$nvim_config_dir"; then
    git pull --rebase
else
    git clone https://github.com/ro-i/kickstart.nvim.git "$nvim_config_dir"
fi
