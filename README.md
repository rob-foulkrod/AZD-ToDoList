---
page_type: sample
languages:
- azdeveloper
- C#
products:
- azure
- azure-app-service
- azure-functions
- azure-storage-account
- azure-monitor
urlFragment: AZD-ToDoList
name: Razor Web Page + Azure Functions + Storage Tables
description: A complete ToDo app with front-end in Razor pages hosted in App Service, backend in Azure Functions hosted in function app and data in Azure Table Storage. Using of Managed Identity to access data (no connection string and keys). Uses Azure Developer CLI (azd) to build, deploy, and monitor
---
<!-- YAML front-matter schema: https://review.learn.microsoft.com/en-us/help/contribute/samples/process/onboarding?branch=main#supported-metadata-fields-for-readmemd -->

# ToDo List - Razor Web Page + Azure Functions + Storage Tables

💪 This template scenario is part of the larger **[Microsoft Trainer Demo Deploy Catalog](https://aka.ms/trainer-demo-deploy)**.

A C# todo list app that showcases **Azure Developer CLI (azd)** end-to-end:

| Layer | Tech | Azure Service |
|---|---|---|
| Web frontend | ASP.NET Core 8 Razor Pages | Azure App Service (Linux, B1) |
| API backend | Azure Functions .NET 8 isolated | Consumption plan |
| Data | Azure Table Storage | Managed Identity (no secrets) |
| Observability | Application Insights + Log Analytics | — |

---

## Prerequisites

| Tool | Install |
|---|---|
| Azure Developer CLI | `winget install Microsoft.Azd` |
| .NET 10 SDK | [https://dotnet.microsoft.com/download/dotnet/10.0](https://dotnet.microsoft.com/download/dotnet/10.0) |
| Azure Functions Core Tools v4 | `npm i -g azure-functions-core-tools@4` |
| Azurite (local storage emulator) | `npm i -g azurite` |
| Azure subscription | https://azure.com/free |

---

## Deploy to Azure (one command)

```bash
azd init -t massimobonanni/AZD-ToDoList
azd auth login
azd up
```

`azd up` will:
1. Ask for an environment name and Azure region
2. Provision the resource group, App Service, Function App, Storage, and App Insights via Bicep
3. Build and deploy the web app and the functions API
4. Print the live URL of the web app

---

## Run Locally

Run three different instance of terminal:

**Terminal 1 — Storage emulator**
```bash
azurite --silent
```

**Terminal 2 — Functions API**
```bash
cd src/api
func start
```

**Terminal 3 — Web app**
```bash
cd src/web
dotnet run
```

Open https://localhost:5000 in your browser.

---

## Project Structure

```
azd-todolist/
├── azure.yaml              # AZD service definitions
├── infra/
│   ├── main.bicep          # Subscription-scoped entry point
│   ├── main.parameters.json
│   └── core/
│       ├── host/           # App Service + Function App Bicep
│       ├── monitor/        # Log Analytics + App Insights Bicep
│       ├── security/       # RBAC role assignments Bicep
│       └── storage/        # Storage Account Bicep
└── src/
    ├── web/                # ASP.NET Core 8 Razor Pages
    └── api/                # Azure Functions .NET 8 isolated
```

---

## Key AZD Commands

| Command | Description |
|---|---|
| `azd up` | Provision + deploy everything |
| `azd deploy` | Re-deploy code only (no infra changes) |
| `azd provision` | Provision/update infra only |
| `azd env list` | List environments |
| `azd monitor` | Open Application Insights dashboard |
| `azd down` | Delete all Azure resources |

---

## Security Highlights

- **No secrets in code or config** — Managed Identity everywhere
- Storage Account has `allowSharedKeyAccess: false` — MI-only access
- HTTPS enforced on all services, TLS 1.2 minimum
- FTPS disabled on both App Service and Function App
- RBAC scoped to minimum required roles (Blob Owner, Queue Contributor, Table Contributor)
