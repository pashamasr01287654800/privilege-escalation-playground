# 🏢 Enterprise Linux Privilege Escalation Lab (15 Levels)

A **realistic, linear, enterprise-style Linux privilege escalation lab** designed for **Red Teamers, penetration testers, and security learners** who want to practice **real-world Linux misconfigurations** — not artificial CTF tricks.

This lab enforces a **strict escalation chain**:

user1 → user2 → user3 → user4 → user5 → user6 → user7 → user8 → user9 → user10 → user11 → user12 → user13 → user14 → user15 → root

No skipping. No brute force. Just **enumeration + exploitation**, exactly like real enterprise environments.

---

<p align="center">
  <img src="banner.png" alt="Enterprise Linux Privilege Escalation Lab" width="800">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Levels-15-blue">
  <img src="https://img.shields.io/badge/Style-Enterprise-red">
  <img src="https://img.shields.io/badge/Setup-Automated-green">
  <img src="https://img.shields.io/badge/Platform-Linux-yellow">
</p>

---

## 🔥 Features

- 15 progressive privilege escalation levels
- Strict linear chain (no skipping)
- Enterprise-style Linux misconfigurations
- No external exploitation frameworks required
- Fully automated installation and cleanup
- Random passwords generated per installation
- Bash or Zsh shell selection
- Clean user isolation

---

## 🧠 Attack Flow

user1 → user2 → user3 → user4 → user5  
user6 → user7 → user8 → user9 → user10  
user11 → user12 → user13 → user14 → user15 → root

- **Entry user:** `user1`  
- **Final objective:** `/root/flag.txt`

---

## 🎯 Challenge Matrix (Script-Accurate)

| Level | From   | To     | Technique                          |
|------:|--------|--------|------------------------------------|
| 1     | user1  | user2  | Sudo file read                     |
| 2     | user2  | user3  | Group-readable backup              |
| 3     | user3  | user4  | Sudo script execution              |
| 4     | user4  | user5  | Sudo as another user               |
| 5     | user5  | user6  | Git history credential leak        |
| 6     | user6  | user7  | `less` via sudo (shell escape)     |
| 7     | user7  | user8  | Python insecure deserialization    |
| 8     | user8  | user9  | World-readable script              |
| 9     | user9  | user10 | Hidden `.config` credentials       |
| 10    | user10 | user11 | World-readable config              |
| 11    | user11 | user12 | Sudo-readable script               |
| 12    | user12 | user13 | Backup credential exposure         |
| 13    | user13 | user14 | Group-executable script            |
| 14    | user14 | user15 | Sudo shell as user                 |
| 15    | user15 | root   | Sudo root shell                    |

---

## 🛡️ Attack Vectors Covered

- Sudo misconfigurations
- Group permission abuse
- World-readable sensitive files
- Git history leaks
- Insecure Python deserialization
- Hidden dotfiles
- Script ownership and permission mistakes

All scenarios reflect **real enterprise security failures**.

---

## ⚙️ Requirements

- Linux (Kali / Ubuntu / Debian / Arch)
- Root privileges
- Required tools:
  - `bash`
  - `openssl`
  - `git`
  - `python3`
  - `less`

---

## 🚀 Installation

```bash
git clone https://github.com/pashamasr01287654800/privilege-escalation-playground.git
cd privilege-escalation-playground
chmod +x lab.sh
sudo ./lab.sh