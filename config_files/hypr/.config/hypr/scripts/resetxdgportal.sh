#!/bin/bash
sleep 1
killall xdg-desktop-portal-hyprland
killall xdg-desktop-portal-wlr
killall xdg-desktop-portal
sleep 1
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export QT_QPA_PLATFORM=wayland
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_QPA_PLATFORM="wayland;xcb"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_CURRENT_DESKTOP=hyprland
export XDG_SESSION_DESKTOP=hyprland
export GDK_BACKEND="wayland,x11"
export CLUTTER_BACKEND="wayland"

#NVIDIA Specific : place the word export in front of the lines below if you have nvidia-card see example above

#LIBVA_DRIVER_NAME=nvidia
#XDG_SESSION_TYPE=wayland
#GBM_BACKEND=nvidia-drm
# __GLX_VENDOR_LIBRARY_NAME=nvidia
#WLR_NO_HARDWARE_CURSORS=1
#WLR_DRM_NO_ATOMIC=1
