curl -fsSL https://bun.sh/install | bash
source $HOME/.bashrc
bun install -g @google/gemini-cli@latest
export PATH="$HOME/.bun/bin:$PATH"
source $HOME/.bashrc
sudo ln -s /usr/bin/bun /usr/bin/node
source $HOME/.bashrc
