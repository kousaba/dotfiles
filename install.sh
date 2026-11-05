#!/usr/bin/env bash

# エラー時に停止、未定義変数の参照で停止、パイプライン失敗検知
set -euo pipefail

# -----------------------------------------------------------------------------
# 定数・初期設定
# -----------------------------------------------------------------------------
readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# オプション用フラグ
DRY_RUN=false
ASSUME_YES=false

# カラー設定
if [[ -t 1 ]]; then
    readonly C_RESET='\033[0m'
    readonly C_BOLD='\033[1m'
    readonly C_RED='\033[31m'
    readonly C_GREEN='\033[32m'
    readonly C_YELLOW='\033[33m'
    readonly C_BLUE='\033[34m'
    readonly C_CYAN='\033[36m'
else
    readonly C_RESET='' C_BOLD='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN=''
fi

# -----------------------------------------------------------------------------
# ログ用関数
# -----------------------------------------------------------------------------
log_info()    { echo -e "${C_BLUE}${C_BOLD}[INFO]${C_RESET} $*"; }
log_success() { echo -e "${C_GREEN}${C_BOLD}[OK]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $*" >&2; }

prompt_confirm() {
    if [[ "$ASSUME_YES" == true ]]; then return 0; fi
    read -rp "$(echo -e "${C_CYAN}?${C_RESET} $1 [y/N]: ")" choice
    case "$choice" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# ヘルプ表示
# -----------------------------------------------------------------------------
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -d, --dry-run      変更を行わず、実行される処理のシミュレーション結果を表示
    -y, --yes          確認プロンプトをすべてスキップして実行 (CI等に便利)
    -h, --help         このヘルプを表示
EOF
}

# -----------------------------------------------------------------------------
# 引数解析
# -----------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)  DRY_RUN=true; shift ;;
            -y|--yes)      ASSUME_YES=true; shift ;;
            -h|--help)     show_help; exit 0 ;;
            *) log_error "未知のオプション: $1"; show_help; exit 1 ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# OS判別
# -----------------------------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            if grep -qi "microsoft" /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

# -----------------------------------------------------------------------------
# バックアップ & シンボリックリンク作成
# -----------------------------------------------------------------------------
link_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        log_warn "元ファイルが存在しません: $src (スキップ)"
        return
    fi

    # 既に正しいシンボリックリンクが貼られている場合
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        log_success "すでにリンク済み: $dest -> $src"
        return
    fi

    # バックアップ処理（既存のファイル・ディレクトリ・別リンクがある場合）
    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_warn "[Dry-run] バックアップ予定: $dest -> $BACKUP_DIR"
        else
            mkdir -p "$BACKUP_DIR"
            mv "$dest" "$BACKUP_DIR/"
            log_warn "既存ファイルを退避しました: $dest -> $BACKUP_DIR/"
        fi
    fi

    # リンク作成
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[Dry-run] リンク作成予定: $dest -> $src"
    else
        mkdir -p "$(dirname "$dest")"
        ln -snf "$src" "$dest"
        log_success "リンク作成完了: $dest -> $src"
    fi
}

# -----------------------------------------------------------------------------
# シンボリックリンクの適用
# -----------------------------------------------------------------------------
setup_symlinks() {
    log_info "シンボリックリンクを作成します..."

    # ~/.config 配下のツール
    link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    link_file "$DOTFILES_DIR/wezterm" "$HOME/.config/wezterm"

    # Git 設定
    link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    [[ -f "$DOTFILES_DIR/.gitignore_global" ]] && link_file "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

    # Zsh 設定（ホーム直下に配置する標準スタイル）
    # ※ ZDOTDIR で ~/.config/zsh にまとめている場合はそちらに合わせてパスを変更してください
    link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]] && link_file "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
}

# -----------------------------------------------------------------------------
# パッケージマネージャ・必須コマンドのセットアップ
# -----------------------------------------------------------------------------
install_packages() {
    local os
    os="$(detect_os)"
    log_info "OS環境を検出しました: $os"

    if [[ "$os" == "macos" ]]; then
        # Homebrewのインストール確認
        if ! command -v brew >/dev/null 2>&1; then
            if prompt_confirm "Homebrewが見つかりません。インストールしますか？"; then
                if [[ "$DRY_RUN" == false ]]; then
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
            fi
        fi

        # Brewfile があれば実行
        if [[ -f "$DOTFILES_DIR/Brewfile" ]] && command -v brew >/dev/null 2>&1; then
            if prompt_confirm "Brewfile からパッケージを一括インストールしますか？"; then
                if [[ "$DRY_RUN" == false ]]; then
                    brew bundle --file="$DOTFILES_DIR/Brewfile"
                fi
            fi
        fi

    elif [[ "$os" == "linux" || "$os" == "wsl" ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            if prompt_confirm "apt で主要ツール (git, zsh, curl 等) を更新・インストールしますか？"; then
                if [[ "$DRY_RUN" == false ]]; then
                    sudo apt-get update
                    sudo apt-get install -y git zsh curl ripgrep
                fi
            fi
        fi
    fi
}

# -----------------------------------------------------------------------------
# デフォルトシェルの確認・変更
# -----------------------------------------------------------------------------
setup_shell() {
    if ! command -v zsh >/dev/null 2>&1; then
        log_warn "zshがインストールされていないため、シェルの変更をスキップします。"
        return
    fi

    local current_shell
    current_shell="$(basename "$SHELL")"

    if [[ "$current_shell" != "zsh" ]]; then
        if prompt_confirm "現在のシェルは $current_shell です。デフォルトシェルを zsh に変更しますか？"; then
            local zsh_path
            zsh_path="$(command -v zsh)"
            if [[ "$DRY_RUN" == false ]]; then
                chsh -s "$zsh_path"
                log_success "デフォルトシェルを $zsh_path に変更しました。（再ログイン後に反映されます）"
            fi
        fi
    else
        log_success "デフォルトシェルは既に zsh に設定されています。"
    fi
}

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"

    echo -e "${C_BOLD}=========================================${C_RESET}"
    echo -e "${C_BOLD}      Dotfiles Installer Starting        ${C_RESET}"
    echo -e "${C_BOLD}=========================================${C_RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "ドライランモードで実行中です。ファイルは変更されません。"
    fi

    # 1. パッケージインストール
    install_packages

    # 2. リンク配置
    setup_symlinks

    # 3. デフォルトシェル設定
    setup_shell

    echo -e "${C_BOLD}=========================================${C_RESET}"
    log_success "すべてのセットアップが完了しました！🎉"
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "既存ファイルのバックアップ場所: $BACKUP_DIR"
    fi
    echo -e "${C_BOLD}=========================================${C_RESET}"
}

main "$@"
