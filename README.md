
# 💾 Azure SQL Server Automated Backup to Azure Blob Storage

This project provides PowerShell scripts to **export Azure SQL Server databases to a .bacpac format** and save them in a designated Azure Blob Storage container. The export operation supports **Azure AD authentication**, and the `.bacpac` files are stored in environment-specific paths to separate production and test data.

---

## 📁 Project Structure

```
C:\Scripts\
├── Export-SQL-Backup-Live.ps1      # Script for the Live environment
├── Export-SQL-Backup-Test.ps1      # Script for the Test environment
└── README.md                       # This file
```

---

## 🌍 Environment Overview

| Environment | SQL Server Name             | Resource Group              | Subscription Name |SubscriptionID                            |

| **Live**    | `superenvironment0live`     | `superenvironment-live`     | Apps Live         |`c3885f45-6172-4386-a8a3-8bcc83a96b8e`    |
| **Test**    | `superenvironment0test-envs`| `superenvironment-test-envs`| Apps Test         |`06512459-9f85-4800-a92b-d333fa1b2ad2`    |
| **Storage** | `decommissioned0live`       | `Decommissioned-RG`         | Live              |`2c59dd5f-a222-476d-ba56-3e0c009af644`    |

---

## 🗃️ Storage Container Structure

Both environments write their exports to the **same blob container**: `aws` in the `decommissioned0live` storage account.

To **distinguish between environments**, a folder prefix is used in the `StorageUri`:

```
aws/
├── live/
│   └── 2025-xx-xx/
│       └── production_db.bacpac
└── test/
    └── 2025-xx-xx/
        └── test_db.bacpac
```

📌 You **must** ensure that the `StorageUri` includes `/live` or `/test` to avoid mixing backups.

---

## 🧰 Prerequisites

1. **PowerShell** installed (preferably 5.1 or later).
2. **Az PowerShell module** installed:
   ```powershell
   Install-Module -Name Az -Repository PSGallery -Force
   ```
3. Access to:
   - SQL server with **Microsoft Entra Admin** rights.
   - Azure subscription that owns the SQL servers and the storage account.
4. Authentication:
   - Azure AD credentials (your Entra user must be an admin on the SQL server).

---

## 🔐 Authentication Details

The scripts use Azure AD authentication:

- Your Azure AD user (e.g., `you@yourcompany.com`) **must be added as an Entra administrator** on the SQL server.
- On script execution, you'll be prompted to enter your Azure AD password securely using:
  ```powershell
  Read-Host -AsSecureString "Enter Azure AD password"
  ```

---

## 🚀 How to Run Backups

### 🔵 Live Environment Backup

Script: `Export-SQL-Backup-Live.ps1`

#### What it does:
- Connects to the **Apps Live** subscription.
- Queries all non-system databases on `superenvironment0live`.
- Creates a `.bacpac` export for each database.
- Saves each file to `aws/live/<timestamp>/` in the storage account.

#### To run:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Export-SQL-Backup-Live.ps1"
```

---

### 🟡 Test Environment Backup

Script: `Export-SQL-Backup-Test.ps1`

#### What it does:
- Connects to the **superenvironment-test-envs** subscription.
- Queries all non-system databases on `superenvironment0test-envs`.
- Creates a `.bacpac` export for each database.
- Saves each file to `aws/test/<timestamp>/` in the storage account.

#### To run:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Export-SQL-Backup-Test.ps1"
```

## 📦 File Sizes

Don't be alarmed if `.bacpac` files are small. These are ZIP-compressed exports:
- Small DBs compress to < 1MB.
- Large DBs can still be < 50MB if they have mostly empty tables or indexes.

---

## 📌 Notes

- SQL system databases like `master`, `msdb`, `tempdb` are automatically **excluded** from export.
- Storage authentication is handled using **Storage Access Keys**, not SAS tokens or identity-based access.

---

## ✅ Summary

| Task | Script | Container Path |
|------|--------|----------------|
| Export Live Databases | `Export-SQL-Backup-Live.ps1` | `aws/live/YYYY-MM-DD` |
| Export Test Databases | `Export-SQL-Backup-Test.ps1` | `aws/test/YYYY-MM-DD` |

This setup ensures secure, automated, environment-isolated backups of all critical Azure SQL databases.

---

