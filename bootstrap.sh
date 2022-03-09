#!/bin/bash
#
# Bootstrap script for setting up a new OSX/Ubuntu machine
#
# This should be idempotent so it can be run multiple times.
#
# Some apps don't have a cask and so still need to be installed by hand. These
# include:
#
# 
#
# Notes:
#
# - If installing full Xcode, it's better to install that first from the app
#   store before running the bootstrap script. Otherwise, Homebrew can't access
#   the Xcode libraries as the agreement hasn't been accepted yet.
#
# Reading:
#

# helpers
function echo_ok() { echo -e '\033[1;32m'"$1"'\033[0m'; }
function echo_warn() { echo -e '\033[1;33m'"$1"'\033[0m'; }
function echo_error() { echo -e '\033[1;31mERROR: '"$1"'\033[0m'; }


if [[ $(uname -s) == Darwin ]];then
    echo_ok "Install starting for OSX. You may be asked for your password (for sudo)."
    # requires xcode and tools!
    xcode-select -p || exit "XCode must be installed! (use the app store)"
elif [[ $(uname -s) == Linux ]];then
    echo_ok "Install starting for Ubuntu. You may be asked for your password (for sudo)."
    echo "What's your Git Repo directory ?"
    read GIT_HOME
    sudo apt update
    sudo apt full-upgrade -y
    # chsh -s /bin/zsh
else 
    break
fi

# homebrew
if hash brew &>/dev/null; then
	echo_ok "Homebrew already installed. Getting updates..."
	brew update
	brew doctor
else
	echo_warn "Installing homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# fi

# Update homebrew recipes
brew update

if [[ $(uname -s) == Darwin ]];then
    echo_ok "Install GNU core utilities (those that come with OS X are outdated)."
    brew tap homebrew/dupes
    brew install coreutils
    brew install gnu-sed --with-default-names
    brew install gnu-tar --with-default-names
    brew install gnu-indent --with-default-names
    brew install gnu-which --with-default-names
    brew install gnu-grep --with-default-names
    brew install findutils
    brew install bash
elif [[ $(uname -s) == Linux ]];then
    echo_ok "Updating findutils and bash (those that come with Ubuntu are outdated)."
    brew tap homebrew/dupes
    brew install coreutils
    brew install findutils
    brew install bash
else 
    break
fi

PACKAGES=(
autogen
bdw-gc
berkeley-db
binutils
bison
brotli
bzip2
ca-certificates
curl
expat
gcc
gcc@5
gdbm
gettext
git
gmp
gnutls
go
gperf
guile
helm
icu4c
isl
isl@0.18
k9s
krb5
kubectx
kubernetes-cli
libevent
libffi
libgcrypt
libgpg-error
libidn2
libmpc
libnghttp2
libprelude
libpthread-stubs
libssh2
libtasn1
libtirpc
libtool
libunistring
libx11
libxau
libxcb
libxdmcp
libxext
libxml2
libxslt
linux-headers@4.4
linux-pam
lsd
m4
mpdecimal
mpfr
ncurses
nettle
openldap
openssl@1.1
p11-kit
pcre2
perl
pkg-config
postgresql
python@3.10
python@3.8
python@3.9
readline
rtmpdump
scw
sqlite
tcl-tk
thefuck
unbound
unzip
util-linux
xorgproto
xz
zlib
zstd
zsh
)

echo_ok "Installing packages..."
brew install "${PACKAGES[@]}"

echo_ok "Cleaning up..."
brew cleanup

TAPS=(
caskroom/cask
adoptopenjdk/openjdk
derailed/popeye
etopeter/tap
homebrew/cask
homebrew/core
mongodb/brew
robscott/tap
)

echo_ok "Installing taps..."
# brew install caskroom/cask/brew-cask
brew tap "${TAPS[@]}" 


CASKS=(
adobe-acrobat-reader
adoptopenjdk11
adoptopenjdk8
android-platform-tools
android-sdk
angry-ip-scanner
appcleaner
balenaetcher
burp-suite
discord
github
google-chrome
google-cloud-sdk
lens
mongodb-compass
postman
spotify
visual-studio-code
)

if [[ $(uname -s) == Darwin ]];then
    echo_ok "Installing cask apps..."
    brew cask install "${CASKS[@]}"
    echo_ok "Installing fonts..."
    brew tap caskroom/fonts
FONTS=(
	font-clear-sans
	font-consolas-for-powerline
	font-dejavu-sans-mono-for-powerline
	font-fira-code
	font-fira-mono-for-powerline
	font-inconsolata
	font-inconsolata-for-powerline
	font-liberation-mono-for-powerline
	font-menlo-for-powerline
	font-roboto
)
brew cask install "${FONTS[@]}"
else
    break
fi



echo_ok "Installing Python packages..."
PYTHON_PACKAGES=(
	ipython
	virtualenv
	virtualenvwrapper
)
sudo pip install "${PYTHON_PACKAGES[@]}"

echo_ok "Installing global npm packages..."

npm install -g aws-sam-local
npm install -g spaceship-prompt

echo_ok "Installing oh my zsh..."

if [[ -f ~/.zshrc ]]; then
	echo ''
	echo '##### Installing oh-my-zsh...'
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	# cp ~/.zshrc ~/.zshrc.orig
	# cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
	chsh -s /bin/zsh
fi

echo_ok "Configuring Github"

if [[ ! -f ~/.ssh/id_rsa ]]; then
	echo ''
	echo '##### Please enter your github username: '
	read github_user
	echo '##### Please enter your github email address: '
	read github_email

	# setup github
	if [[ $github_user && $github_email ]]; then
		# setup config
		git config --global user.name "$github_user"
		git config --global user.email "$github_email"
		git config --global github.user "$github_user"
		# git config --global github.token your_token_here
		git config --global color.ui true
		git config --global push.default current
		# VS Code support
		git config --global core.editor "code --wait"

		# set rsa key
		# curl -s -O http://github-media-downloads.s3.amazonaws.com/osx/git-credential-osxkeychain
		# chmod u+x git-credential-osxkeychain
		# sudo mv git-credential-osxkeychain "$(dirname $(which git))/git-credential-osxkeychain"
		# git config --global credential.helper osxkeychain

		# generate ssh key
		cd ~/.ssh || exit
		ssh-keygen -t rsa -C "$github_email"
		# pbcopy <~/.ssh/id_rsa.pub
		echo ''
		echo '##### The following rsa key has been copied to your clipboard: '
		cat ~/.ssh/id_rsa.pub
		echo '##### Follow step 4 to complete: https://help.github.com/articles/generating-ssh-keys'
		# ssh -T git@github.com
	fi
fi

echo_ok "Installing VS Code Extensions..."

VSCODE_EXTENSIONS=(
	AlanWalk.markdown-toc
	CoenraadS.bracket-pair-colorizer
	DavidAnson.vscode-markdownlint
	DotJoshJohnson.xml
	EditorConfig.EditorConfig
	Equinusocio.vsc-material-theme
	HookyQR.beautify
	James-Yu.latex-workshop
	PKief.material-icon-theme
	PeterJausovec.vscode-docker
	Shan.code-settings-sync
	Zignd.html-css-class-completion
	akamud.vscode-theme-onedark
	akmittal.hugofy
	anseki.vscode-color
	arcticicestudio.nord-visual-studio-code
	aws-scripting-guy.cform
	bungcip.better-toml
	christian-kohler.npm-intellisense
	christian-kohler.path-intellisense
	codezombiech.gitignore
	dansilver.typewriter
	dbaeumer.jshint
	donjayamanne.githistory
	dracula-theme.theme-dracula
	eamodio.gitlens
	eg2.vscode-npm-script
	ipedrazas.kubernetes-snippets
	loganarnett.lambda-snippets
	lukehoban.Go
	mohsen1.prettify-json
	monokai.theme-monokai-pro-vscode
	ms-python.python
	ms-vscode.azure-account
	msjsdiag.debugger-for-chrome
	robertohuertasm.vscode-icons
	robinbentley.sass-indented
	waderyan.gitblame
	whizkydee.material-palenight-theme
	whtsky.agila-theme
	zhuangtongfa.Material-theme
	foxundermoon.shell-format
	timonwong.shellcheck
)

if hash code &>/dev/null; then
	echo_ok "Installing VS Code extensions..."
	for i in "${VSCODE_EXTENSIONS[@]}"; do
		code --install-extension "$i"
	done
fi

if [[ $(uname -s) == Darwin ]];then
  echo_ok "Configuring OSX..."
  
  # Set fast key repeat rate
  # The step values that correspond to the sliders on the GUI are as follow (lower equals faster):
  # KeyRepeat: 120, 90, 60, 30, 12, 6, 2
  # InitialKeyRepeat: 120, 94, 68, 35, 25, 15
  defaults write NSGlobalDomain KeyRepeat -int 6
  defaults write NSGlobalDomain InitialKeyRepeat -int 25
  
  # Always show scrollbars
  defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
  
  # Require password as soon as screensaver or sleep mode starts
  # defaults write com.apple.screensaver askForPassword -int 1
  # defaults write com.apple.screensaver askForPasswordDelay -int 0
  
  # Show filename extensions by default
  # defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  
  # Expanded Save menu
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  
  # Expanded Print menu
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
  
  # Enable tap-to-click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  
  # Disable "natural" scroll
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
  
  echo_ok 'Running OSX Software Updates...'
  sudo softwareupdate -i -a
  
  echo_ok "Creating folder structure..."
  #[[ ! -d Wiki ]] && mkdir Wiki
  #[[ ! -d Workspace ]] && mkdir Workspace
else
    break
fi
  
echo_ok "Bootstrapping complete"
