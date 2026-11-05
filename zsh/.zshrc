# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"

# --- 1. 基本・履歴設定 ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history
setopt extended_history
setopt hist_ignore_space      # [追加] スペース始まりは履歴に残さない
setopt hist_reduce_blanks     # [追加] 余分な空白を除去

# --- 2. ディレクトリ移動 ---
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

# --- 3. 補完設定 ---
# ※ compinit の前に fpath を追加するのが必須
fpath=(~/.zsh/zsh-completions/src $fpath)

autoload -U compinit && compinit
autoload -Uz colors && colors

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:processes' command 'ps -A'
zstyle ':completion:*:default' menu select=1   # [追加] 補完候補を矢印キーで選択可能に
setopt correct

# --- 4. キーバインド・検索 ---
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# --- 5. プロンプト設定 ---
source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme

# --- 6. エイリアス ---

# --- 7. 外部ツール・プラグイン（末尾で読み込む） ---
# 1. eza (ls の置き換え)
if (( $+commands[eza] )); then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'          # 詳細リスト表示 + Gitステータス表示
  alias lt='eza --tree --level=2 --icons'   # 2階層までのツリー表示
fi

# 2. bat (cat の置き換え)
if (( $+commands[bat] )); then
  alias cat='bat --paging=never'           # 通常のcatと同じく一気に出力
  alias preview='bat'                      # ページャー（lessのようにスクロール）で見る用
fi

# 3. ripgrep (grep の置き換え)
if (( $+commands[rg] )); then
  alias grep='rg'
fi

# 4. fd (find の置き換え)
if (( $+commands[fd] )); then
  alias find='fd'
fi

# 5. zoxide
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)"
fi

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
# syntax-highlighting は一番最後に source する
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
