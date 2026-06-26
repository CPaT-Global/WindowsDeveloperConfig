# CPaT Test Config

A WinGet Configuration (DSC) profile for an AI-enabled QA workstation on Windows.

This profile is based on CPaT Dev Config but intentionally excludes:
- WSL and Ubuntu provisioning
- Docker Desktop
- ABP Studio
- winappcli

## Files

- `dev-config.winget`: Main DSC configuration.
- `install.ps1`: Wrapper used by CI and local flow execution.
- `QA-SETUP-README.md` (repository root): End-to-end QA onboarding guide (machine bootstrap + project setup).

## Usage

```powershell
winget configure -f dev-config.winget --accept-configuration-agreements --disable-interactivity
```

## Scope

This profile keeps the core desktop and developer tooling setup from CPaT Dev Config, including UI/OS hardening and common developer apps, while avoiding container and Linux subsystem dependencies that many QA personas do not require.

It also preps Playwright QA workflows by installing the VS Code Playwright extension and bootstrapping Playwright Chromium.

## Notes

- Run from an elevated PowerShell session when possible.
- The flow is idempotent and safe to re-run.