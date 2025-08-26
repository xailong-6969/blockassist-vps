# blockassist-vps-guide
# 🚀 BlockAssist on Kasm — Setup Guide

Welcome to the **BlockAssist** setup guide! This walkthrough installs Kasm (optional), sets up Java + Python, and runs BlockAssist on the Kasm web desktop.

---

## 🧭 Prerequisites

- ✅ Ubuntu 22.04 or 24.04 (root or sudo)
- ✅ `git` and `curl` installed
- ✅ Browser access to your VM (for Kasm desktop)
- ✅ Kasm Workspaces (installed in Step 1)
- ✅ ~100 GB free disk space

---

## ⚙️ Setup Steps

### 📦 1.Install Kasm

```bash
chmod +x kasm-install.sh
sudo ./kasm-install.sh
```
- After install, open in your browser:

- https://(your-vm-public-ip)(if routed)
- open the public ip on your local browser

- Credentials are printed and saved to ~/kasm_credentials.txt
- login with the admin details 
<img width="359" height="117" alt="image" src="https://github.com/user-attachments/assets/4535b201-2a91-4f28-97e4-7da04004fc7b" />

### 🚀After login follow this steps:-
- ✅there will be a dashboard like this
<img width="1916" height="863" alt="image" src="https://github.com/user-attachments/assets/eb67fb18-3279-448f-8b5a-d92955e32e95" />

- ✅Then click on workspaces
<img width="317" height="867" alt="image" src="https://github.com/user-attachments/assets/21bbccfc-0389-441d-880d-839cb672b22d" />

- ✅Add a workspace
<img width="1634" height="898" alt="image" src="https://github.com/user-attachments/assets/df222e56-25b3-4e09-b5c9-494e5e83f6fb" />

- ✅Choose container then ubuntu jammy desktop
<img width="1642" height="901" alt="image" src="https://github.com/user-attachments/assets/14f5d20d-c237-4834-91d5-a92e4c976c54" />

- Mention the cores and dont need to chnage the memory and gpu count
<img width="1533" height="801" alt="image" src="https://github.com/user-attachments/assets/f9ce457e-2ce2-4b01-afcc-53cc979672ec" />

- ✅ To give the workspace full root access, find the **Docker Run Config Override (JSON)** field and paste this configuration:

```json
{
  "hostname": "kasm",
  "user": "root"
}
```










  
