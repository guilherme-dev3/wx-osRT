import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() { presentation.goToNextSlide(); }

    Timer {
        id: advanceTimer
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Rectangle { anchors.fill: parent; color: "#0B1319" }
        Image { id: logo1; source: "logo.png"; width: 130; height: 130; fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 40 }
        Text { anchors.top: logo1.bottom; anchors.topMargin: 22; anchors.horizontalCenter: parent.horizontalCenter
               width: parent.width * 0.85; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
               color: "#FFFFFF"; font.pixelSize: 22; font.family: "Inter"
               text: "Bem-vindo ao <b>WX OS</b>.<br/>A elegância do macOS com a robustez e compatibilidade do Ubuntu.<br/><br/><small style='color:#34D399'>Desenvolvido por GR TECH</small>" }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#0F172A" }
        Text { anchors.centerIn: parent; width: parent.width * 0.85; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#FFFFFF"; font.pixelSize: 20; font.family: "Inter"
               text: "<b>Interface Inspirada no macOS</b><br/><br/>Barra de menus superior com <b>Menu Global unificado</b> e <b>Dock flutuante</b> inferior para acesso rápido aos seus aplicativos favoritos com visual limpo e moderno." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#064E3B" }
        Text { anchors.centerIn: parent; width: parent.width * 0.85; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#FFFFFF"; font.pixelSize: 20; font.family: "Inter"
               text: "<b>Tipografia Inter & Gráficos em Alta Definição</b><br/><br/>Fontes ultra nítidas no estilo Apple San Francisco, ícones modernos Papirus e papéis de parede abstratos em 4K nos modos claro e escuro." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#0F172A" }
        Text { anchors.centerIn: parent; width: parent.width * 0.85; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#FFFFFF"; font.pixelSize: 20; font.family: "Inter"
               text: "<b>Loja de Aplicativos & Flatpak</b><br/><br/>Abra o Discover para instalar LibreOffice, Spotify, navegadores e milhares de ferramentas com apenas um clique." }
    }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}
