# zsh/.zshrc

# --- プロファイル読み込み ---
[[ -f "$HOME/.dotfiles_profile.sh" ]] && source "$HOME/.dotfiles_profile.sh"

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# --- 1. 基本・履歴設定 ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history
setopt extended_history
setopt hist_ignore_space
setopt hist_reduce_blanks

# --- 2. ディレクトリ移動 ---
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

# --- 3. 補完設定 ---
[[ -d ~/.zsh/zsh-completions/src ]] && fpath=(~/.zsh/zsh-completions/src $fpath)

autoload -U compinit && compinit
autoload -Uz colors && colors

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:processes' command 'ps -A'
zstyle ':completion:*:default' menu select=1
setopt correct

# --- 4. キーバインド・検索 ---
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# --- 5. プロンプト設定 ---
if [[ -f ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme
fi

# --- 6. 外部ツール・プラグイン ---
# 1. eza (Nerd Font の有無でアイコンを切り替え)
if (( $+commands[eza] )); then
  if [[ "${DOTFILES_NERD_FONT:-true}" == "true" ]]; then
    alias ls='eza --icons'
    alias ll='eza -la --icons --git'
    alias lt='eza --tree --level=2 --icons'
  else
    alias ls='eza'
    alias ll='eza -la --git'
    alias lt='eza --tree --level=2'
  fi
fi

# 2. bat
if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
  alias preview='bat'
fi

# 3. ripgrep
if (( $+commands[rg] )); then
  alias grep='rg'
fi

# 4. fd
if (( $+commands[fd] )); then
  alias find='fd'
fi

# 5. zoxide
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)"
fi

# プラグインが存在する場合のみ source
[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# p10k設定
## --- 5. プロンプト設定 ---
if [[ -f ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme

  # Nerd Fonts の有無に応じて p10k 設定を切り替え
  if [[ "${DOTFILES_NERD_FONT:-true}" == "true" ]]; then
    [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
  else
    [[ -f ~/.dotfiles/zsh/.p10k.ascii.zsh ]] && source ~/.dotfiles/zsh/.p10k.ascii.zsh
  fi
fi
