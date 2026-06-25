# DT-Agent-POC-Accelerator

Infrastructure-as-Code accelerator for the **Discount Tire Store Performance Advisor** — an AI Foundry agent that helps store managers, AVPs, and RVPs understand performance and take action.

## What Gets Deployed

| Resource | SKU | Purpose |
|----------|-----|---------|
| **Azure AI Foundry** (account + project) | S0 | Hosts the agent, model deployments, and tool connections |
| **GPT-5.4** model deployment | GlobalStandard, 10K TPM | LLM powering the agent |
| **Azure AI Search** | Basic, semantic enabled | Knowledge base for operational playbooks |
| **Microsoft Fabric** capacity | F4 (configurable) | Semantic layer, Direct Lake, Power BI |
| **VNet + Private Endpoints** *(optional)* | — | Network isolation for AI Services & Search |

## Quick Start

```bash
# 1. Install Azure Developer CLI
winget install Microsoft.Azd

# 2. Clone and initialize
git clone https://github.com/claraworkman/DT-Agent-POC-Accelerator.git
cd DT-Agent-POC-Accelerator

# 3. Create environment and deploy
azd init
azd env set AZURE_LOCATION eastus2
azd env set FABRIC_ADMIN_UPN your-email@domain.com
azd up
```

## Configuration

Set these environment variables before `azd up`:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_LOCATION` | Yes | `eastus2` | Azure region |
| `AZURE_SEARCH_LOCATION` | No | Same as primary | Override if primary region has no Search capacity |
| `FABRIC_ADMIN_UPN` | Yes | — | Email of the Fabric capacity admin |
| `ENABLE_PRIVATE_NETWORKING` | No | `false` | Provisions VNet + private endpoints |

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  Resource Group: DT-Agent-POC                        │
│                                                      │
│  ┌─────────────────────┐  ┌───────────────────────┐ │
│  │  AI Foundry Account │  │  Azure AI Search      │ │
│  │  └─ Project         │  │  (playbooks index)    │ │
│  │     └─ Agent        │  └───────────────────────┘ │
│  │     └─ GPT-5.4      │                            │
│  └─────────────────────┘  ┌───────────────────────┐ │
│                            │  Fabric Capacity (F4) │ │
│                            │  (semantic layer)     │ │
│                            └───────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

## Private Networking (Optional)

When `ENABLE_PRIVATE_NETWORKING=true`:

- VNet with `/16` address space
- Private endpoint subnet (`/24`)
- Private endpoints for AI Foundry and AI Search
- Private DNS zones for name resolution
- Public access **disabled** on both services

```bash
azd env set ENABLE_PRIVATE_NETWORKING true
azd up
```

## Post-Deployment

After `azd up` succeeds, configure the agent's tools in the Foundry portal or via the SDK:

1. **AI Search tool** — auto-wired via the `ai-search-connection`
2. **MCP tools** (Weather, Traffic, Databricks Genie) — deploy as Azure Functions, register as MCP connections
3. **Work IQ** — add M365 grounding via the Foundry portal
4. **Web Search** — enable Bing grounding in the project

## Teardown

```bash
azd down --purge
```

The `--purge` flag is required to permanently delete soft-deleted resources (AI Services).

## Cost Estimate (Monthly)

| Resource | Estimated Cost |
|----------|---------------|
| AI Foundry (S0) | ~$0 (pay-per-token only) |
| GPT-5.4 (10K TPM) | ~$0.01/1K input tokens |
| AI Search (Basic) | ~$70/mo |
| Fabric F4 | ~$526/mo (can pause) |
| **Total (active)** | **~$600/mo** |

> 💡 Fabric capacity can be paused when not in use — reduces cost to ~$70/mo for Search only.

## License

MIT
