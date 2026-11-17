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
        Rectangle { anchors.fill: parent; color: "#052E16" }
        Image { id: logo1; source: "logo.png"; width: 140; height: 140; fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 40 }
        Text { anchors.top: logo1.bottom; anchors.topMargin: 24; anchors.horizontalCenter: parent.horizontalCenter
               width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
               color: "#FFFFFF"; font.pixelSize: 22
               text: "Bem-vindo ao <b>WX OS</b>.<br/>Estamos instalando o sistema no seu computador." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#14532D" }
        Text { anchors.centerIn: parent; width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#FFFFFF"; font.pixelSize: 20
               text: "<b>Tudo em português</b><br/><br/>Navegador, escritório (LibreOffice), vídeos e fotos já vêm prontos para usar." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#15803D" }
        Text { anchors.centerIn: parent; width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#FFFFFF"; font.pixelSize: 20
               text: "<b>Modo claro e escuro</b><br/><br/>Procure por \"Tema claro\" ou \"Tema escuro\" no menu para trocar o visual quando quiser." }
    }
    Slide {
        Rectangle { anchors.fill: parent; color: "#052E16" }
        Text { anchors.centerIn: parent; width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter
               wrapMode: Text.WordWrap; color: "#FFFFFF"; font.pixelSize: 20
               text: "<b>Loja de aplicativos</b><br/><br/>Abra o Discover para instalar novos programas com um clique." }
    }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}
