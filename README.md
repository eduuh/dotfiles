# Harmonize
The repo that harmonise all my dot files in Windows, Mac , Linux , WSL and a docker container.

### Setup 

      echo ".cfg" >> .gitignore
      git clone git@github.com:eduuh/harmonize.git $HOME/.cfg
      config config --local status.showUntrackedFiles no
      config checkout --force
      git submodule init
      git submodule update
      
### WSL
- Fonts are install on windows, and make sure you set the nerd font in Terminal settings.

        scoop bucket add nerd-fonts
        scoop install nerd-fonts/Agave-NF  

### IDES 

#### Nvim


- Base config used are nvchad
- commands.
   - :NvCheatsheet or : leader<ch>
   - :

#### Helix

### Password Manager

#### Pass

