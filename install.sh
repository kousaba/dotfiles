#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and ensure pipe failures are detected.
set -euo pipefail

# -----------------------------------------------------------------------------
# Constants & Initial Variables
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR="$HOME/.dotfiles_backup/$TIMESTAMP"
readonly PROFILE_SH="$HOME/.dotfiles_profile.sh"
readonly PROFILE_LUA_DIR="$HOME/.config/dotfiles"
readonly PROFILE_LUA="$PROFILE_LUA_DIR/profile.lua"
readonly LOCAL_BIN_DIR="$HOME/.local/bin"

# CLI Options
DRY_RUN=false
ASSUME_YES=false
VERBOSE=true

# Profile parameters
SPEC="high"         # high | low
ENV_TYPE="local"    # local | cloud
HAS_NERD_FONT=true  # true | false
HAS_SUDO=false      # true | false

# -----------------------------------------------------------------------------
# Color & Logging Setup
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
    readonly C_RESET='\033[0m'
    readonly C_BOLD='\033[1m'
    readonly C_DIM='\033[2m'
    readonly C_RED='\033[31m'
    readonly C_GREEN='\033[32m'
    readonly C_YELLOW='\033[33m'
    readonly C_BLUE='\033[34m'
    readonly C_MAGENTA='\033[35m'
    readonly C_CYAN='\033[36m'
else
    readonly C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_MAGENTA='' C_CYAN=''
fi

log_info()    { echo -e "${C_BLUE}${C_BOLD}[INFO]${C_RESET}    $*"; }
log_step()    { echo -e "${C_CYAN}${C_BOLD}[STEP]${C_RESET}    $*"; }
log_action()  { echo -e "${C_MAGENTA}${C_BOLD}[ACTION]${C_RESET}  $*"; }
log_success() { echo -e "${C_GREEN}${C_BOLD}[SUCCESS]${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET}    $*"; }
log_error()   { echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET}   $*" >&2; }
log_debug()   { [[ "$VERBOSE" == true ]] && echo -e "${C_DIM}[DEBUG]   $*${C_RESET}" || true; }

prompt_confirm() {
    if [[ "$ASSUME_YES" == true ]]; then
        log_debug "Auto-confirming (-y / --yes specified): $1"
        return 0
    fi
    read -rp "$(echo -e "${C_CYAN}${C_BOLD}[PROMPT]${C_RESET}  $1 [y/N]: ")" choice
    case "$choice" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -d, --dry-run      Simulate installation without making actual changes
    -y, --yes          Assume yes to all prompts (ideal for CI/CD or containers)
    -h, --help         Show this help message and exit
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)  DRY_RUN=true; shift ;;
            -y|--yes)      ASSUME_YES=true; shift ;;
            -h|--help)     show_help; exit 0 ;;
            *) log_error "Unknown argument: $1"; show_help; exit 1 ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# System & Hardware Diagnostics
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

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "unknown" ;;
    esac
}

check_sudo_privilege() {
    log_debug "Checking superuser privilege availability..."
    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null; then
            log_debug "Passwordless sudo is available."
            HAS_SUDO=true
        else
            log_debug "sudo binary found, password authentication may be required."
            HAS_SUDO=true
        fi
    else
        log_debug "sudo command not found on host."
        HAS_SUDO=false
    fi
}

# -----------------------------------------------------------------------------
# Interactive Profile Configuration Wizard
# -----------------------------------------------------------------------------
configure_profile() {
    echo -e "\n${C_BOLD}================================================================${C_RESET}"
    echo -e "${C_BOLD}             Target Profile Configuration Wizard                ${C_RESET}"
    echo -e "${C_BOLD}================================================================${C_RESET}"

    check_sudo_privilege

    # Automatic environment heuristics
    local detected_env="local"
    if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]]; then
        detected_env="cloud"
        log_debug "Remote SSH session detected."
    elif [[ -f /.dockerenv ]] || grep -q -i -E "docker|containerd" /proc/1/cgroup 2>/dev/null; then
        detected_env="cloud"
        log_debug "Container environment detected."
    fi

    if [[ "$ASSUME_YES" == true ]]; then
        ENV_TYPE="$detected_env"
        SPEC="high"
        HAS_NERD_FONT=true
        log_info "Default configuration loaded (--yes mode activated):"
        log_info "  Environment: $ENV_TYPE | Spec: $SPEC | Nerd Fonts: $HAS_NERD_FONT"
        return
    fi

    # 1. Environment Type
    echo -e "\n${C_CYAN}[?] Select runtime environment topology:${C_RESET}"
    echo "  1) Local Workstation (Desktop / Laptop / GUI terminal)"
    echo "  2) Cloud / Remote Host (SSH, VPS, Headless container, No sudo)"
    local env_prompt="Enter choice [1-2] (default: $( [[ "$detected_env" == "cloud" ]] && echo "2" || echo "1" )): "
    read -rp "$env_prompt" env_choice
    case "$env_choice" in
        2) ENV_TYPE="cloud" ;;
        1) ENV_TYPE="local" ;;
        *) ENV_TYPE="$detected_env" ;;
    esac
    log_debug "Selected environment: $ENV_TYPE"

    # 2. Hardware Resource Profile (Spec)
    echo -e "\n${C_CYAN}[?] Select hardware performance profile:${C_RESET}"
    echo "  1) High  (Full suite: All LSPs, rich Treesitter parsers, animated UI, Neo-tree on open)"
    echo "  2) Low   (Lightweight: Minimal background tasks, Neo-tree on-demand, lower memory footprint)"
    read -rp "Enter choice [1-2] (default: 1): " spec_choice
    case "$spec_choice" in
        2) SPEC="low" ;;
        *) SPEC="high" ;;
    esac
    log_debug "Selected spec profile: $SPEC"

    # 3. Font / Glyph Rendering Capabilities
    echo -e "\n${C_CYAN}[?] Is your terminal configured with Nerd Fonts (patched glyphs/icons)?:${C_RESET}"
    echo "  1) Yes (Enable file icons, powerline symbols, statusline glyphs)"
    echo "  2) No  (Fallback to clean ASCII characters to prevent broken boxes/tofu)"
    read -rp "Enter choice [1-2] (default: 1): " font_choice
    case "$font_choice" in
        2) HAS_NERD_FONT=false ;;
        *) HAS_NERD_FONT=true ;;
    esac
    log_debug "Selected Nerd Font capability: $HAS_NERD_FONT"

    echo ""
    log_success "Target profile committed:"
    log_info "  * Hardware Profile : ${C_BOLD}${SPEC}${C_RESET}"
    log_info "  * Runtime Host     : ${C_BOLD}${ENV_TYPE}${C_RESET}"
    log_info "  * Nerd Font Glyphs : ${C_BOLD}${HAS_NERD_FONT}${C_RESET}"
    log_info "  * Sudo Privilege   : ${C_BOLD}${HAS_SUDO}${C_RESET}"
}

save_profile_files() {
    log_step "Serializing profile configuration to disk..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[Dry-run] Would write shell profile to: $PROFILE_SH"
        log_info "[Dry-run] Would write Lua profile to:   $PROFILE_LUA"
        return
    fi

    # Shell Profile (~/.dotfiles_profile.sh)
    log_debug "Generating $PROFILE_SH"
    cat << EOF > "$PROFILE_SH"
# Auto-generated by dotfiles install.sh at $(date -u +"%Y-%m-%dT%H:%M:%SZ")
export DOTFILES_SPEC="$SPEC"
export DOTFILES_ENV="$ENV_TYPE"
export DOTFILES_NERD_FONT=$HAS_NERD_FONT
export DOTFILES_HAS_SUDO=$HAS_SUDO
EOF
    log_success "Shell profile saved: $PROFILE_SH"

    # Lua Profile (~/.config/dotfiles/profile.lua)
    mkdir -p "$PROFILE_LUA_DIR"
    log_debug "Generating $PROFILE_LUA"
    cat << EOF > "$PROFILE_LUA"
-- Auto-generated by dotfiles install.sh at $(date -u +"%Y-%m-%dT%H:%M:%SZ")
return {
  spec = "$SPEC",
  env = "$ENV_TYPE",
  has_nerd_font = $HAS_NERD_FONT,
  has_sudo = $HAS_SUDO,
}
EOF
    log_success "Neovim profile saved: $PROFILE_LUA"
}

# -----------------------------------------------------------------------------
# Neovim Installer (Multi-Platform & Rootless Portable)
# -----------------------------------------------------------------------------
install_neovim() {
    log_step "Checking Neovim installation and version compatibility..."

    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"

    local need_install=true
    if command -v nvim >/dev/null 2>&1; then
        local current_ver
        current_ver="$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")"
        log_info "Found existing Neovim binary: $(command -v nvim) (v${current_ver})"

        # Check if version is >= 0.10.0 (required for modern LSP & OSC52 APIs)
        local major minor
        major="$(echo "$current_ver" | cut -d. -f1)"
        minor="$(echo "$current_ver" | cut -d. -f2)"

        if [[ "$major" -gt 0 || ("$major" -eq 0 && "$minor" -ge 10) ]]; then
            log_success "Installed Neovim satisfies required version (>= 0.10.0)."
            need_install=false
        else
            log_warn "Installed Neovim is outdated (v${current_ver} < 0.10.0). Upgrading is strongly recommended."
        fi
    else
        log_info "Neovim binary is not present on this system."
    fi

    if [[ "$need_install" == false ]]; then
        return 0
    fi

    if ! prompt_confirm "Would you like to install/upgrade the latest release of Neovim?"; then
        log_warn "Neovim installation skipped by user choice."
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[Dry-run] Would download and configure latest Neovim for ${os}/${arch}."
        return 0
    fi

    if [[ "$os" == "macos" ]] && command -v brew >/dev/null 2>&1; then
        log_action "Installing Neovim via Homebrew..."
        brew install neovim || brew upgrade neovim
        log_success "Neovim installed successfully via Homebrew."
    else
        # Linux / WSL / Rootless: Download standalone prebuilt release archive from GitHub
        log_action "Fetching official portable binary archive from Neovim GitHub Releases..."

        local asset_name=""
        if [[ "$os" == "macos" ]]; then
            [[ "$arch" == "arm64" ]] && asset_name="nvim-macos-arm64.tar.gz" || asset_name="nvim-macos-x86_64.tar.gz"
        else
            [[ "$arch" == "arm64" ]] && asset_name="nvim-linux-arm64.tar.gz" || asset_name="nvim-linux-x86_64.tar.gz"
        fi

        local download_url="https://github.com/neovim/neovim/releases/latest/download/${asset_name}"
        local extract_dest="$HOME/.local"
        mkdir -p "$LOCAL_BIN_DIR" "$extract_dest"

        log_debug "Downloading payload: $download_url"
        local tmp_archive="/tmp/${asset_name}"

        if curl -fsSL -o "$tmp_archive" "$download_url"; then
            log_action "Extracting Neovim payload directly to $extract_dest ..."
            tar -xzf "$tmp_archive" -C "$extract_dest" --strip-components=1
            rm -f "$tmp_archive"
            log_success "Portable Neovim deployed successfully to $LOCAL_BIN_DIR/nvim"
        else
            log_error "Failed to download Neovim archive from GitHub ($download_url)."
        fi
    fi
}

# -----------------------------------------------------------------------------
# Package Management (Homebrew / Apt / Rootless Fallbacks)
# -----------------------------------------------------------------------------
install_packages() {
    log_step "Resolving system packages and prerequisites..."

    local os
    os="$(detect_os)"
    log_debug "Detected host operating system: $os"

    if [[ "$os" == "macos" ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            if prompt_confirm "Homebrew was not found. Install Homebrew package manager?"; then
                if [[ "$DRY_RUN" == false ]]; then
                    log_action "Executing Homebrew official installation script..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
            fi
        fi

        if [[ -f "$DOTFILES_DIR/Brewfile" ]] && command -v brew >/dev/null 2>&1; then
            if prompt_confirm "Install applications and CLI tools declared in Brewfile?"; then
                if [[ "$DRY_RUN" == false ]]; then
                    log_action "Running 'brew bundle' to provision bundle packages..."
                    brew bundle --file="$DOTFILES_DIR/Brewfile"
                    log_success "Homebrew bundle provisioning completed."
                fi
            fi
        fi

    elif [[ "$os" == "linux" || "$os" == "wsl" ]]; then
        if [[ "$HAS_SUDO" == true ]] && command -v apt-get >/dev/null 2>&1; then
            if prompt_confirm "Run 'apt-get' to install core utilities (git, zsh, curl, ripgrep, build tools)?"; then
                if [[ "$DRY_RUN" == false ]]; then
                    log_action "Synchronizing apt package indexes..."
                    sudo apt-get update -y
                    log_action "Installing essential packages..."
                    sudo apt-get install -y git zsh curl ripgrep tar gzip build-essential
                    log_success "Core utilities provisioned via apt-get."
                fi
            fi
        else
            log_warn "Skipping system package manager (sudo privileges unavailable or apt not found)."
            log_info "Proceeding with user-space rootless portable toolchain."
        fi
    fi

    # Install Neovim after resolving base dependencies
    install_neovim
}

# -----------------------------------------------------------------------------
# Zsh Plugins Provisioning
# -----------------------------------------------------------------------------
setup_zsh_plugins() {
    log_step "Checking and synchronizing Zsh extension modules..."

    local zsh_dir="$HOME/.zsh"
    mkdir -p "$zsh_dir"

    clone_or_update() {
        local repo_url="$1"
        local target_path="$2"
        local repo_name
        repo_name="$(basename "$target_path")"

        if [[ -d "$target_path/.git" ]]; then
            log_debug "Zsh module '$repo_name' already present. Updating..."
            if [[ "$DRY_RUN" == false ]]; then
                git -C "$target_path" pull --quiet || log_warn "Failed to update $repo_name, skipping."
            fi
        else
            log_action "Cloning Zsh plugin: $repo_name"
            if [[ "$DRY_RUN" == false ]]; then
                git clone --depth=1 --quiet "$repo_url" "$target_path"
                log_success "Synchronized plugin: $repo_name"
            fi
        fi
    }

    clone_or_update "https://github.com/romkatv/powerlevel10k.git"             "$zsh_dir/powerlevel10k"
    clone_or_update "https://github.com/zsh-users/zsh-autosuggestions.git"     "$zsh_dir/zsh-autosuggestions"
    clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$zsh_dir/zsh-syntax-highlighting"
    clone_or_update "https://github.com/zsh-users/zsh-completions.git"         "$zsh_dir/zsh-completions"
}

# -----------------------------------------------------------------------------
# Symlink Management with Automated Backups
# -----------------------------------------------------------------------------
link_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        log_warn "Source file not found: $src (skipped)"
        return
    fi

    # Already correctly linked
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        log_debug "Symlink valid and unchanged: $dest -> $src"
        return
    fi

    # Backup existing non-matching target
    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[Dry-run] Would backup conflicting file: $dest -> $BACKUP_DIR"
        else
            mkdir -p "$BACKUP_DIR"
            mv "$dest" "$BACKUP_DIR/"
            log_warn "Archived existing target: $dest -> $BACKUP_DIR/"
        fi
    fi

    # Create link
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[Dry-run] Would create symlink: $dest -> $src"
    else
        mkdir -p "$(dirname "$dest")"
        ln -snf "$src" "$dest"
        log_success "Linked: $dest -> $src"
    fi
}

setup_symlinks() {
    log_step "Deploying configuration symlinks across home directory..."

    # Neovim
    link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

    # WezTerm GUI Terminal (Excluded on cloud/remote hosts)
    if [[ "$ENV_TYPE" == "local" ]]; then
        log_debug "Linking desktop terminal configuration (WezTerm)..."
        link_file "$DOTFILES_DIR/wezterm" "$HOME/.config/wezterm"
    else
        log_info "Bypassing WezTerm configuration (Headless/Cloud environment)."
    fi

    # Git configuration
    link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    [[ -f "$DOTFILES_DIR/.gitignore_global" ]] && link_file "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

    # Zsh configuration
    link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]] && link_file "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
}

prebake_neovim() {
    log_step "Pre-baking Neovim plugins and parsers (headless mode)..."

    # ~/.local/bin を確実に PATH に含めておく
    export PATH="$LOCAL_BIN_DIR:$PATH"

    if ! command -v nvim >/dev/null 2>&1; then
        log_warn "Neovim executable not found in PATH. Skipping headless sync."
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[Dry-run] Would execute: nvim --headless '+Lazy! sync' +qa"
        return 0
    fi

    log_action "Synchronizing Lazy.nvim packages in background..."
    # --headless で起動し、同期が終わったら即終了 (+qa)
    if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
        log_success "Neovim plugins pre-baked successfully."
    else
        log_warn "Neovim pre-baking finished with warnings (normal on first run)."
    fi
}


// git user setup
setup_git_user() {
    log_step "Checking local Git identity (~/.gitconfig.local)..."

    local git_local="$HOME/.gitconfig.local"

    # すでに設定ファイルが存在する場合はスキップ（上書き防止）
    if [[ -f "$git_local" ]]; then
        log_debug "Found existing Git identity at $git_local (preserved)."
        return 0
    fi

    # CI環境など --yes オプションがついている場合の安全対策
    if [[ "$ASSUME_YES" == true ]]; then
        log_warn "Non-interactive mode: Skipping ~/.gitconfig.local creation."
        log_info "Please configure your git user manually later: git config --file ~/.gitconfig.local user.name 'Your Name'"
        return 0
    fi

    log_info "No local Git identity found. Let's configure your commit author info."

    # 現在の環境に設定が残っていればそれを初期値としてサジェスト
    local default_name default_email
    default_name="$(git config --global user.name 2>/dev/null || echo "")"
    default_email="$(git config --global user.email 2>/dev/null || echo "")"

    # 名前入力
    local name_prompt="Enter your Git User Name"
    [[ -n "$default_name" ]] && name_prompt+=" [default: $default_name]"
    read -rp "$(echo -e "${C_CYAN}[?]${C_RESET} ${name_prompt}: ")" git_name
    git_name="${git_name:-$default_name}"

    # メール入力
    local email_prompt="Enter your Git Email address"
    [[ -n "$default_email" ]] && email_prompt+=" [default: $default_email]"
    read -rp "$(echo -e "${C_CYAN}[?]${C_RESET} ${email_prompt}: ")" git_email
    git_email="${git_email:-$default_email}"

    if [[ -z "$git_name" || -z "$git_email" ]]; then
        log_warn "Git name or email was left empty. Skipping ~/.gitconfig.local creation."
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[Dry-run] Would create $git_local with name='$git_name', email='$git_email'"
        return 0
    fi

    # ~/.gitconfig.local を生成
    cat << EOF > "$git_local"
# Local machine-specific Git identity (Not tracked by dotfiles repo)
[user]
    name = $git_name
    email = $git_email
EOF
    log_success "Git identity created successfully: $git_local"
}

# -----------------------------------------------------------------------------
# Default Shell Orchestration
# -----------------------------------------------------------------------------
setup_shell() {
    log_step "Validating login shell configuration..."

    if ! command -v zsh >/dev/null 2>&1; then
        log_warn "Zsh executable not detected. Bypassing shell switch."
        return
    fi

    if [[ "$HAS_SUDO" == false && "$ENV_TYPE" == "cloud" ]]; then
        log_info "Rootless/Cloud environment detected: skipping chsh to prevent auth stalls."
        return
    fi

    local current_shell
    current_shell="$(basename "$SHELL")"
    log_debug "Active user shell reported: $current_shell"

    if [[ "$current_shell" != "zsh" ]]; then
        if prompt_confirm "Current default shell is '$current_shell'. Switch default login shell to Zsh?"; then
            local zsh_path
            zsh_path="$(command -v zsh)"
            if [[ "$DRY_RUN" == false ]]; then
                if chsh -s "$zsh_path" 2>/dev/null; then
                    log_success "Default login shell switched to: $zsh_path (effective upon next login)."
                else
                    log_warn "Failed to execute chsh automatically. Manual intervention may be required."
                fi
            fi
        fi
    else
        log_success "Zsh is already registered as your default login shell."
    fi
}

# -----------------------------------------------------------------------------
# Main Execution Entrypoint
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"

    echo -e "${C_BOLD}${C_CYAN}"
    cat << "EOF"
    DOTFILE INSTALLER
EOF
    echo -e "${C_RESET}"
    echo -e "${C_BOLD}Host Architecture : $(uname -s) ($(uname -m))${C_RESET}"
    echo -e "${C_BOLD}Execution Path    : $DOTFILES_DIR${C_RESET}"
    echo -e "${C_BOLD}Started at        : $(date)${C_RESET}"
    echo -e "${C_BOLD}----------------------------------------------------------------${C_RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Running in DRY-RUN mode. System state will remain unaltered."
    fi

    # Pipeline Execution
    configure_profile
    save_profile_files
    install_packages
    setup_zsh_plugins
    setup_git_user
    setup_symlinks
    prebake_neovim
    setup_shell

    echo -e "\n${C_BOLD}================================================================${C_RESET}"
    log_success "All dotfiles tasks finished successfully! 🚀"
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Archived superseded files preserved at: $BACKUP_DIR"
    fi
    log_info "Reload your shell: ${C_BOLD}exec zsh${C_RESET}"
    echo -e "${C_BOLD}================================================================${C_RESET}\n"
}

main "$@"
