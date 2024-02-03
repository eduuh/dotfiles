git config --local status.showUntrackedFiles no
git config --global core.editor "nvim"
git config oh-my-zsh.hide-info 1 --global

//ssh
ssh-keygen -t ed25519 -C "eduuh.muraya@outlook.com"
eval "$(ssh-agent -s)"
gh auth login

gh auth refresh -h github.com -s admin:public_key
gh ssh-key add ~/.ssh/id_ed25519.pub
