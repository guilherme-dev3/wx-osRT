# WX OS 1.0 — Edição macOS

Distribuição Linux criada pela **GR TECH**: base **Debian 13 (trixie)**, área de trabalho **KDE Plasma** totalmente personalizada com **interface limpa e fluida inspirada no macOS**, destaque verde esmeralda (`#10B981`), papéis de parede abstratos em 4K, tudo em **português do Brasil**, teclado **ABNT2** e instalador gráfico (**Calamares**).

---

## Destaques Visuais & Interface macOS

| Elemento | Descrição |
|---|---|
| **Barra Superior (Menu Bar)** | Barra fina translúcida no topo com menu iniciar WX OS, **Menu Global unificado** (Arquivo, Editar, Exibir...) da janela ativa, espaçador, bandeja de sistema e relógio digital limpo. |
| **Dock Flutuante Inferior** | Dock centralizado e flutuante no estilo macOS com atalhos para Finder (Dolphin), Navegador (Firefox), Terminal (Konsole), Editor (Kate), Vídeos (VLC), Loja (Discover), Preferências e Lixeira. |
| **Controles de Janela (Semáforo)** | Botões Fechar (vermelho), Minimizar (amarelo) e Maximizar (verde) posicionados no canto **superior esquerdo** das janelas. |
| **Tipografia Inter** | Fonte moderna Inter (mesma métrica e clareza da San Francisco da Apple) com renderização subpixel e anti-aliasing de altíssima nitidez. |
| **Ícones Papirus & Squircles** | Pacote de ícones modernos em squircle e novo logotipo 3D refinado no padrão dos ícones de apps do macOS. |
| **Gráficos em 4K / HD** | Novos papéis de parede abstratos em camadas fluidas (ondas orgânicas) para modo claro e escuro em resoluções 3840×2160 e 1920×1080. |
| **Tela de Login SDDM** | Fundo translúcido com efeito de desfoque suave (blur) e caixa de login limpa e centralizada. |

---

## O que vem no sistema

| Área | Conteúdo |
|---|---|
| **Visual** | Plasma com layout macOS, tema escuro nativo (ou claro), aceleração gráfica Mesa 3D |
| **Idioma** | pt-BR completo, teclado ABNT2, fuso America/Sao_Paulo |
| **Programas** | Firefox ESR (pt-BR), VLC, Dolphin, Kate, Okular, Gwenview, Spectacle, Ark, Calculadora, Gerenciador de partições |
| **Loja** | Discover com Flathub integrado (LibreOffice, Spotify, Discord, Chrome com 1 clique) |
| **Hardware** | Firmwares de Wi-Fi (Intel, Realtek, Atheros, Broadcom), placas AMD, som Intel SOF, microcódigo Intel/AMD |
| **Instalador** | Calamares com apresentação gráfica moderna, instalação offline do GRUB em UEFI e BIOS Legacy |

---

## Alternar Modo Claro / Escuro

No menu ou pelo atalho, procure por **Tema claro** ou **Tema escuro**. Pelo terminal:

```bash
wxos-tema claro      # Aplica visual claro estilo macOS (Breeze Light + Papirus + Wall Claro)
wxos-tema escuro     # Aplica visual escuro estilo macOS (Breeze Dark + Papirus Dark + Wall Escuro)
wxos-tema alternar   # Alterna entre os dois modos
```

---

## Como compilar a ISO (GitHub Actions)

1. Crie um repositório **público** (ex.: `wx-osRT`) no seu GitHub.
2. Envie todo o conteúdo desta pasta para o repositório (branch `main`):
   ```bash
   git init
   git add .
   git commit -m "WX OS 1.0 - Interface macOS e gráficos refinados"
   git branch -M main
   git remote add origin https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git
   git push -u origin main
   ```
3. A compilação é iniciada automaticamente pelo GitHub Actions (leva de 40 a 60 minutos).
4. Ao concluir, vá até a aba **Actions** e baixe o artefato **wx-os-1.0-amd64** (contendo a ISO pronta para boot e o arquivo de verificação sha256).

### Publicar uma versão oficial (Aba Releases)

```bash
git tag v1.0
git push origin v1.0
```

A ISO será anexada automaticamente na aba **Releases**.

---

## Como testar

- **Máquina virtual:** VirtualBox, VMware ou GNOME Boxes com 4 GB de RAM, 2 CPUs e 25 GB de disco.
- **Pendrive inicializável:** Grave a ISO com o **Rufus** (selecionando o modo *DD* quando solicitado) ou com o **balenaEtcher**.
- O live-boot entra automaticamente no usuário `wxos` (senha `live`). Na área de trabalho você encontra o atalho **Instalar o WX OS**.

---

## Estrutura do projeto

```
auto/config                         opções do live-build (Debian trixie, pt-BR, nome da ISO)
config/package-lists/               lista de pacotes (KDE Plasma, Inter, Papirus, Flatpak)
config/hooks/normal/9000-wxos...    identidade (os-release), idioma, teclado, instalador, fontes
config/includes.chroot/             arquivos copiados para dentro do sistema
  etc/calamares/branding/wxos/      marca e apresentação do instalador gráfico
  etc/xdg/                          configurações globais (botões à esquerda, fontes, GTK)
  etc/skel/.config/                 configurações padrão para novos usuários
  usr/local/bin/wxos-tema           alternador claro/escuro dinâmico
  usr/local/bin/wxos-primeiro-login automação do layout macOS (Barra Superior + Dock)
  usr/local/sbin/wxos-bootloader-config  instalação offline do GRUB
  usr/share/wallpapers/             papéis de parede 4K / FHD (claro e escuro)
branding/                           vetores SVG e imagens de alta resolução
.github/workflows/build-iso.yml     automação da compilação via GitHub Actions
```
