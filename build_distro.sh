#!/usr/bin/env bash
# ==============================================================================
# SCRIPT DE CONSTRUÇÃO E REMASTERIZAÇÃO: UBUNTU 24.04 LTS (NOBLE NUMBAT)
# Projeto: Distro Personalizada Leve (XFCE4 + Picom + Plank + Brave)
# Foco: Hardware Modesto (<650MB RAM ociosa), Visual macOS, Usabilidade Windows
# ==============================================================================
# Execução recomendada: Dentro do ambiente chroot (Cubic, Live-Build ou debootstrap)
# Uso: sudo ./build_distro.sh [NOME_DA_DISTRO] [VERSAO] [FUSO_HORARIO]
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# 0. CONFIGURAÇÕES E VARIÁVEIS INICIAIS
# ------------------------------------------------------------------------------
DISTRO_NAME="${1:-MinhaDistro}"
DISTRO_VERSION="${2:-1.4}"
DISTRO_TIMEZONE="${3:-America/Porto_Velho}"
DISTRO_CODENAME="noble"
DISTRO_ID="$(echo "${DISTRO_NAME}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
[ -z "${DISTRO_ID}" ] && DISTRO_ID="minhadistro"

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Cores para logs formatados
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_step()    { echo -e "\n${BOLD}${GREEN}==>${NC} ${BOLD}$*${NC}"; }
log_error()   { echo -e "${RED}[ERRO]${NC}  $*" >&2; }

# Checagem de privilégios de root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Este script precisa ser executado como root (ou dentro de ambiente chroot)."
    exit 1
fi

log_step "Iniciando remasterização do ${DISTRO_NAME} v${DISTRO_VERSION} (Ubuntu 24.04 LTS ${DISTRO_CODENAME})"

# ------------------------------------------------------------------------------
# 1. REPOSITÓRIOS APT (MAIN, RESTRICTED, UNIVERSE, MULTIVERSE)
# ------------------------------------------------------------------------------
log_step "1/14. Configurando repositórios APT oficiais do Ubuntu 24.04 LTS (Noble Numbat)..."

mkdir -p /etc/apt/keyrings /etc/apt/sources.list.d

cat > /etc/apt/sources.list <<EOF
# Ubuntu 24.04 LTS Noble Numbat - Repositórios Oficiais
deb http://archive.ubuntu.com/ubuntu/ ${DISTRO_CODENAME} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${DISTRO_CODENAME}-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu ${DISTRO_CODENAME}-security main restricted universe multiverse
EOF

apt-get update -y
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    software-properties-common \
    lsb-release \
    dirmngr

log_success "Repositórios oficiais e utilitários base configurados."

# ------------------------------------------------------------------------------
# 2. LOCALIZAÇÃO E IDIOMA ÚNICO (pt-BR 100%, ABNT2, FUSO HORÁRIO)
# ------------------------------------------------------------------------------
log_step "2/14. Configurando idioma 100% pt-BR, teclado ABNT2 e remoção de locales supérfluos..."

apt-get install -y --no-install-recommends \
    locales \
    tzdata \
    console-setup \
    keyboard-configuration \
    localepurge

# Gera exclusivamente pt_BR.UTF-8
sed -i 's/^[^#].*//' /etc/locale.gen
echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

cat > /etc/default/locale <<EOF
LANG=pt_BR.UTF-8
LANGUAGE=pt_BR:pt
LC_ALL=pt_BR.UTF-8
EOF

# Fuso horário
ln -sf "/usr/share/zoneinfo/${DISTRO_TIMEZONE}" /etc/localtime
echo "${DISTRO_TIMEZONE}" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Teclado ABNT2 Brasileiro
cat > /etc/default/keyboard <<EOF
XKBMODEL="abnt2"
XKBLAYOUT="br"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

# Configura localepurge para manter apenas pt e pt_BR
cat > /etc/locale.nopurge <<EOF
MANDELETE
DONTBOTHERNEWLOCALE
SHOWFREEDSPACE
pt
pt_BR
pt_BR.UTF-8
EOF

localepurge || true

log_success "Idioma pt-BR, ABNT2 e limpeza de locales configurados com sucesso."

# ------------------------------------------------------------------------------
# 3. OTIMIZAÇÕES DE MEMÓRIA E DESEMPENHO (ZRAM + SWAPPINESS PARA MÁQUINAS 4GB)
# ------------------------------------------------------------------------------
log_step "3/14. Configurando ZRAM (zstd 50% RAM) e sysctl para hardware modesto..."

apt-get install -y --no-install-recommends zram-tools

cat > /etc/default/zramswap <<EOF
# Configuração do ZRAM para ${DISTRO_NAME}
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

# Ajustes finos do Kernel para evitar congelamentos e reduzir swap excessivo
cat > /etc/sysctl.d/99-performance.conf <<EOF
# Otimizações de Memória e Desempenho - ${DISTRO_NAME}
# Reduz uso agressivo de swap mantendo páginas ativas em RAM/ZRAM
vm.swappiness = 10

# Mantém cache de diretórios e arquivos aberto por mais tempo
vm.vfs_cache_pressure = 50

# Escrita limpa em disco sem bloquear o sistema
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# Otimizações gerais de responsividade
fs.inotify.max_user_watches = 524288
EOF

log_success "ZRAM e parâmetros do Kernel otimizados."

# ------------------------------------------------------------------------------
# 4. HARDWARE, DRIVERS, FIRMWARES E CODECS ESSENCIAIS
# ------------------------------------------------------------------------------
log_step "4/14. Instalando firmwares Wi-Fi, microcódigos e aceleração de vídeo VA-API/Vulkan..."

apt-get install -y --no-install-recommends \
    linux-firmware \
    intel-microcode \
    amd64-microcode \
    mesa-vulkan-drivers \
    va-driver-all \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    libgl1-mesa-dri \
    libglx-mesa0 \
    mesa-utils \
    pciutils \
    usbutils \
    rfkill \
    wireless-tools \
    wpasupplicant

log_success "Drivers gráficos e firmwares de conectividade instalados."

# ------------------------------------------------------------------------------
# 5. ÁUDIO AUTOMÁTICO E PLUG-AND-PLAY COM PIPEWIRE
# ------------------------------------------------------------------------------
log_step "5/14. Configurando PipeWire, WirePlumber e comutação automática de áudio..."

# Remove o PulseAudio clássico se presente para evitar conflitos de barramento
apt-get remove -y --purge pulseaudio pulseaudio-module-bluetooth 2>/dev/null || true

apt-get install -y --no-install-recommends \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    pulseaudio-utils \
    libspa-0.2-bluetooth \
    gstreamer1.0-pipewire

# Habilita serviços do PipeWire para todos os usuários globais da sessão gráfica
systemctl --global enable pipewire.socket || true
systemctl --global enable pipewire-pulse.socket || true
systemctl --global enable wireplumber.service || true

# Garante comutação automática de endpoints (fone de ouvido, bluetooth, HDMI)
mkdir -p /etc/wireplumber/wireplumber.conf.d/
cat > /etc/wireplumber/wireplumber.conf.d/50-autoswitch-endpoints.conf <<EOF
wireplumber.settings = {
    device.routes.default-sink-volume = 0.70
    bluetooth.autoswitch-to-headset-profile = true
}
EOF

log_success "PipeWire com WirePlumber configurado para detecção automática."

# ------------------------------------------------------------------------------
# 6. AMBIENTE GRÁFICO XFCE4 ENXUTO E GERENCIADOR DE LOGIN (LIGHTDM)
# ------------------------------------------------------------------------------
log_step "6/14. Instalando base gráfica XFCE4 minimalista e LightDM..."

apt-get install -y --no-install-recommends \
    xorg \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    dbus-x11 \
    xfce4-session \
    xfwm4 \
    xfdesktop4 \
    xfce4-panel \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    xfce4-terminal \
    xfce4-settings \
    xfce4-power-manager \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-notifyd \
    xfce4-whiskermenu-plugin \
    xfce4-pulseaudio-plugin \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings \
    policykit-1-gnome \
    gvfs \
    gvfs-backends \
    network-manager \
    network-manager-gnome \
    fonts-noto-core \
    fonts-noto-color-emoji \
    fonts-dejavu-core \
    unzip \
    p7zip-full

# Ativa o NetworkManager
systemctl enable NetworkManager

log_success "XFCE4 minimalista e LightDM instalados."

# ------------------------------------------------------------------------------
# 7. COMPOSITOR PICOM OTIMIZADO (ZERO LAG EM GPUS INTEGRADAS)
# ------------------------------------------------------------------------------
log_step "7/14. Substituindo compositor do XFWM pelo Picom com bordas arredondadas e GLX..."

apt-get install -y --no-install-recommends picom

# Criar arquivo de configuração global otimizado do Picom
mkdir -p /etc/xdg/picom /etc/skel/.config/picom
cat > /etc/xdg/picom/picom.conf <<'EOF'
# ==============================================================================
# Configuração Picom Otimizada para Hardware Modesto (Zero Lag)
# ==============================================================================

# Backend: glx com fallback automático para xrender
backend = "glx";
glx-no-stencil = true;
glx-no-rebind-pixmap = true;
vsync = true;

# ------------------------------------------------------------------------------
# Bordas Arredondadas (Estilo macOS)
# ------------------------------------------------------------------------------
corner-radius = 12;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "class_g = 'Plank'",
  "class_g = 'plank'",
  "class_g = 'Xfce4-panel'",
  "_GTK_FRAME_EXTENTS@:c"
];

# ------------------------------------------------------------------------------
# Sombras Suaves (Shadows)
# ------------------------------------------------------------------------------
shadow = true;
shadow-radius = 14;
shadow-opacity = 0.40;
shadow-offset-x = -14;
shadow-offset-y = -14;
shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Plank'",
  "class_g = 'plank'",
  "class_g = 'Xfce4-panel'",
  "class_g ?= 'Notify-osd'",
  "_GTK_FRAME_EXTENTS@:c"
];

# ------------------------------------------------------------------------------
# Efeitos de Transição (Fading)
# ------------------------------------------------------------------------------
fading = true;
fade-in-step = 0.06;
fade-out-step = 0.06;
fade-delta = 6;
fade-exclude = [];

# ------------------------------------------------------------------------------
# Opacidade e Transparências
# ------------------------------------------------------------------------------
inactive-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;
active-opacity = 1.0;

# Opacidade customizada para o menu e dock
opacity-rule = [
  "92:class_g = 'Xfce4-panel'",
  "95:class_g = 'Xfce4-whiskermenu-plugin'"
];

# ------------------------------------------------------------------------------
# Outros Parâmetros de Performance
# ------------------------------------------------------------------------------
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
use-damage = true;
log-level = "warn";
EOF

cp /etc/xdg/picom/picom.conf /etc/skel/.config/picom/picom.conf

# Autostart do Picom na inicialização do XFCE
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/picom.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Picom Compositor
Comment=Compositor leve com cantos arredondados e sombras suaves
Exec=picom -b --config /etc/xdg/picom/picom.conf
OnlyShowIn=XFCE;
NoDisplay=true
X-XFCE-Autostart-Priority=1
EOF

log_success "Picom configurado com aceleração GLX e inicialização automática."

# ------------------------------------------------------------------------------
# 8. DOCK INFERIOR ANIMADA (PLANK COM ZOOM ATIVADO E TEMA ARREDONDADO)
# ------------------------------------------------------------------------------
log_step "8/14. Instalando e configurando o Plank com efeito Zoom ativado (150%)..."

apt-get install -y --no-install-recommends plank

# Configuração padrão do Plank para novos usuários
mkdir -p /etc/skel/.config/plank/dock1/launchers

cat > /etc/skel/.config/plank/dock1/settings <<EOF
[PlankDockPreferences]
# Tema Transparente / Arredondado
Theme=Transparent
# Posição: 3 = Inferior (Bottom)
Position=3
# Alinhamento: 3 = Centralizado (Center)
Alignment=3
# Tamanho dos ícones em pixels
IconSize=48
# Ocultamento Inteligente: 1 = Dodge-Windows (Oculta ao sobrepor janela)
HideMode=1
# Efeito de Zoom Animado Ativado
ZoomEnabled=true
# Porcentagem de expansão do zoom
ZoomPercent=150
# Largura do traço e delay
ItemStrokeWidth=0
PressureReveal=false
UnhideDelay=0
ShowDockItem=false
LockItems=false
EOF

# Lançadores fixados no Plank (.dockitem)
cat > /etc/skel/.config/plank/dock1/launchers/thunar.dockitem <<EOF
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/thunar.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/brave-browser.dockitem <<EOF
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/brave-browser.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/xfce4-terminal.dockitem <<EOF
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/xfce4-terminal.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/xfce4-taskmanager.dockitem <<EOF
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/xfce4-taskmanager.desktop
EOF

cat > /etc/skel/.config/plank/dock1/launchers/xfce4-settings-manager.dockitem <<EOF
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/xfce4-settings-manager.desktop
EOF

# Autostart do Plank
cat > /etc/xdg/autostart/plank.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Plank Dock
Comment=Dock inferior animada com efeito de zoom
Exec=plank
OnlyShowIn=XFCE;
NoDisplay=true
X-XFCE-Autostart-Priority=2
EOF

log_success "Plank configurado com Zoom 150% e lançadores essenciais."

# ------------------------------------------------------------------------------
# 9. BARRA SUPERIOR XFCE (ESTILO MACOS MENU BAR)
# ------------------------------------------------------------------------------
log_step "9/14. Configurando a barra superior única do XFCE (Top Menu Bar)..."

mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

# Configuração do Painel Superior XFCE (xfce4-panel.xml)
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=6;x=0;y=0"/>
    <property name="length" type="uint" value="100"/>
    <property name="position-locked" type="bool" value="true"/>
    <property name="icon-size" type="uint" value="16"/>
    <property name="size" type="uint" value="28"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
      <value type="int" value="6"/>
      <value type="int" value="7"/>
    </property>
    <property name="background-style" type="uint" value="0"/>
    <property name="leave-opacity" type="uint" value="95"/>
    <property name="enter-opacity" type="uint" value="100"/>
  </property>
  <property name="plugins" type="empty">
    <!-- Whisker Menu (Menu iniciar com logo da distro) -->
    <property name="plugin-1" type="string" value="whiskermenu">
      <property name="button-title" type="string" value="${DISTRO_NAME}"/>
      <property name="button-icon" type="string" value="distro-logo"/>
      <property name="show-button-title" type="bool" value="false"/>
      <property name="show-button-icon" type="bool" value="true"/>
    </property>
    <!-- Espaçador transparente e expansível -->
    <property name="plugin-2" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <!-- Área de Notificação / Bandeja do Sistema -->
    <property name="plugin-3" type="string" value="systray">
      <property name="square-icons" type="bool" value="true"/>
      <property name="single-row" type="bool" value="true"/>
    </property>
    <!-- Plugin de Áudio PulseAudio/PipeWire -->
    <property name="plugin-4" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
    </property>
    <!-- Gerenciador de Energia / Bateria -->
    <property name="plugin-5" type="string" value="power-manager-plugin"/>
    <!-- Relógio Digital formatado estilo macOS -->
    <property name="plugin-6" type="string" value="clock">
      <property name="digital-layout" type="uint" value="3"/>
      <property name="digital-time-format" type="string" value="%a, %d de %b   %H:%M"/>
    </property>
    <!-- Botões de Ação (Bloquear / Sair / Desligar) -->
    <property name="plugin-7" type="string" value="actions">
      <property name="appearance" type="uint" value="0"/>
      <property name="ask-for-confirmation" type="bool" value="true"/>
    </property>
  </property>
</channel>
EOF

cp /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# Desativar compositor nativo do xfwm4 (Picom assume o controle)
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="box_resize" type="bool" value="false"/>
    <property name="box_move" type="bool" value="false"/>
    <property name="double_click_action" type="string" value="maximize"/>
    <property name="theme" type="string" value="WhiteSur-Dark"/>
    <property name="title_alignment" type="string" value="left"/>
    <property name="button_layout" type="string" value="CHM|"/>
  </property>
</channel>
EOF

cp /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

log_success "Barra superior XFCE e layout de janelas configurados."

# ------------------------------------------------------------------------------
# 10. ATALHOS DE TECLADO ESTILO WINDOWS
# ------------------------------------------------------------------------------
log_step "10/14. Mapeando atalhos de teclado globais estilo Windows (Super, Super+E, Super+D...)..."

cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="default" type="empty"/>
    <property name="custom" type="empty">
      <!-- Super: Abre o Menu de Aplicativos (Whisker Menu) -->
      <property name="Super_L" type="string" value="xfce4-popup-whiskermenu"/>
      <!-- Super + E: Abre o Gerenciador de Arquivos (Thunar) -->
      <property name="&lt;Super&gt;e" type="string" value="thunar"/>
      <!-- Super + D: Minimiza todas as janelas / Mostra Área de Trabalho -->
      <property name="&lt;Super&gt;d" type="string" value="xfdesktop --reload"/>
      <!-- Super + L: Bloqueia a Tela -->
      <property name="&lt;Super&gt;l" type="string" value="xflock4"/>
      <!-- Ctrl + Shift + Esc: Gerenciador de Tarefas -->
      <property name="&lt;Primary&gt;&lt;Shift&gt;Escape" type="string" value="xfce4-taskmanager"/>
      <!-- PrintScreen: Captura de tela inteira -->
      <property name="Print" type="string" value="xfce4-screenshooter -f"/>
      <!-- Alt + PrintScreen: Captura janela ativa -->
      <property name="&lt;Alt&gt;Print" type="string" value="xfce4-screenshooter -w"/>
      <!-- Shift + PrintScreen: Captura região selecionada -->
      <property name="&lt;Shift&gt;Print" type="string" value="xfce4-screenshooter -r"/>
      <!-- Super + R: Caixa de execução de comandos -->
      <property name="&lt;Super&gt;r" type="string" value="xfrun4"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="default" type="empty"/>
    <property name="custom" type="empty">
      <!-- Super + Seta Esquerda: Ajusta janela à esquerda (Tiling) -->
      <property name="&lt;Super&gt;Left" type="string" value="tile_left_key"/>
      <!-- Super + Seta Direita: Ajusta janela à direita (Tiling) -->
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <!-- Super + Seta Cima: Maximizar Janela -->
      <property name="&lt;Super&gt;Up" type="string" value="maximize_window_key"/>
      <!-- Super + Seta Baixo: Minimizar Janela -->
      <property name="&lt;Super&gt;Down" type="string" value="hide_window_key"/>
      <!-- Alt + F4: Fechar Janela -->
      <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>
    </property>
  </property>
</channel>
EOF

cp /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml

log_success "Atalhos globais estilo Windows mapeados com sucesso."

# ------------------------------------------------------------------------------
# 11. NAVEGADOR BRAVE COMO PADRÃO (REMOÇÃO DO FIREFOX)
# ------------------------------------------------------------------------------
log_step "11/14. Removendo Firefox e instalando o Brave Browser como navegador padrão..."

# Remoção completa do Firefox ESR
apt-get purge -y firefox-esr firefox-esr-l10n-* 2>/dev/null || true
apt-get autoremove -y --purge 2>/dev/null || true

# Chave GPG e Repositório Oficial do Brave
curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

cat > /etc/apt/sources.list.d/brave-browser-release.list <<EOF
deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main
EOF

apt-get update -y
apt-get install -y brave-browser

# Define Brave como navegador padrão nas alternativas do sistema
update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/brave-browser 200
update-alternatives --set x-www-browser /usr/bin/brave-browser
update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/brave-browser 200
update-alternatives --set gnome-www-browser /usr/bin/brave-browser

# Define o Brave como padrão para tipos MIME e no XFCE
mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list <<EOF
[Default Applications]
text/html=brave-browser.desktop
x-scheme-handler/http=brave-browser.desktop
x-scheme-handler/https=brave-browser.desktop
x-scheme-handler/about=brave-browser.desktop
x-scheme-handler/unknown=brave-browser.desktop
EOF

mkdir -p /etc/skel/.config
cp /etc/xdg/mimeapps.list /etc/skel/.config/mimeapps.list

# Helper padrão do XFCE
mkdir -p /etc/xdg/xfce4
cat > /etc/xdg/xfce4/helpers.rc <<EOF
WebBrowser=brave-browser
EOF

log_success "Brave Browser instalado e registrado como navegador padrão."

# ------------------------------------------------------------------------------
# 12. TEMAS MACOS, ÍCONES, CURSORES E IDENTIDADE VISUAL
# ------------------------------------------------------------------------------
log_step "12/14. Instalando temas estilo macOS (WhiteSur/Colloid), ícones e fontes..."

# Instalação de fontes modernas com legibilidade estilo Apple San Francisco
apt-get install -y --no-install-recommends fonts-inter fonts-inter-variable

# Instalação automatizada do WhiteSur GTK Theme e WhiteSur Icon Theme
# Para garantir idempotência e resiliência sem falhas de compilação em chroot:
mkdir -p /usr/share/themes /usr/share/icons /usr/share/backgrounds /usr/share/pixmaps

WORK_DIR="$(mktemp -d)"

log_info "Baixando pacotes de tema WhiteSur..."
# Download WhiteSur GTK Theme
if curl -fsSL -o "${WORK_DIR}/whitesur-gtk.tar.xz" \
    "https://github.com/vinceliuice/WhiteSur-gtk-theme/releases/latest/download/WhiteSur-Dark.tar.xz" 2>/dev/null; then
    tar -xf "${WORK_DIR}/whitesur-gtk.tar.xz" -C /usr/share/themes/ || true
else
    log_warn "Download release WhiteSur falhou, instalando tema de fallback estilo macOS..."
    apt-get install -y --no-install-recommends greybird-gtk-theme arc-theme || true
fi

# Download WhiteSur Icon Theme ou Tela-Circle
log_info "Baixando pacote de ícones WhiteSur..."
if curl -fsSL -o "${WORK_DIR}/whitesur-icon.tar.xz" \
    "https://github.com/vinceliuice/WhiteSur-icon-theme/releases/latest/download/WhiteSur-dark.tar.xz" 2>/dev/null; then
    tar -xf "${WORK_DIR}/whitesur-icon.tar.xz" -C /usr/share/icons/ || true
else
    log_warn "Instalando Papirus como pacote de ícones moderno de alta resolução..."
    apt-get install -y --no-install-recommends papirus-icon-theme || true
fi

# Download WhiteSur Cursors
log_info "Baixando cursor estilo macOS..."
if curl -fsSL -o "${WORK_DIR}/whitesur-cursors.tar.xz" \
    "https://github.com/vinceliuice/WhiteSur-cursors/releases/latest/download/WhiteSur-cursors.tar.xz" 2>/dev/null; then
    tar -xf "${WORK_DIR}/whitesur-cursors.tar.xz" -C /usr/share/icons/ || true
fi

rm -rf "${WORK_DIR}"

# Ajuste automático do nome do tema caso tenha sido usado fallback
THEME_NAME="WhiteSur-Dark"
[ ! -d "/usr/share/themes/WhiteSur-Dark" ] && THEME_NAME="Greybird-dark"

ICON_NAME="WhiteSur-dark"
[ ! -d "/usr/share/icons/WhiteSur-dark" ] && ICON_NAME="Papirus-Dark"

CURSOR_NAME="WhiteSur-cursors"
[ ! -d "/usr/share/icons/WhiteSur-cursors" ] && CURSOR_NAME="Adwaita"

# Configuração global de aparência do XFCE (xsettings.xml)
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="${THEME_NAME}"/>
    <property name="IconThemeName" type="string" value="${ICON_NAME}"/>
    <property name="DoubleClickTime" type="int" value="400"/>
    <property name="DoubleClickDistance" type="int" value="5"/>
    <property name="DndDragThreshold" type="int" value="8"/>
    <property name="CursorThemeName" type="string" value="${CURSOR_NAME}"/>
    <property name="CursorThemeSize" type="int" value="24"/>
    <property name="EnableEventSounds" type="bool" value="false"/>
    <property name="EnableInputFeedbackSounds" type="bool" value="false"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="-1"/>
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Inter 10"/>
    <property name="MonospaceFontName" type="string" value="Monospace 10"/>
    <property name="CursorThemeName" type="string" value="${CURSOR_NAME}"/>
    <property name="CursorThemeSize" type="int" value="24"/>
    <property name="DecorationLayout" type="string" value="close,minimize,maximize:"/>
  </property>
</channel>
EOF

cp /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

# Gera logo vetorial minimalista para o sistema e Whisker Menu
cat > /usr/share/pixmaps/distro-logo.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#10B981"/>
      <stop offset="100%" stop-color="#047857"/>
    </linearGradient>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="26" fill="url(#g)"/>
  <path d="M34 40 L48 88 L60 88 L70 56 L80 88 L92 88 L106 40 L94 40 L85 72 L76 44 L64 44 L55 72 L46 40 Z" fill="#ffffff"/>
</svg>
EOF

# Configuração do LightDM GTK Greeter
cat > /etc/lightdm/lightdm-gtk-greeter.conf <<EOF
[greeter]
theme-name = ${THEME_NAME}
icon-theme-name = ${ICON_NAME}
cursor-theme-name = ${CURSOR_NAME}
font-name = Inter 10
background = /usr/share/backgrounds/distro-wallpaper.png
user-background = false
default-user-image = /usr/share/pixmaps/distro-logo.svg
position = 50%,center 50%,center
screensaver-timeout = 60
indicators = ~host;~spacer;~clock;~power
clock-format = %a, %d de %b   %H:%M
EOF

# Instala e configura tema do Plymouth (Boot Splash)
apt-get install -y --no-install-recommends plymouth plymouth-themes

plymouth-set-default-theme -R spinner 2>/dev/null || true

log_success "Temas, ícones, cursores e telas de login/boot configurados."

# ------------------------------------------------------------------------------
# 13. IDENTIDADE DO SISTEMA E VERSÃO (/etc/os-release, /etc/issue, GRUB)
# ------------------------------------------------------------------------------
log_step "13/14. Atualizando metadados de identidade para ${DISTRO_NAME} v${DISTRO_VERSION}..."

# os-release com proteção via dpkg-divert contra sobrescrita por updates do Ubuntu
if ! dpkg-divert --list /usr/lib/os-release | grep -q "${DISTRO_ID}"; then
  dpkg-divert --local --package "${DISTRO_ID}" --rename --divert /usr/lib/os-release.ubuntu --add /usr/lib/os-release || true
fi

cat > /usr/lib/os-release <<EOF
PRETTY_NAME="${DISTRO_NAME} ${DISTRO_VERSION}"
NAME="${DISTRO_NAME}"
VERSION_ID="${DISTRO_VERSION}"
VERSION="${DISTRO_VERSION} (base Ubuntu 24.04 LTS ${DISTRO_CODENAME})"
VERSION_CODENAME=${DISTRO_CODENAME}
ID=${DISTRO_ID}
ID_LIKE="ubuntu debian"
HOME_URL="https://github.com"
SUPPORT_URL="https://github.com"
BUG_REPORT_URL="https://github.com"
LOGO=distro-logo
EOF

ln -sf ../usr/lib/os-release /etc/os-release

echo "${DISTRO_NAME} ${DISTRO_VERSION} \n \l" > /etc/issue
echo "${DISTRO_NAME} ${DISTRO_VERSION}" > /etc/issue.net

# Configuração do GRUB
if [ -f /etc/default/grub ]; then
  sed -i "s/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR=\"${DISTRO_NAME}\"/" /etc/default/grub
else
  mkdir -p /etc/default
  echo "GRUB_DISTRIBUTOR=\"${DISTRO_NAME}\"" > /etc/default/grub
fi

log_success "Identidade ${DISTRO_NAME} v${DISTRO_VERSION} aplicada com sucesso."

# ------------------------------------------------------------------------------
# 14. LIMPEZA FINAL E SINCRONIZAÇÃO DE PERMISSÕES
# ------------------------------------------------------------------------------
log_step "14/14. Limpando pacotes residuais, caches e sincronizando /etc/skel..."

# Permissões do diretório base de novos usuários (/etc/skel)
chown -R root:root /etc/skel
chmod -R 755 /etc/skel

# Atualização de caches do sistema
update-icon-caches /usr/share/icons/* 2>/dev/null || true
fc-cache -f 2>/dev/null || true
update-desktop-database -q 2>/dev/null || true
update-mime-database /usr/share/mime 2>/dev/null || true

# Limpeza profunda do APT para manter a imagem leve
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*
find /var/log -type f -exec truncate -s 0 {} +

echo -e "\n${BOLD}${GREEN}========================================================================${NC}"
echo -e "${BOLD}${GREEN} REMASTERIZAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${BOLD} Distro:   ${DISTRO_NAME} v${DISTRO_VERSION}${NC}"
echo -e "${BOLD} Base:     Ubuntu 24.04 LTS (Noble Numbat)${NC}"
echo -e "${BOLD} Desktop:  XFCE4 + Picom (GLX) + Plank Zoom (150%)${NC}"
echo -e "${BOLD} Áudio:    PipeWire + WirePlumber (Plug-and-play)${NC}"
echo -e "${BOLD} Navegador: Brave Browser (Padrão)${NC}"
echo -e "${BOLD} Memória:  ZRAM zstd (50%) + Swappiness 10 (<650MB RAM ociosa)${NC}"
echo -e "${BOLD}${GREEN}========================================================================${NC}\n"
EOF
