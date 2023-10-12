alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias docker-compose='arion'
alias tts='xsel | mimic --setf duration_stretch=0.6 --setf int_f0_target_mean=130 -voice slt'
alias testtts='echo "xsel | mimic --setf duration_stretch=0.6 --setf int_f0_target_mean=120 -voice rms"'
alias ww='sudo ddcutil setvcp 60 27' # USB-C
alias pp='sudo ddcutil setvcp 60 18' # HDMI-1
set -o ignoreeof
alias bc='bc <<< '
alias gpom='git pull origin master'
alias gPom='git push origin master'
alias ga='git add '
alias gcm='git commit -m '
alias gcma='git commit --amend -m '
alias gcb='git checkout -b '
alias gc='git checkout'
alias grh='git reset --hard'
alias grhom='git reset --hard origin/master'
alias gfa='git fetch --all'
alias grom='git rebase origin/master'
alias gp='git pull'
alias gph='git pull --hard'
alias gd='git diff'
alias gs='git status'
alias gsp='git stash pop'
alias gds='git diff --staged'
alias gau='git add -u'
alias g='cd ~/git'
alias n='cd ~/git/bernadinm/nix-config'
alias vi='hx'
alias ll='exa -l'
alias ls='exa'
alias k='kubectl'
alias lsaltr='exa -al --sort=oldest --reverse'
alias pop='pop -H 127.0.0.1 -p $(pass protonmail.com/bridge/$(hostname)/smtp/password) -U $(gum filter <<< $(pass protonmail.com/emails)) -P $(pass protonmail.com/bridge/$(hostname)/smtp/port) -i'
alias mods='OPENAI_API_KEY=$(pass openai.com/$(hostname)/api-key) mods'
freshfetch # bash init

# Environment Variables
EDITOR='hx' # default editor

if test -f "$HOME/.config/navi/.navi.plugin.bash"; then
  eval "$(cat $HOME/.config/navi/.navi.plugin.bash)"
fi

# Source system wide bash settings
. /etc/profile.local
