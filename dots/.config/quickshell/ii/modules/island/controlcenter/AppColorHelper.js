// AppColorHelper - Color utilities for app branding and theming
// Plain JavaScript module (not a QML singleton) to avoid "Singleton is not a type" errors

// Brand colors for known applications
const brandColors = {
    "discord": "#5865F2",
    "youtube": "#FF0000",
    "spotify": "#1DB954",
    "firefox": "#FF7139",
    "telegram": "#229ED9",
    "signal": "#3A76F0",
    "slack": "#4A154B",
    "element": "#0DBD8B",
    "matrix": "#0DBD8B",
    "steam": "#1B2838",
    "thunderbird": "#0A84FF",
    "chrome": "#4285F4",
    "chromium": "#4285F4",
    "vscode": "#007ACC",
    "code": "#007ACC",
    "git": "#F05032",
    "github": "#FFFFFF",
    "gitlab": "#FC6D26",
    "docker": "#2496ED",
    "npm": "#CB3837",
    "node": "#339933",
    "python": "#3776AB",
    "rust": "#DEA584",
    "go": "#00ADD8",
    "vim": "#019733",
    "neovim": "#57A143",
    "emacs": "#7F5AB6",
    "zed": "#DB3D74",
    "sublime": "#FF9800",
    "postman": "#FF6C37",
    "insomnia": "#5848DE",
    "figma": "#F24E1E",
    "obsidian": "#483699",
    "notion": "#000000",
    "obs": "#000000",
    "vlc": "#EE7711",
    "mpv": "#000000",
    "gimp": "#FEFEFC",
    "blender": "#F5792A",
    "krita": "#FFA500",
    "inkscape": "#000000",
    "libreoffice": "#18A303",
    "onlyoffice": "#2E8BFF",
    "thunderbird": "#0A84FF",
    "evolution": "#5B8DEF",
    "geary": "#3197EE",
    "kde connect": "#3584E4",
    "kdeconnect": "#3584E4",
    "gsconnect": "#3584E4",
    "android": "#3DDC84",
    "ios": "#000000",
    "ipad": "#000000",
    "iphone": "#000000",
};

function colorForApp(appName) {
    if (!appName) {
        return fallbackColor("");
    }

    const lower = appName.toLowerCase();

    for (const brand in brandColors) {
        if (lower.includes(brand)) {
            return brandColors[brand];
        }
    }

    return fallbackColor(appName);
}

function fallbackColor(appName, darkmode) {
    const hash = Qt.md5(appName.toLowerCase());
    const hue = parseInt(hash.substr(0, 4), 16) / 0xFFFF * 360;
    const saturation = 0.55 + (parseInt(hash.substr(4, 2), 16) / 255) * 0.25;
    const lightness = 0.45 + (parseInt(hash.substr(6, 2), 16) / 255) * 0.2;

    if (darkmode) {
        return Qt.hsla(hue / 360, saturation, lightness + 0.1, 1);
    }
    return Qt.hsla(hue / 360, saturation, lightness, 1);
}

function onColor(bgColor) {
    return ColorUtils.isDark(bgColor) ? "#FFFFFF" : "#1A120B";
}

function accentStripeColor(appName, darkmode) {
    const color = colorForApp(appName);
    return ColorUtils.applyAlpha(color, 0.9);
}

function iconBackgroundColor(appName, darkmode) {
    const color = colorForApp(appName);
    return ColorUtils.applyAlpha(color, 0.18);
}

function appNameColor(appName, darkmode) {
    const color = colorForApp(appName);
    if (darkmode) {
        return ColorUtils.colorWithLightness(color, 0.85);
    }
    return ColorUtils.colorWithLightness(color, 0.45);
}