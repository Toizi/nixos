{ config, pkgs, ... }:
{
  home.stateVersion = "26.05";
  home.username = "mg";
  home.homeDirectory = "/home/mg";
  home.sessionPath = [
    "/home/mg/.my_scripts"
    "/home/mg/.bun/bin"
  ];

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Original-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  home.packages = with pkgs; [
    sqlite # this gives the sqlite3 cli.
    sqlite.out # this gives the dynamic library that some apps may need. In general, it's considered an antipattern to add a library here.

    # llm agent launcher (packages injected from flake.nix)

    ripgrep
    ripgrep-all
    bat
    delta
    tmux
    eza
    fd
    htop

    # custom font
    nerd-fonts.iosevka-term

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

    mermaid-cli

    # Rust development
    # (rust-bin.stable.latest.default.override {
    #  extensions = [ "rust-src" ];
    # })
    wofi
    waybar
    keepassxc
    wl-clipboard-rs
    tealdeer

    spotify
    signal-desktop
    portfolio
    vlc
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

    profileExtra = ''
      if command -v start-hyprland > /dev/null \
        && [ -z "''${DISPLAY}" ] \
        && [ -z "''${WAYLAND_DISPLAY}" ] \
        && [ "''${XDG_VTNR:-0}" -eq 1 ]; then

        # General Wayland hints
        export SDL_VIDEODRIVER=wayland
        export _JAVA_AWT_WM_NONREPARENTING=1
        export QT_QPA_PLATFORM=wayland
        export MOZ_ENABLE_WAYLAND=1

        # Hyprland session identity
        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        export XDG_SESSION_TYPE=wayland

        # Optional: only if you actually need it
        # export WLR_NO_HARDWARE_CURSORS=1
        # export XWAYLAND_NO_GLAMOR=1

        exec ssh-agent systemd-cat --identifier=hyprland start-hyprland
      fi

    '';

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
      setclip = "wl-copy";
      getclip = "wl-paste";
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

  programs.alacritty = {
    enable = true;

    settings = {
      colors = {
        primary = {
          background = "#FCFCFC";
          foreground = "#5C6166";
        };

        normal = {
          black = "#010101";
          blue = "#4196df";
          cyan = "#51b891";
          green = "#80ab24";
          magenta = "#9870c3";
          red = "#e7666a";
          white = "#c1c1c1";
          yellow = "#eba54d";
        };

        bright = {
          black = "#343434";
          blue = "#6daee6";
          cyan = "#75c7a8";
          green = "#9fd32f";
          magenta = "#b294d2";
          red = "#ee9295";
          white = "#dbdbdb";
          yellow = "#f0bc7b";
        };
      };

      font = {
        size = 14.0;
        normal = {
          family = "IosevkaTerm NF";
        };
      };

      keyboard.bindings = [
        {
          key = "_";
          mods = "Shift|Control";
          mode = "~Search";
          action = "ToggleViMode";
        }
        {
          key = 53;
          mods = "Shift";
          mode = "Vi|~Search";
          action = "SearchBackward";
        }
        {
          key = "Y";
          mode = "Vi|~Search";
          action = "Copy";
        }
        {
          key = "Y";
          mode = "Vi|~Search";
          action = "ClearSelection";
        }
        {
          key = "Y";
          mode = "Vi|~Search";
          action = "ToggleViMode";
        }
        {
          key = "Return";
          mods = "Super|Control";
          action = "SpawnNewInstance";
        }
        {
          key = "Return";
          mods = "Shift";
          chars = "\\n";
        }
      ];

      scrolling.history = 100000;

      window.padding = {
        x = 2;
        y = 0;
      };
    };
  };

  programs.kitty = {
    enable = true;

    font = {
      name = "IosevkaTerm Nerd Font Mono";
      size = 14.0;
    };

    settings = {
      macos_quit_when_last_window_closed = true;

      scrollback_pager = "nvim --cmd 'set eventignore=FileType' +'set notermguicolors' +'hi Visual cterm=reverse' +'nnoremap q ZQ' +'vnoremap y \"+y:execute \"normal ZQ\"\<CR>' +'call nvim_open_term(0, {})' +'set nomodified nolist' +'$' -";

      # ── Scrollback (≈ history-limit 100000) ───────────────────────────────
      scrollback_lines = 100000;

      # ── Mouse ─────────────────────────────────────────────────────────────
      mouse_hide_wait = 0; # keep mouse visible (you had mouse on)
      focus_follows_mouse = false; # ≈ focus-events off

      # ── Performance / behavior ────────────────────────────────────────────
      input_delay = 0; # ≈ escape-time 0
      repaint_delay = 10;

      # ── Tab bar (≈ tmux status bar) ───────────────────────────────────────
      tab_bar_style = "powerline";
      tab_bar_edge = "bottom";
      tab_powerline_style = "slanted";
      active_tab_foreground = "#000000";
      active_tab_background = "#00aa00"; # ≈ window-status-current-style bg=green
      inactive_tab_foreground = "#000000";
      inactive_tab_background = "#ffffff"; # ≈ status-bg white / status-fg black
      tab_title_template = "{index}: {title}";

      # ── Layouts ───────────────────────────────────────────────────────────
      enabled_layouts = "splits,stack,tall,fat";

      # ── Window resize (dragging borders) ─────────────────────────────────
      resize_in_steps = false;

      foreground = "#5C6166";
      background = "#FCFCFC";

      # Selection
      selection_foreground = "#FCFCFC";
      selection_background = "#5C6166";

      # Cursor
      cursor = "#5C6166";
      cursor_text_color = "#FCFCFC";

      # Normal colors (0–7)
      color0 = "#010101"; # black
      color1 = "#e7666a"; # red
      color2 = "#80ab24"; # green
      color3 = "#eba54d"; # yellow
      color4 = "#4196df"; # blue
      color5 = "#9870c3"; # magenta
      color6 = "#51b891"; # cyan
      color7 = "#c1c1c1"; # white

      # Bright colors (8–15)
      color8 = "#343434"; # bright black
      color9 = "#ee9295"; # bright red
      color10 = "#9fd32f"; # bright green
      color11 = "#f0bc7b"; # bright yellow
      color12 = "#6daee6"; # bright blue
      color13 = "#b294d2"; # bright magenta
      color14 = "#75c7a8"; # bright cyan
      color15 = "#dbdbdb"; # bright white

      # Light theme rendering
      text_composition_strategy = "2.2 30";
    };

    keybindings = {
      # ── Disable kitty's default kitty_mod bindings we're replacing ────────
      # (kitty_mod defaults to ctrl+shift; leave those alone unless they
      #  conflict — they won't since our leader is ctrl+space)

      # # ── Tabs (≈ tmux windows) ─────────────────────────────────────────────
      # "ctrl+space>c" = "new_tab_with_cwd";
      # "ctrl+space>n" = "next_tab";
      # "ctrl+space>p" = "previous_tab";
      # "ctrl+space>1" = "goto_tab 1";
      # "ctrl+space>2" = "goto_tab 2";
      # "ctrl+space>3" = "goto_tab 3";
      # "ctrl+space>4" = "goto_tab 4";
      # "ctrl+space>5" = "goto_tab 5";
      # "ctrl+space>6" = "goto_tab 6";
      # "ctrl+space>7" = "goto_tab 7";
      # "ctrl+space>8" = "goto_tab 8";
      # "ctrl+space>9" = "goto_tab 9";
      # "ctrl+space>," = "set_tab_title";
      #
      # # ── Splits/Panes (≈ tmux panes) ───────────────────────────────────────
      # # % → vertical split (side by side)
      # "ctrl+space>shift+5" = "launch --location=vsplit --cwd=current";
      # # " → horizontal split (top/bottom)
      # "ctrl+space>shift+apostrophe" = "launch --location=hsplit --cwd=current";
      # "ctrl+space>x" = "close_window";
      #
      # # ── Pane navigation (≈ vim-style hjkl) ───────────────────────────────
      # "ctrl+space>h" = "neighboring_window left";
      # "ctrl+space>j" = "neighboring_window down";
      # "ctrl+space>k" = "neighboring_window up";
      # "ctrl+space>l" = "neighboring_window right";
      #
      # # ── Pane resize (≈ HJKL capital) ─────────────────────────────────────
      # "ctrl+space>shift+h" = "resize_window narrower 5";
      # "ctrl+space>shift+l" = "resize_window wider 5";
      # "ctrl+space>shift+k" = "resize_window taller 5";
      # "ctrl+space>shift+j" = "resize_window shorter 5";

      # # ── Zoom/Fullscreen (≈ prefix+f / prefix+z) ───────────────────────────
      # # 'stack' layout = only show one window = zoom
      # "ctrl+space>f" = "toggle_layout stack";
      # "ctrl+space>z" = "toggle_layout stack"; # alias for muscle memory

      # Emit the CSI-u sequence for shift+enter so tmux (and apps behind it)
      # can distinguish it from a plain enter.
      "shift+enter" = ''send_text all \x1b[13;2u'';

      # ── Scrollback / copy mode (closest to tmux copy-mode-vi) ────────────
      # Opens scrollback in $PAGER (less by default, searchable with /)
      # "ctrl+space>[" = "show_scrollback";
      "ctrl+shift+m" = "show_scrollback";
      "ctrl+shift+space" = "show_scrollback";
      # If you later set scrollback_pager to nvim, this becomes vi copy mode

      # # ── Layout cycling ────────────────────────────────────────────────────
      # "ctrl+space>alt+space" = "next_layout";
    };

    # extraConfig handles things the settings/keybindings attrsets can't express,
    # like mouse_map and per-mode (scrollback) bindings.
    extraConfig = ''
      # ── Mouse support ──────────────────────────────────────────────────────
      mouse_map left click ungrabbed mouse_handle_click selection link prompt
      mouse_map right click ungrabbed mouse_handle_click selection

      # ── Strip ctrl+space from being sent to apps when used as prefix ───────
      # Kitty handles this automatically for leader-key sequences.
      # If you need to send a literal ctrl+space to an app:
      # map ctrl+space>ctrl+space send_key ctrl+space
    '';
  };

  # home.nix
  home.file = {
    ".my_scripts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/config/.my_scripts";
    ".config/systemd/hypr-session.target".text = ''
      [Unit]
      Description=hypr compositor session
      Documentation=man:systemd.special(7)
      BindsTo=graphical-session.target
      Wants=graphical-session-pre.target
      After=graphical-session-pre.target
    '';
    ".config/uv/uv.toml".text = ''
      index-strategy = "unsafe-first-match"

      # Tells uv to use python interpreters that are downloaded and managed by uv itself.
      # Prevents the use of system-wide python installations, which is usually nix-provided.
      # This is not compatible with using libraries such as `numpy`,`torch`,`opencv` that ship 
      # code compiled against system-wide libraries that are not present on a nix install.
      # Using compiled libraries leads to an infamous "ImportError: libstdc++.so.6: cannot open shared object file: No such file or directory"
      # More details here: https://wiki.nixos.org/wiki/Python#Running_Python_packages_which_requires_compilation_and/or_contains_libraries_precompiled_without_nix
      python-preference = "only-managed"
    '';
  };
}
