# 🧹 Flutter Project Cleaner

A highly performant, cross-platform Dart script that recursively scans for Flutter projects on your system and cleans up heavy, unnecessary build output files (`build/`, `.dart_tool/`, `ios/Pods`, `macos/Pods`, `.symlinks`). It can also clean system-level caches (Gradle, Xcode, Docker). This helps free up gigabytes of disk space instantly!

---

## 🚀 Installation & Usage

To quickly run this script from anywhere on your system by simply typing `fclean`, follow the instructions for your specific Operating System below.

### 🍎 macOS

macOS uses **Zsh** by default. To add a terminal alias:

1. Open your terminal and run the following command to add the alias to your Zsh profile:
   ```bash
   echo 'alias fclean="dart run /Users/altaysakarya/my_programs/flutter_project_cleaner/flutter_cleaner.dart"' >> ~/.zshrc
   source ~/.zshrc
   ```
2. You can now type `fclean` in any directory to scan and clean it!

> **Permission Errors (Operation not permitted):**
> If you run the script on protected folders like `~/Documents`, `~/Downloads`, or `~/Desktop` and encounter permission errors, you must grant "Full Disk Access" to your Terminal.
> 1. Open **System Settings** > **Privacy & Security** > **Full Disk Access**.
> 2. Toggle the switch next to **Terminal** (or iTerm2).
> 3. Restart the terminal fully (`Cmd + Q`).

### 🐧 Linux

Linux commonly uses **Bash** or **Zsh**. Add the alias to your active shell profile:

1. For Bash users (default on most distributions like Ubuntu):
   ```bash
   echo 'alias fclean="dart run /Users/altaysakarya/my_programs/flutter_project_cleaner/flutter_cleaner.dart"' >> ~/.bashrc
   source ~/.bashrc
   ```
   *(If you use Zsh, use `.zshrc` similarly to the macOS instructions).*
2. Type `fclean` anywhere to use the script.

### 🪟 Windows

On Windows, you can create a permanent alias (function) using **PowerShell**:

1. Open PowerShell and run this command to find or create your profile:
   ```powershell
   if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
   ```
2. Open the profile in Notepad:
   ```powershell
   notepad $PROFILE
   ```
3. Add the following function to the bottom of the file and save it (update the absolute path to point to your script's actual location in Windows format):
   ```powershell
   function fclean {
       dart run "/Users/altaysakarya/my_programs/flutter_project_cleaner/flutter_cleaner.dart" $args
   }
   ```
4. Restart your PowerShell or run `. $PROFILE`. Now you can type `fclean` from anywhere!

---

## 🛠️ How to use the command once set up:

- To clean the **current directory and all its subdirectories**, simply type:
  ```bash
  fclean
  ```
- To clean a **specific path or directory**, provide the path as an argument:
  ```bash
  fclean ~/Projects/Flutter
  ```
- To preview what would be deleted **without actually deleting anything**, use `--dry-run`:
  ```bash
  fclean --dry-run
  fclean ~/Projects/Flutter --dry-run
  ```

When you run the script, you will first be asked whether you also want to clean system-level caches (Gradle, Xcode DerivedData, Xcode iOS DeviceSupport, unavailable Xcode simulators, and Docker). All cleanups report the actual size of each deleted item, and the final summary shows the total space saved across both project and system caches.
