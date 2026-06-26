# QA Setup Readme

This guide combines:
- The workstation bootstrap using `cpat-test-config`
- The existing Playwright Agents project onboarding steps

Use this when setting up a Manual QA workstation for the Playwright Agents POC.

## Purpose

Prepare a QA machine and local project so you can run and iterate on Playwright tests in VS Code with Copilot support.

## Prerequisites

- Access to repository:
  - `https://dev.azure.com/CPaT/SoftwareDevelopment/_git/cpat-automated-tests`
- Access to branch:
  - `poc-playwright-agents`
- GitHub account with Copilot entitlement
- Permission to install software
- Windows machine with `winget`

If Git is not already installed, install it first:

```powershell
winget install --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
```

## Step 1: Bootstrap the QA Workstation (cpat-test-config)

Run these commands in an elevated PowerShell terminal.

```powershell
git clone https://github.com/microsoft/WindowsDeveloperConfig.git
cd WindowsDeveloperConfig\cpat-test-config
winget configure -f dev-config.winget --accept-configuration-agreements --disable-interactivity
```

What this gives you:
- VS Code
- Git and TortoiseGit
- Node.js LTS
- Python
- .NET 10 SDK
- VS Code Playwright extension
- Playwright CLI + Chromium browser bootstrap
- Copilot CLI profile plumbing in terminal

Checkpoint:
- `git --version` works
- `node --version` works
- `playwright --version` works

## Step 2: Open VS Code and Verify Copilot

1. Open VS Code.
2. Sign in to GitHub when prompted.
3. Confirm Copilot is active in chat.

Checkpoint:
- Copilot chat responds to a simple prompt like `Hello world`.

## Step 3: Clone the Automated Tests Repository

Use the integrated VS Code terminal.

```powershell
git clone https://dev.azure.com/CPaT/SoftwareDevelopment/_git/cpat-automated-tests
cd cpat-automated-tests
git fetch origin
git switch poc-playwright-agents
```

Checkpoint:
- `git branch --show-current` returns `poc-playwright-agents`.

## Step 4: Install Project Dependencies

From inside `cpat-automated-tests`:

```powershell
npm ci
```

Checkpoint:
- Install completes without errors.

## Step 5: Install Playwright Browsers

```powershell
npx playwright install chromium
```

If your team needs other browsers:

```powershell
npx playwright install chromium firefox webkit
```

## Step 6: Initialize Playwright Agents

```powershell
npx playwright init-agents --loop=vscode
```

Checkpoint:
- Command completes and generates expected agent setup artifacts.

## Step 7: Configure Environment Variables

Create `.env` from template:

```powershell
Copy-Item .env.example .env
```

Then edit `.env` and set required values (for example `ADMIN_PASSWORD`, `ADMIN_TEMP_PASSWORD` if applicable).

Important:
- Do not commit secrets.
- `.env` must stay gitignored.

## Step 8: Review Existing Seed Test

Open:
- `tests/seed.spec.ts`

Use this as the style and structure reference for new scenarios.

## Step 9: Run Tests

```powershell
npm test
```

Optional modes:

```powershell
npm run test:headed
npm run test:ui
npm run test:debug
```

Checkpoint:
- Dummy/seed tests execute successfully.

## Troubleshooting Quick Checks

- `playwright` command missing:
  - Restart terminal and run `playwright --version` again.
  - If still missing, run `npm install -g playwright`.
- Browser missing:
  - Run `npx playwright install chromium`.
- Copilot unavailable:
  - Re-check GitHub sign-in and entitlement in VS Code.

## Success Criteria

- VS Code installed and opens
- Copilot active in VS Code
- Git available in terminal
- Target repo cloned locally
- `poc-playwright-agents` branch checked out
- Project dependencies installed
- Playwright browser(s) installed
- Playwright agents initialized
- `.env` created and configured locally
- Seed/dummy test passes
