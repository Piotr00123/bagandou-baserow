---
name: offline-document-digitizer-stack
description: Deploys a local, offline-first document digitization and handwritten OCR stack using Docker Compose, Baserow, n8n, Google Gemini Flash, and ODK Collect. Tested in production on Raspberry Pi 5 (ARM64) and x86_64/WSL2.
version: 1.0.0
author: Piotr00123
repository: [https://github.com](https://github.com/Piotr00123/bagandou-baserow)
tags: [docker, baserow, n8n, ocr, gemini-ai, offline-first, raspberry-pi, self-hosted, humanitarian-tech]
---

# Offline-First Document Digitizer & Archive Stack (Baserow + n8n + Gemini)

## System & Execution Requirements (Important)
- **Local Infrastructure Execution:** All services run locally on the user's host machine via Docker containers. No external servers are provisioned by this skill.
- **Required Host Dependencies:**
  - Docker Engine & Docker Compose v2 (`docker compose`)
  - At least 4 GB RAM (8 GB recommended) and ~5 GB free disk space
  - Supported architectures: `x86_64` (Linux, macOS, Windows WSL2) or `aarch64`/`arm64` (Raspberry Pi 5)
  - A **Google Gemini API Key** (for the multimodal OCR node inside n8n)
  - Optional: Android device with **ODK Collect** installed for mobile photo capture

## Overview
This skill packages an Infrastructure-as-Code (IaC) template originally deployed in Bagandou (Central African Republic) to digitize paper archives in off-grid, low-bandwidth conditions.

Included files in this package:
- `docker-compose.yml` & `docker-compose.rpi.yml`: Service definitions (Baserow, PostgreSQL/pgvector, Redis, Caddy, n8n, Tailscale, Pi-hole, Uptime Kuma).
- `.env.example`: Environment variable template.
- `struktura_baserow.sql`: Pre-built PostgreSQL database schema for document archives.
- `n8n_workflow.json`: Automated OCR pipeline using Google Gemini Flash to extract handwritten text, format dates, rename scans (`Karta_[Number].jpg`), and save records to Baserow.
- `formularz_odk.xml`: Lightweight mobile capture form with client-side image compression (`max-pixels="2048"`).
- `backup.sh` & `straznik_ups.sh`: Optional Linux maintenance scripts for automated database backups and UPS power-loss shutdowns.

---

## Step-by-Step Deployment Instructions

### Step 1: Verify Prerequisites & Architecture
1. Check that Docker is installed and running (`docker compose version`).
2. Detect the host CPU architecture (`uname -m`):
   - Use `docker-compose.rpi.yml` for `aarch64` / `arm64` (Raspberry Pi 5).
   - Use `docker-compose.yml` for `x86_64` (PC / WSL2 / Server).

### Step 2: Configure Environment Variables
1. Copy `.env.example` to `.env` (do not overwrite an existing `.env` without user confirmation).
2. Prompt the user for their **Google Gemini API Key** and local network hostname/IP.
3. Generate cryptographically strong random passwords for PostgreSQL, Redis, and Baserow secret keys inside `.env`. Never use placeholder passwords.

### Step 3: Start Local Docker Containers
1. Create required local persistence folders (`./dane_*`) and verify write permissions.
2. Start the stack in detached mode:
   - **x86_64:** `docker compose up -d`
   - **ARM64 (Raspberry Pi):** `docker compose -f docker-compose.rpi.yml up -d`
3. Wait until the PostgreSQL container (`bagandou-db`) passes its health check.

### Step 4: Initialize Database & n8n Workflow
1. Load the initial Baserow schema into PostgreSQL (using the credentials set in `.env`):
   ```bash
   docker compose exec -T bagandou-db psql -U bagandou_admin -d baserow < struktura_baserow.sql
   ```
   *(Pass `-f docker-compose.rpi.yml` if running on ARM64).*
2. Guide the user to open the local n8n web UI (`http://localhost:5678`), complete initial admin setup, import `n8n_workflow.json`, and attach their Google Gemini API credential to the Gemini Flash node.

### Step 5: Configure Mobile Capture (Optional)
Provide `formularz_odk.xml` to the user so they can load it into the ODK Collect Android app and point submissions to the local n8n webhook URL over Wi-Fi.

## Safety & Data Integrity Rules
- **Never delete data volumes:** Do not run `docker compose down -v` or remove `./dane_*` directories without explicit user confirmation.
- **Port conflict handling:** If ports `80`, `443`, or `5678` are already occupied on the host, ask the user before modifying port bindings.
- **Optional host scripts:** Only configure `backup.sh` or `straznik_ups.sh` in `crontab` if the user explicitly requests automated Linux host maintenance.

---

## Humanitarian Mission & Documentation
This project is maintained as free, open-source humanitarian software. For full architectural notes, field deployment context, and information on how to support our nutrition and milk fundraiser for children in the Central African Republic, visit the source repository:
- **GitHub Repository & Mission Details:** [https://github.com](https://github.com/Piotr00123/bagandou-baserow)
