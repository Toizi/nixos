{ config, pkgs, ... }:
{
  home.stateVersion = "26.05";
  home.username = "mg";
  home.homeDirectory = "/home/mg";
  home.sessionPath = [
    "/home/mg/.my_scripts"
    "/home/mg/.bun/bin"
  ];

  home.packages = with pkgs; [
    sqlite # this gives the sqlite3 cli.
    sqlite.out # this gives the dynamic library that some apps may need. In general, it's considered an antipattern to add a library here.

    ripgrep
    ripgrep-all
    bat
    delta
    tmux
    eza
    fd
    htop

    git-lfs

    python3
    uv
    ruff
    ty

    rustup
    bun

    podman
    podman-compose
    pnpm
    protobuf

    tealdeer
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Marius G";
        email = "3457016+Toizi@users.noreply.github.com";
      };
      diff.algorithm = "histogram";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only --features=interactive";
      delta = {
        features = "decorations";
        side-by-side = true;
        syntax-theme = "Monokai Extended Light";
      };

      "delta \"decorations\"" = {
        commit-decoration-style = "blue ol";
        commit-style = "raw";
        file-style = "omit";
        hunk-header-decoration-style = "blue box";
        hunk-header-file-style = "red";
        hunk-header-line-number-style = "#067a00";
        hunk-header-style = "file line-number syntax";
      };

      push.autoSetupRemote = true;
    };

    ignores = [
      # nix
      "result"

      # vim
      "*~"
      "*.swp"
    ];
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "murilasso";
      plugins =  [
        "git"
      ];
    };


    history = {
      size = 999999999;
      save = 999999999;
    };

    # --- Static Aliases ---
    # Note: conditional aliases (Wayland/WSL) are handled in initExtra below
    shellAliases = {
      vim = "nvim";
      vimconfig = "pushd ~/.config/nvim; $EDITOR .; popd";
      cat = "bat";
      bathelp = "bat --plain --language=help";
      rg = "rg --colors 'path:fg:yellow'";
      ls = "eza";
      todo = "$EDITOR ~/todo.txt";
    };

    # --- Extra Init (appended to end of .zshrc) ---
    initContent = ''
      # bat-powered help function
      help() {
        "$@" --help 2>&1 | bat --plain --language=help
      }

      # don't print current dir stack when using pushd/popd
      setopt PUSHDSILENT

      _fzf_compgen_path() {
        fd --hidden --follow --exclude ".git" . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude ".git" . "$1"
      }

      _fzf_comprun() {
        local command=$1
        shift
        case "$command" in
          cd)           fzf --preview 'tree -C {} | head -200' "$@" ;;
          export|unset) fzf --preview "eval 'echo \$'{}"       "$@" ;;
          *)            fzf "$@" ;;
        esac
      }
    '';
  };
  programs.bash = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = ''rg --files --hidden -g "!.git"'';
  };

  # --- Environment Variables ---
  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
    BAT_THEME = "Monokai Extended Light";
  };

  # LazyVim, managed by lazyvim-nix: it generates init.lua, pins LazyVim and its
  # plugins, installs treesitter parsers for the enabled extras, and disables
  # mason and the runtime treesitter installer. Tools come from Nix instead.
  programs.lazyvim = {
    enable = true;

    # Lua config, copied into ~/.config/nvim/lua/{config,plugins} as store files.
    # Edit it here and rebuild; ~/.config/nvim is not writable in place.
    configFiles = ./nvim;

    # Enable extras here rather than via :LazyExtras, which would write an
    # unmanaged ~/.config/nvim/lazyvim.json and git-clone the extra's plugins.
    extras = {
      editor.snacks-picker.enable = true;
      editor.snacks-explorer.enable = true;

      coding.yanky.enable = true;
      lang = {
        docker.enable = true;
        nix.enable = true;
        python.enable = true;
        rust.enable = true;
        toml.enable = true;
        typescript.enable = true;
      };
    };

    # Plugins lazyvim-nix does not provide, so lazy.nvim would otherwise
    # git-clone them on first start. Pointing `dir` at nixpkgs makes lazy.nvim
    # treat them as local, installed plugins.
    plugins.nix-sourced = with pkgs.vimPlugins; ''
      return {
        { "saghen/blink.cmp", dir = "${blink-cmp}" },
        { "rafamadriz/friendly-snippets", dir = "${friendly-snippets}" },
        { "gbprod/yanky.nvim", dir = "${yanky-nvim}" },
        { "catppuccin/nvim", name = "catppuccin", dir = "${catppuccin-nvim}" },

        -- Ours, from nvim/plugins.
        { "Mofiqul/vscode.nvim", dir = "${vscode-nvim}" },
        { "sindrets/diffview.nvim", dir = "${diffview-nvim}" },
        { "nmac427/guess-indent.nvim", dir = "${guess-indent-nvim}" },
      }
    '';

    # List tools explicitly; the per-extra installDependencies mappings are
    # incomplete (no pyright, vtsls or nixd).
    extraPackages = with pkgs; [
      lua-language-server
      stylua

      # lang.nix: nixd replaces the extra's default nil_ls
      nixd
      nixfmt
      statix

      # lang.python
      pyright
      ruff

      # lang.rust (cargo itself comes from rustup on PATH)
      rust-analyzer

      # lang.typescript
      vtsls

      # lang.docker
      dockerfile-language-server
      docker-compose-language-service
      hadolint

      # lang.toml
      taplo
    ];
  };

  programs.tmux = {
    enable = true;

    # set prefix to ctrl + space
    prefix = "C-Space";
    disableConfirmationPrompt = false;

    # start windows numbering at 1
    baseIndex = 1;

    # fix escape not working immediately for vim
    escapeTime = 0;

    # set copy mode to vi bindings
    keyMode = "vi";

    # allow usage of mouse
    mouse = true;

    # increase scrollback buffer size
    historyLimit = 100000;

    # fix colors
    terminal = "tmux-256color";

    extraConfig = ''
      # Use v to trigger selection
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # Use y to yank current selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection
      bind-key -T copy-mode-vi Y send-keys -X copy-selection-and-cancel

      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Small adjustments with capital JKHL
      bind-key J resize-pane -D 5
      bind-key K resize-pane -U 5
      bind-key H resize-pane -L 5
      bind-key L resize-pane -R 5

      # Fullscreen
      bind-key f resize-pane -Z

      # Open splits and new windows in the active pane's directory instead of
      # the directory the session was started in.
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # THEME
      # Use explicit hex instead of the named palette colors: "white" maps to
      # color7 (#c1c1c1, a gray) in the kitty palette, not true white.
      set -g status-bg "#ffffff"
      set -g status-fg "#000000"
      set -g window-status-current-style bg=#dbe9f7,fg=#000000
      # Pad the active tab so the tinted background isn't flush against the text.
      set -g window-status-current-format ' #I:#W#F '
      set -g status-interval 5
      set -g display-time 4000
      set -g status-left ""
      # Move the session name to the right, styled to match the active tab's
      # pale-blue tint for a cohesive look.
      set -g status-right-length 60
      set -g status-right '#[bg=#dbe9f7,fg=#000000] #S #[default] #[fg=black]%H:%M#[default]'

      # Enable OSC 52 clipboard support (works over SSH)
      set -g set-clipboard on
      set -ag terminal-features ",*:clipboard"
      set -s set-clipboard on
      set -g allow-passthrough on

      # Advertise truecolor so hex colors in the status bar render exactly
      # rather than being snapped to the terminal's 256-color palette.
      set -ga terminal-features "*:RGB"

      # Forward extended key sequences to inner applications
      set -g extended-keys always

      # Use CSI u encoding format (what opencode/modern TUI apps expect)
      set -g extended-keys-format csi-u

      # Tell tmux that the outer terminal (Kitty) supports extended keys
      set -as terminal-features 'xterm*:extkeys'
    '';
  };

  home.file.".config/uv/uv.toml".text = ''
    index-strategy = "unsafe-first-match"

    # Tells uv to use python interpreters that are downloaded and managed by uv itself.
    # Prevents the use of system-wide python installations, which is usually nix-provided.
    # This is not compatible with using libraries such as `numpy`,`torch`,`opencv` that ship 
    # code compiled against system-wide libraries that are not present on a nix install.
    # Using compiled libraries leads to an infamous "ImportError: libstdc++.so.6: cannot open shared object file: No such file or directory"
    # More details here: https://wiki.nixos.org/wiki/Python#Running_Python_packages_which_requires_compilation_and/or_contains_libraries_precompiled_without_nix
    python-preference = "only-managed"
  '';
}
