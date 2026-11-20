#!/usr/bin/env bash
# ==============================================================================
# SCRIPT DE ATUALIZAÇÃO DE VERSÃO (BUMP VERSION)
# Projeto: Remasterização Ubuntu 24.04 LTS (Noble Numbat)
# ==============================================================================
# Atualiza automaticamente:
# - /etc/os-release e /usr/lib/os-release
# - /etc/issue e /etc/issue.net
# - /etc/default/grub (GRUB_DISTRIBUTOR)
# - /etc/lightdm/lightdm-gtk-greeter.conf
# - Branding do Calamares (se existente)
# - Metadados do Live-Build / Workflows (se existente)
# ==============================================================================
# Uso:
#   sudo ./bump_version.sh <NOVA_VERSAO> [CODENAME_OPCIONAL] [DIRETORIO_ROOTFS]
# Exemplo:
#   sudo ./bump_version.sh 1.5
#   sudo ./bump_version.sh 2.0 noble /caminho/chroot
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# Cores para saída no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_error()   { echo -e "${RED}[ERRO]${NC}  $*" >&2; }

# Validação do argumento de versão
NEW_VERSION="${1:-}"
if [ -z "${NEW_VERSION}" ]; then
    echo -e "${BOLD}Uso:${NC} sudo $0 <NOVA_VERSAO> [CODENAME] [ROOTFS_PATH]"
    echo -e "Exemplo: sudo $0 1.5"
    echo -e "Exemplo: sudo $0 2.0 noble /var/chroot"
    exit 1
fi

TARGET_ROOT="${3:-/}"
TARGET_ROOT="${TARGET_ROOT%/}"
[ -z "${TARGET_ROOT}" ] && TARGET_ROOT="/"

log_info "Diretório de destino (Rootfs): ${TARGET_ROOT}"

# Caminhos dos arquivos alvo
OS_RELEASE_USR="${TARGET_ROOT}/usr/lib/os-release"
OS_RELEASE_ETC="${TARGET_ROOT}/etc/os-release"
ISSUE_FILE="${TARGET_ROOT}/etc/issue"
ISSUE_NET_FILE="${TARGET_ROOT}/etc/issue.net"
GRUB_DEFAULT="${TARGET_ROOT}/etc/default/grub"
LIGHTDM_CONF="${TARGET_ROOT}/etc/lightdm/lightdm-gtk-greeter.conf"

# Identificar nome da distro atual a partir do os-release existente
CURRENT_DISTRO_NAME="MinhaDistro"
CURRENT_CODENAME="${2:-noble}"

if [ -f "${OS_RELEASE_USR}" ]; then
    CURRENT_DISTRO_NAME="$(grep -E '^NAME=' "${OS_RELEASE_USR}" | head -n1 | cut -d'=' -f2 | tr -d '"')"
elif [ -f "${OS_RELEASE_ETC}" ]; then
    CURRENT_DISTRO_NAME="$(grep -E '^NAME=' "${OS_RELEASE_ETC}" | head -n1 | cut -d'=' -f2 | tr -d '"')"
fi
[ -z "${CURRENT_DISTRO_NAME}" ] && CURRENT_DISTRO_NAME="MinhaDistro"

DISTRO_ID="$(echo "${CURRENT_DISTRO_NAME}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-')"
[ -z "${DISTRO_ID}" ] && DISTRO_ID="minhadistro"

echo -e "\n${BOLD}${BLUE}========================================================================${NC}"
echo -e "${BOLD} ATUALIZANDO VERSÃO DO SISTEMA: ${CURRENT_DISTRO_NAME}${NC}"
echo -e " Nova Versão: ${BOLD}${GREEN}${NEW_VERSION}${NC}"
echo -e " Codename:    ${BOLD}${YELLOW}${CURRENT_CODENAME}${NC}"
echo -e "${BOLD}${BLUE}========================================================================${NC}\n"

# ------------------------------------------------------------------------------
# 1. ATUALIZAR /usr/lib/os-release E /etc/os-release
# ------------------------------------------------------------------------------
log_info "Atualizando os-release..."
mkdir -p "$(dirname "${OS_RELEASE_USR}")"

cat > "${OS_RELEASE_USR}" <<EOF
PRETTY_NAME="${CURRENT_DISTRO_NAME} ${NEW_VERSION}"
NAME="${CURRENT_DISTRO_NAME}"
VERSION_ID="${NEW_VERSION}"
VERSION="${NEW_VERSION} (base Ubuntu 24.04 LTS ${CURRENT_CODENAME})"
VERSION_CODENAME=${CURRENT_CODENAME}
ID=${DISTRO_ID}
ID_LIKE="ubuntu debian"
HOME_URL="https://github.com"
SUPPORT_URL="https://github.com"
BUG_REPORT_URL="https://github.com"
LOGO=distro-logo
EOF

mkdir -p "$(dirname "${OS_RELEASE_ETC}")"
ln -sf ../usr/lib/os-release "${OS_RELEASE_ETC}" 2>/dev/null || cp "${OS_RELEASE_USR}" "${OS_RELEASE_ETC}"
log_success "os-release atualizado com sucesso."

# ------------------------------------------------------------------------------
# 2. ATUALIZAR /etc/issue E /etc/issue.net
# ------------------------------------------------------------------------------
log_info "Atualizando banners de login no terminal (/etc/issue)..."
echo "${CURRENT_DISTRO_NAME} ${NEW_VERSION} \n \l" > "${ISSUE_FILE}"
echo "${CURRENT_DISTRO_NAME} ${NEW_VERSION}" > "${ISSUE_NET_FILE}"
log_success "/etc/issue e /etc/issue.net atualizados."

# ------------------------------------------------------------------------------
# 3. ATUALIZAR GRUB (DISTRIBUTOR)
# ------------------------------------------------------------------------------
if [ -f "${GRUB_DEFAULT}" ]; then
    log_info "Atualizando identificação no menu do GRUB..."
    sed -i "s/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR=\"${CURRENT_DISTRO_NAME} ${NEW_VERSION}\"/" "${GRUB_DEFAULT}"
    log_success "GRUB_DISTRIBUTOR atualizado para '${CURRENT_DISTRO_NAME} ${NEW_VERSION}'."
    
    # Se estiver rodando no sistema real, chama update-grub se existir
    if [ "${TARGET_ROOT}" = "/" ] && command -v update-grub >/dev/null 2>&1; then
        log_info "Executando update-grub..."
        update-grub || log_warn "update-grub retornou aviso (normal em ambiente chroot sem montagem /boot)."
    fi
fi

# ------------------------------------------------------------------------------
# 4. ATUALIZAR CALAMARES BRANDING (SE EXISTIR)
# ------------------------------------------------------------------------------
CALAMARES_BRANDING_DIR="${TARGET_ROOT}/etc/calamares/branding"
if [ -d "${CALAMARES_BRANDING_DIR}" ]; then
    log_info "Atualizando metadados de versão do instalador Calamares..."
    find "${CALAMARES_BRANDING_DIR}" -name "branding.desc" -type f | while read -r bfile; do
        sed -i -E "s/version:\s+\"[^\"]+\"/version:             \"${NEW_VERSION}\"/g" "${bfile}"
        sed -i -E "s/shortVersion:\s+\"[^\"]+\"/shortVersion:        \"${NEW_VERSION}\"/g" "${bfile}"
        sed -i -E "s/versionedName:\s+\"[^\"]+\"/versionedName:       \"${CURRENT_DISTRO_NAME} ${NEW_VERSION}\"/g" "${bfile}"
        sed -i -E "s/shortVersionedName:\s+\"[^\"]+\"/shortVersionedName:  \"${CURRENT_DISTRO_NAME} ${NEW_VERSION}\"/g" "${bfile}"
        log_success "Calamares atualizado em: ${bfile}"
    done
fi

# ------------------------------------------------------------------------------
# 5. ATUALIZAR WORKFLOWS GITHUB ACTIONS E SCRIPTS DE BUILD (SE PRESENTE NA ÁRVORE)
# ------------------------------------------------------------------------------
for rel_file in ".github/workflows/build-iso.yml" "build-iso.yml" "auto/config"; do
    if [ -f "${TARGET_ROOT}/${rel_file}" ]; then
        log_info "Atualizando referências no arquivo de build: ${rel_file}..."
        sed -i -E "s/${CURRENT_DISTRO_NAME}-[0-9]+\.[0-9]+/${CURRENT_DISTRO_NAME}-${NEW_VERSION}/g" "${TARGET_ROOT}/${rel_file}" 2>/dev/null || true
    fi
done

# ------------------------------------------------------------------------------
# 6. RESUMO DE CONFERÊNCIA
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${GREEN}========================================================================${NC}"
echo -e "${BOLD}${GREEN} VERSÃO ATUALIZADA COM SUCESSO!${NC}"
echo -e "${BOLD} Nova Identidade em ${OS_RELEASE_USR}:${NC}"
echo "------------------------------------------------------------------------"
cat "${OS_RELEASE_USR}"
echo "------------------------------------------------------------------------"
echo -e "${BOLD} Banner TTY (/etc/issue):${NC} $(cat "${ISSUE_FILE}")"
echo -e "${BOLD}${GREEN}========================================================================${NC}\n"
EOF
