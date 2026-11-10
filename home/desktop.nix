{ config, lib, pkgs, ... }:
{
  options.mg.waybar.overrides = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Host-specific waybar settings; the generated config.jsonc includes the shared common.jsonc and wins on conflicts.";
  };

  options.mg.hypr.monitors = lib.mkOption {
    type = lib.types.path;
    description = "Host-specific Hyprland monitor/workspace Lua file, installed as hyprland/monitors.lua.";
  };

  config = {
  # Hyprland config shared by all desktops; only monitors.lua differs per host.
  xdg.configFile."hypr/hyprland.lua".source = ./hypr/hyprland.lua;
  xdg.configFile."hypr/hypridle.conf".source = ./hypr/hypridle.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;
  xdg.configFile."hypr/hyprland" = {
    source = ./hypr/hyprland;
    recursive = true;
  };
  xdg.configFile."hypr/hyprland/monitors.lua".source = config.mg.hypr.monitors;

  # Waybar: shared bar in common.jsonc, host-specific bits via mg.waybar.overrides.
  xdg.configFile."waybar/common.jsonc".source = ./waybar/common.jsonc;
  xdg.configFile."waybar/config.jsonc".text = builtins.toJSON (
    { include = [ "${config.xdg.configHome}/waybar/common.jsonc" ]; } // config.mg.waybar.overrides
  );
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."waybar/voxtype.css".source = ./waybar/voxtype.css;
  xdg.configFile."waybar/modules".source = ./waybar/modules;
  xdg.configFile."waybar/scripts".source = ./waybar/scripts;

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
    # custom font
    nerd-fonts.iosevka-term

    mermaid-cli

    wofi
    waybar
    keepassxc
    wl-clipboard-rs

    spotify
    signal-desktop
    portfolio
    vlc
  ];

  programs.zsh = {
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

    shellAliases = {
      setclip = "wl-copy";
      getclip = "wl-paste";
    };
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
          chars = "\n";
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

  home.file.".my_scripts".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/config/.my_scripts";

  systemd.user.targets.hypr-session = {
    Unit = {
      Description = "hypr compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  systemd.user.services.waybar = {
    Unit = {
      Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors";
      Documentation = [ "https://github.com/Alexays/Waybar/wiki/" ];
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
      # Restart on config/style change; the unit text itself only changes with the package.
      X-Restart-Triggers = [
        "${config.xdg.configFile."waybar/config.jsonc".source}"
        "${./waybar/common.jsonc}"
        "${./waybar/style.css}"
      ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  };
}
