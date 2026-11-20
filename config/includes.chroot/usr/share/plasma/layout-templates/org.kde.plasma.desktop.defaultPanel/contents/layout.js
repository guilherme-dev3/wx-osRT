var panel = new Panel;
panel.location = "bottom";
panel.alignment = "center";
panel.floating = true;
panel.height = 64;
panel.lengthMode = "fitContent";

// 1. Lançador com ícone do WX OS
var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "/usr/share/pixmaps/wx-os.svg");

// 2. Aplicativos Fixados na Dock (Estilo macOS / Squircle)
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:brave-browser.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:vlc.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop",
    "applications:org.kde.kcalc.desktop",
    "applications:org.kde.spectacle.desktop"
]);

// 3. Bandeja do Sistema e Notificações (Wi-Fi, Áudio, Bateria)
panel.addWidget("org.kde.plasma.systemtray");

// 4. Relógio Digital Limpo
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "false");
clock.writeConfig("dateFormat", "shortDate");

// 5. Lixeira na extremidade da Dock
panel.addWidget("org.kde.plasma.trash");
