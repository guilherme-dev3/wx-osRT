#!/bin/sh
# WX OS — Exporta o menu global para aplicativos GTK (estilo macOS)
export GTK_MODULES="${GTK_MODULES:+$GTK_MODULES:}appmenu-gtk-module"
export UBUNTU_MENUPROXY=1
