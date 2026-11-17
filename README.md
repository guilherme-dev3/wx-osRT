# WX OS 1.0

Distribuição Linux da **Souza Soluções Digitais**: base **Debian 13 (trixie)**, área de trabalho **KDE Plasma**, verde como cor principal, modo claro e escuro, tudo em **português do Brasil**, teclado **ABNT2** e instalador gráfico (**Calamares**).

## O que vem no sistema

| Área | Conteúdo |
|---|---|
| Visual | Plasma com destaque verde `#16A34A`, papéis de parede WX OS claro/escuro, ícone WX OS no menu iniciar, tela de login personalizada |
| Idioma | pt-BR, teclado ABNT2, fuso America/Sao_Paulo |
| Programas | Firefox ESR (pt-BR), LibreOffice (Writer, Calc, Impress), VLC, Dolphin, Kate, Okular, Gwenview, Spectacle, Ark, Calculadora, Gerenciador de partições |
| Loja | Discover com Flatpak |
| Hardware | Firmwares de Wi-Fi (Intel, Realtek, Atheros, Broadcom), placas AMD, som Intel SOF, microcódigo Intel/AMD |
| Instalador | Calamares com a marca WX OS; instala o GRUB **sem precisar de internet**; funciona em UEFI (com Secure Boot) e BIOS antiga |

## Como compilar a ISO (GitHub Actions)

1. Crie um repositório **público** chamado `wx-os` no GitHub (público tem minutos ilimitados de Actions).
2. Envie todo o conteúdo desta pasta para o repositório (branch `main`).
3. A compilação começa sozinha. Acompanhe na aba **Actions** (leva de 40 a 70 minutos).
4. Ao terminar, abra a execução e baixe o artifact **wx-os-1.0-amd64** (a ISO + o arquivo sha256).

### Publicar uma versão oficial (aba Releases)

```bash
git tag v1.0
git push origin v1.0
```

A ISO aparece em **Releases**. Se passar de 2 GB (limite do GitHub por arquivo), ela é dividida em partes `.part00`, `.part01`; as instruções para juntar ficam na própria Release.

## Como testar

- **Máquina virtual:** VirtualBox ou GNOME Boxes, com 4 GB de RAM, 2 CPUs, disco de 25 GB. Para testar UEFI no VirtualBox, marque *Ativar EFI*.
- **Pendrive:** grave a ISO com o **Rufus** (modo *DD* quando ele perguntar) ou **balenaEtcher**.
- O sistema inicia direto no usuário `wxos` (senha `live`). Na área de trabalho fica o atalho **Instalar o WX OS**.

## Modo claro / escuro

No menu, procure **Tema claro** ou **Tema escuro**. No terminal:

```bash
wxos-tema claro      # ou: escuro | alternar
```

## Estrutura do projeto

```
auto/config                         opções do live-build (Debian trixie, pt-BR, nome da ISO)
config/package-lists/               lista de pacotes do sistema
config/hooks/normal/9000-wxos...    identidade (os-release), idioma, teclado, instalador
config/includes.chroot/             arquivos copiados para dentro do sistema
  etc/calamares/branding/wxos/      marca do instalador (logo, cores, slides)
  etc/skel/.config/                 padrões do Plasma para todo usuário novo
  usr/local/bin/wxos-tema           troca claro/escuro
  usr/local/bin/wxos-primeiro-login ajustes no primeiro login
  usr/local/sbin/wxos-bootloader-config  GRUB offline durante a instalação
  usr/share/wallpapers/WXOS*        papéis de parede
branding/                           arquivos-fonte (SVG) do logo e papéis de parede
.github/workflows/build-iso.yml     compilação automática
```

## Adicionar ou remover programas

Edite `config/package-lists/wx-os.list.chroot` (um pacote por linha, nomes do Debian 13) e envie para o GitHub; uma nova ISO é gerada.

## Observações técnicas

- O menu do GRUB mostra "Debian GNU/Linux". Isso é proposital: o GRUB assinado do Debian (Secure Boot) só funciona na pasta `/EFI/debian`; renomear quebraria o boot em PCs com Secure Boot.
- `/usr/lib/os-release` é protegido com `dpkg-divert`, então as atualizações do Debian não apagam o nome WX OS.
- Para compilar localmente (Debian/Ubuntu): `sudo apt install live-build` e, nesta pasta, `sudo lb config && sudo lb build`.
