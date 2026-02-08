# Ganenblue AHK v3.0

A performant and flexible automation bot for **Granblue Fantasy** (browser version), written in **AutoHotkey v1**.

This bot automates repetitive farming tasks like raids, story events, and guild wars (GW) with visual confirmation and smart state handling.

## 🚀 Features

*   **Smart Automation**: Uses image recognition to confirm actions (attack, summon, results, errors).
*   **Performance Optimized**: Low CPU usage mode with throttled checks.
*   **Modular Architecture**: Clean, object-oriented code split across multiple files for easy maintenance.
*   **Modern GUI**: Resizeable window with live stats, logs, and easy configuration.
*   **Battle Modes**:
    *   **Full Auto**: Starts full auto immediately.
    *   **Semi Auto**: Clicks attack, then handles battle loop.
*   **Bot Modes**:
    *   **Quest Mode**: Repeats a specific quest URL.
    *   **Raid Mode**: Returns to the "Assist" tab for raid farming.
*   **Reliability**: Handles network errors, party wipes (revives with elixir), and pending battles automatically.

## 📂 Project Structure

*   `ganenblue.ahk`: **Main Script**. Launch this file. Handles the GUI and main loop.
*   `config.ahk`: Configuration, constants, image paths, and state management (`BotConfig`, `BotState`).
*   `actions.ahk`: Game logic handlers (Battle, Results, Summon selection, etc.).
*   `image/`: Directory containing required PNG assets for image recognition.
*   `bot_settings.ini`: Automatically generated file to save your Quest URL.

## 🛠️ Requirements

1.  **Windows OS**.
2.  **AutoHotkey v1.1+** installed.
3.  **Google Chrome** or a Chromium-based browser.
4.  **Granblue Fantasy** game window visible on screen.

## ⚙️ Setup & Usage

1.  **Download/Clone** this repository.
2.  Ensure your `image/` folder is populated with the necessary game assets (buttons, headers, etc.).
3.  Run **`ganenblue.ahk`** as Administrator (recommended for input simulation).

### Configuration
1.  **Set Quest URL**:
    *   Click "Edit Quest URL".
    *   Paste the URL of the *Supporter Selection* screen for the quest you want to farm.
    *   Example: `https://game.granbluefantasy.jp/#quest/supporter/12345/1`
    *   Click "Save".

2.  **Select Modes**:
    *   **Full Auto / Semi Auto**: Choose your preferred battle style.
    *   **Quest Mode / Raid Mode**: Choose based on your activity.

3.  **Start Farming**:
    *   Navigate to the Quest or Raid page in your browser.
    *   Click **Start**.
    *   The bot will take over. Press **Stop** or `F12` to pause/stop at any time.

## ⌨️ Hotkeys

| Key | Action |
| :--- | :--- |
| **Ctrl + R** | Reload the script (useful after code changes) |
| **F1** | Resize browser window to standard size (1000x1799) |
| **F2** | Manual Refresh & Reset State |
| **F10** | Show detailed statistics popup |
| **F11** | Reset statistics (Battles/Errors) |
| **F12** | **Pause/Resume** the bot |
| **Esc** | Exit the application |

## ⚠️ Important Notes

*   **Window Visibility**: The game window must be visible (not minimized) for image search to work, though it can be in the background if legitimate background input is supported (AutoHotkey reliability varies here).
*   **Image Assets**: If the bot gets stuck, check the `image/` folder. Game UI updates may require capturing new screenshots for `attack_button.png`, `ok.png`, etc.
*   **Browser Accessibility**: The script uses accessibility APIs to read the URL from Chrome. If it fails to detect the URL, ensure Chrome is running and supported.

## 📝 Troubleshooting

*   **"Image not found"**: Ensure your game resolution is standard or use the **F1** key to resize, and check that `image/` files match your current game UI.
*   **Bot stops after one run**: Check if the "Result" timer is timing out. Increase `BotConfig.Timeouts` in `config.ahk` if your load times are slow.
*   **Mouse moving but not clicking**: Try running the script as **Administrator**.
