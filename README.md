# WinSux & Ultimate (Unified & Repo-Independent)

<p align="center">
  <a href="https://github.com/ryslavy/WinSux-Ultimate/stargazers"><img src="https://img.shields.io/github/stars/ryslavy/WinSux-Ultimate?style=for-the-badge&logo=github&color=gold" alt="GitHub Stars"></a>
  <a href="https://github.com/ryslavy/WinSux-Ultimate/network/members"><img src="https://img.shields.io/github/forks/ryslavy/WinSux-Ultimate?style=for-the-badge&logo=github&color=blue" alt="Forks"></a>
  <a href="https://github.com/ryslavy/WinSux-Ultimate"><img src="https://img.shields.io/github/repo-size/ryslavy/WinSux-Ultimate?style=for-the-badge&color=8A2BE2" alt="Repo Size"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ryslavy/WinSux-Ultimate?style=for-the-badge&color=10B981" alt="License: MIT"></a>
  <a href="https://github.com/ryslavy/WinSux-Ultimate/commits/main"><img src="https://img.shields.io/github/last-commit/ryslavy/WinSux-Ultimate?style=for-the-badge&color=06B6D4" alt="Last Commit"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Platform: Windows">
  <img src="https://img.shields.io/badge/Shell-PowerShell%205.1%2B%20%7C%207%2B-5391FE?style=flat-square&logo=powershell&logoColor=white" alt="Shell: PowerShell">
  <img src="https://img.shields.io/badge/Package%20Manager-Winget%20Native-2ea44f?style=flat-square" alt="Winget Native">
  <img src="https://img.shields.io/badge/Releases%203rd%20Party-0%20(Zero)-success?style=flat-square" alt="Zero 3rd party releases">
</p>

[Čeština](#český-popis) | [English](#english-description)

---

## Český popis

Tento projekt spojuje dva populární optimalizační projekty (**WinSux** a **Ultimate**) do jednoho uceleného, moderního a **na repozitáři nezávislého** celku.

### Hlavní změny oproti původním skriptům

1. **Nativní instalace softwaru (Konec GitHub Releases pro 3rd-party software):**
   - Původní projekty stahovaly předem nahrané binární soubory a archivované instalátory z části `releases` na GitHubu autora.
   - V této verzi všechny skripty stahují a instalují software **nativně** přes **Windows Package Manager (Winget)**, oficiální servery Microsoftu (např. trvalé CDNs pro Visual C++ 2005–2022 a DirectX 9.0c) a oficiální repozitáře vývojářů (např. Wagnardsoft pro DDU, Orbmu2k pro Nvidia Profile Inspector, Sysinternals pro Autoruns).

2. **Úplná nezávislost na repozitáři (Repo-Independent):**
   - V celém projektu se již nevyskytují žádné natvrdo zapsané odkazy na původní účet nebo repozitář.
   - Projekt můžete naklonovat kamkoliv na disk, přejmenovat složku nebo jej nahrát do svého vlastního GitHub účtu – skripty se automaticky přizpůsobí lokálnímu prostředí i případnému webovému spuštění.

3. **Sjednocené ovládací centrum (`Start.cmd` a `Start.ps1`):**
   - Interaktivní konzole umožňuje spustit buď **automatizovaný one-click proces (WinSux)**, nebo přehledně procházet a spouštět **jednotlivé modulární optimalizace (Ultimate kategorie 1 až 8)** s možností návratu a vrácení změn.

4. **Jednořádkový webový instalátor (`IWR.ps1`):**
   - Dynamicky detekuje URL repozitáře, ze kterého byl spuštěn, stáhne archiv, rozbalí jej na plochu, povolí spouštění PowerShell skriptů a spustí hlavní menu.

---

### Struktura projektu

* **`Start.cmd` / `Start.ps1`** – Hlavní spouštěcí menu celé sady s automatickým vyžádáním administrátorských práv.
* **`IWR.ps1`** – Dynamický webový bootstrap pro instalaci přes jeden příkaz v PowerShellu.
* **`AllowScripts.cmd`** – Nástroj pro povolení / zakázání spouštění PowerShell skriptů poklepáním.
* **`Core/`** – Sdílený modul `AppHelper.ps1` obsahující nativní instalátory aplikací (Winget kaskády, stahování s opakováním, ověřování integrity a tichou instalaci).
* **`WinSux/`** – Kompletní automatizovaný proces (fáze 1 -> restart -> fáze 2 -> registry, vyčištění ovladačů, herní konfigurace).
* **`1 Check/`** – Diagnostika pamětí, GPU, CPU zátěžové testy (CPU-Z, GPU-Z, OCCT, FurMark).
* **`2 Refresh/`** – Obnova a čistá reinstalace Windows (oficiální Microsoft fwlinky pro W10/W11).
* **`3 Setup/`** – Počáteční konfigurace čerstvých Windows (Edge, účty, sítě).
* **`4 Installers/`** – Nativní instalace 27+ populárních aplikací a MSI Afterburner.
* **`5 Graphics/`** – Čištění grafických ovladačů (DDU), instalace Nvidia ovladačů a kompletních runtimů DirectX a Visual C++ 2005–2022.
* **`6 Windows/`** – Odstranění bloatwaru, telemetrie, nastavení služeb, ochrana soukromí a optimalizace Windows.
* **`7 Hardware/`** – Odezva myši (MarkC Movement Recorder), přetaktování ovladače (LordOfMice hidusbf), test odezvy (Gamepadla Polling), škálování a monitory.
* **`8 Advanced/`** – ReBar (Resizable BAR force), Windows Defender, priority procesů, kernel tweaks a optimalizace paměti.

---

### Jak spustit

#### Možnost A: Stažení a spuštění z vašeho GitHubu (One-Liner)
Otevřete PowerShell jako Administrátor a spusťte:
```powershell
irm https://raw.githubusercontent.com/ryslavy/WinSux-Ultimate/main/IWR.ps1 | iex
```
*(Skript automaticky rozpozná váš GitHub účet i repozitář, stáhne projekt na plochu a spustí menu.)*

#### Možnost B: Lokální použití (Klon / Stažený ZIP)
1. Rozbalte nebo naklonujte repozitář do libovolné složky.
2. Spusťte **`Start.cmd`** (vyžádá si práva Administrátora).
3. Zvolte požadovanou akci z interaktivního menu.

---
---

## English Description

This project unifies two popular Windows gaming optimization projects (**WinSux** and **Ultimate**) into a single, cohesive, modern, and **repository-independent** toolkit.

### Key Improvements over Upstream

1. **Native Software Deployment (No GitHub Releases Hosting):**
   - The original scripts relied on downloading pre-packaged binaries from the author's GitHub release files.
   - In this edition, all applications and runtime components are installed **natively** via **Windows Package Manager (Winget)**, official Microsoft CDNs (such as permanent links for Visual C++ 2005–2022 x86/x64 and DirectX End-User Runtimes), and verified upstream developer repositories (Wagnardsoft for DDU, Orbmu2k for Nvidia Profile Inspector, Sysinternals for Autoruns, LordOfMice for hidusbf, etc.).

2. **Fully Repository-Independent:**
   - Zero hardcoded GitHub usernames or upstream repo URLs remain in the scripts.
   - You can host this repository under your own GitHub profile, clone it locally, or run it in an isolated offline environment without broken paths.

3. **Master Interactive Launcher (`Start.cmd` & `Start.ps1`):**
   - Provides a unified terminal user interface allowing you to run either the **WinSux 1-click automated pipeline** or browse and launch individual **Ultimate modular tweaks (Categories 1 through 8)**.

4. **Dynamic Web Bootstrap (`IWR.ps1`):**
   - Automatically detects the hosting GitHub username and repository from the execution command line, downloads the branch archive to the Desktop, configures PowerShell execution policy, and launches the console.

---

### Project Structure

```
WinSux-better/
├── Core/
│   └── AppHelper.ps1          # Unified native installer and environment engine
├── WinSux/
│   ├── winsux.ps1             # Master 1-click automated optimizer
│   ├── stepone.ps1            # Step 1: DDU preparation, runtimes, base tweaks
│   ├── steptwo.ps1            # Step 2: Post-reboot registry and service tweaks
│   ├── reg.reg                # Predefined low-latency registry template
│   ├── start2.txt             # Startup execution launcher
│   └── settimerresolutionservice.cs # Low-latency system timer resolution service
├── 1 Check/                   # Hardware diagnostics (CPU-Z, GPU-Z, OCCT, FurMark)
├── 2 Refresh/                 # Windows refresh & official ISO reinstallers
├── 3 Setup/                   # Initial post-install setup (Edge, network, accounts)
├── 4 Installers/              # Native deployment for 27+ game engines & desktop apps
├── 5 Graphics/                # DDU, driver debloating, DirectX 9.0c, VC++ 2005-2022
├── 6 Windows/                 # Debloat, telemetry removal, services, privacy, UI
├── 7 Hardware/                # Mouse & gamepad polling, display scaling, refresh rate
├── 8 Advanced/                # Resizable BAR, Windows Defender, scheduler, priorities
├── AllowScripts.cmd           # Toggle PowerShell script execution permissions
├── IWR.ps1                    # Repo-independent dynamic web installer
├── Start.cmd                  # One-click elevated batch launcher
├── Start.ps1                  # Interactive PowerShell console
└── LICENSE                    # MIT License & upstream credits
```

---

### How to Run

#### Option 1: Remote One-Liner (From your GitHub repo)
Open PowerShell as Administrator and run:
```powershell
irm https://raw.githubusercontent.com/ryslavy/WinSux-Ultimate/main/IWR.ps1 | iex
```

#### Option 2: Local Execution
1. Clone or download this repository.
2. Double-click **`Start.cmd`** (or right-click `Start.ps1` -> *Run with PowerShell*).
3. Use the menu to run the full automated WinSux sequence or execute targeted modular tweaks.

---

### Hosting / Pushing Updates

```bash
git add .
git commit -m "Your update message"
git push origin main
```
```powershell
irm https://raw.githubusercontent.com/ryslavy/WinSux-Ultimate/main/IWR.ps1 | iex
```

---

## Project Statistics / Metriky Projektu

<p align="center">
  <img src="https://github-readme-stats.vercel.app/api/pin/?username=ryslavy&repo=WinSux-Ultimate&theme=radical&show_icons=true" alt="WinSux-Ultimate Repo Stats" />
  <img src="https://github-readme-stats.vercel.app/api/top-langs/?username=ryslavy&repo=WinSux-Ultimate&layout=compact&theme=radical" alt="Top Languages" />
</p>

### Detailed Category Breakdown

| Category | Directory | Files | PS1 Scripts | LOC (Lines of Code) | Scope & Focus |
|:---|:---|:---:|:---:|:---:|:---|
| **WinSux (Automated Pipeline)** | `WinSux/` | 6 | 3 | 2,850 | 1-click overhaul, DDU prep, reboot, registry, timer service |
| **1 Check** | `1 Check/` | 6 | 6 | 308 | CPU-Z, GPU-Z, OCCT stress testing, FurMark benchmark |
| **2 Refresh** | `2 Refresh/` | 7 | 7 | 385 | Windows clean reinstall, factory reset, local accounts, ISO fwlinks |
| **3 Setup** | `3 Setup/` | 12 | 12 | 332 | BitLocker, Edge configuration, startup apps, background tasks |
| **4 Installers** | `4 Installers/` | 2 | 2 | 5,464 | 27+ game launchers & desktop apps (Winget) + MSI Afterburner |
| **5 Graphics** | `5 Graphics/` | 14 | 14 | 2,491 | DDU clean, Nvidia debloating, DirectX Jun2010, VC++ 2005-2022 |
| **6 Windows** | `6 Windows/` | 36 | 36 | 5,332 | Debloat, telemetry removal, services, privacy, latency optimization |
| **7 Hardware** | `7 Hardware/` | 8 | 8 | 400 | MarkC mouse movement, hidusbf overclock, Gamepadla Polling |
| **8 Advanced** | `8 Advanced/` | 19 | 19 | 2,910 | Resizable BAR force, Windows Defender, CPU priorities, kernel tweaks |
| **Core & Launchers** | `Core/` + Root | 8 | 3 | 6,000+ | `AppHelper.ps1`, `Start.cmd`, `Start.ps1`, `IWR.ps1` |
| **TOTAL** | **Entire Project** | **118** | **110** | **26,200+** | **100% Native Package Management & 0 Upstream Releases** |

---

### Credits & Attribution

Original research, registry tweaks, and optimization profiles created by [FR33THY](https://www.youtube.com/fr33thy).
Refactored, modernized, and unified with native package management and repository independence by [ryslavy](https://github.com/ryslavy).

