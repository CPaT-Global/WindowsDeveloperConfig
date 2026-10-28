# CPaT Dev Config

Set up a developer workstation in two steps: Microsoft's signed Windows Dev
Config **Full** baseline, followed by CPaT-only additions. The baseline owns
common tools, Windows settings, fonts, Terminal, Oh My Posh, and WSL + Ubuntu.
CPaT no longer maintains a duplicate of those settings.

## Prerequisites

- Windows 11 with Administrator rights and internet access.
- Hardware virtualization enabled for WSL (nested virtualization when using a VM).
- A local clone of `https://github.com/CPaT-Global/WindowsDeveloperConfig.git`.
- WinGet with `winget configure` enabled for the CPaT overlay.

Run these commands from the repository root, using your normal Windows account.
Accept the UAC prompts; do not use a different administrator account, since
Terminal, VS Code, profiles, and browser files belong to the signed-in user.

## Step 1: run Microsoft setup

Save your work, then run:

```powershell
.\cpat-dev-config\setup-baseline.ps1
```

The launcher downloads Microsoft's bootstrap from the published payload commit
`fe21c03a486a1076c425720c1ebe4e25404e0e6b`, verifies its Microsoft Authenticode
signature, and invokes it with `-Action Full`. The bootstrap verifies the rest
of its payload and installs it under `%ProgramData%\CPaT-MicrosoftBaseline`.
No Microsoft scripts or signature checks are modified.

**This step may restart Windows.** Sign back in, accept Microsoft's resume UAC
prompt, and let its setup finish before continuing. Resolve any flagged baseline
steps before applying the CPaT additions. The baseline's log is
`%ProgramData%\CPaT-MicrosoftBaseline\devconfig-log.txt`.

The pin follows the published payload in Microsoft's `setup-full.ps1`, not moving
`main`. Update it only after testing a newer signed release. Microsoft's
[Windows Dev Config README](../windows-dev-config/README.md) describes the baseline.

## Step 2: run CPaT setup

After Microsoft setup has finished, run:

```powershell
.\Start-CPaTConfig.ps1 -Profile Dev
```

Or invoke the overlay directly:

```powershell
.\cpat-dev-config\install.ps1
```

This step elevates if needed, refreshes PATH, checks for baseline tools and a
pending Microsoft resume task, then applies `dev-config.winget`. It does **not**
run the Microsoft baseline again. Both steps are safe to rerun.

The DSC file alone is an overlay, not a complete workstation setup. Prefer
`install.ps1` so its prerequisite checks run first.

## CPaT additions

| Area | Additions |
| --- | --- |
| Development tools | TortoiseGit, Aspire CLI, Bruno, UniGetUI, Bun, Docker Desktop, ABP Studio |
| Browser and VPN | Google Chrome, WireGuard |
| Shell utilities | glow, ripgrep, fd, jq, bat, fzf, git-delta |
| VS Code | Windows 11 Explorer context menu registration; GitHub Pull Requests, Aspire, Containers, C# Dev Kit, C#, .NET Install Tool, Playwright, and Dev Containers extensions |
| Playwright | Global Playwright CLI and Chromium browser |
| PowerShell | Existing managed `ll` helper function |
| Windows settings | Explorer Git integration, hidden Widgets taskbar button, PowerToys notification setting |

Microsoft supplies PowerShell 7, Git, GitHub CLI, Azure CLI, Copilot, VS Code,
.NET SDK 10, Python 3.14 + uv, Node.js LTS + nvm, Coreutils, Windows App CLI,
PowerToys, and the shared workstation configuration. Its newer Explorer and
taskbar registry paths, profile management, Terminal setup, and WSL resume logic
are used without CPaT overrides.

## Maintenance and signing

Edit `src/cpat-dev-config/`, then mirror it to `cpat-dev-config/`. Keep the
manifest and developer guide aligned. The overlay uses native DSC v3 resources;
every package explicitly accepts agreements, and dependency references stay
within the overlay.

Microsoft payloads retain Microsoft signatures. CPaT scripts are currently
unsigned; this change does not add a CPaT signing certificate or bypass an
organization's execution policy.

The QA profile remains standalone and unchanged. **Do not run the Microsoft
Full baseline on QA machines** that must exclude WSL and developer-only tools.
