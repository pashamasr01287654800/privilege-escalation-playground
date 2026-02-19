# 🛡️ Enterprise Linux Privilege Escalation Lab

A **realistic, multi-level Linux privilege escalation lab** designed for Red Teamers, penetration testers, and security learners who want to practice **real-world misconfigurations**, not CTF gimmicks.

---

## 🔥 Features

- 15 progressive privilege escalation levels
- Real enterprise-style misconfigurations
- Covers **multiple Linux PrivEsc techniques**
- Fully automated lab setup
- Interactive shell selection (bash / zsh)
- Clean user isolation
- No external tools required

---

## 🧠 Attack Flow

**Entry Point:** `user1`  
**Goal:** `root`

Each level simulates a **real mistake commonly found in corporate Linux environments**.

| Level | Technique |
|------|----------|
| L1 | sudo abuse + sensitive logs |
| L2 | backup credential leaks |
| L3 | SUID binary abuse |
| L4 | cron job injection |
| L5 | sudo tar abuse |
| L6 | sudo find abuse |
| L7 | Linux capabilities |
| L8 | sudo env abuse |
| L9 | sudo tar privilege escalation |
| L10 | sudo less escape |
| L11 | SUID bash |
| L12 | sudo awk abuse |
| L13 | systemd service abuse |
| L14 | sudo tar (advanced) |
| L15 | root flag |

---

## ⚙️ Requirements

- Linux system (VM recommended)
- Run as **root**
- Tested on:
  - Kali Linux
  - Ubuntu
  - Debian

---

## 🚀 Installation

```bash
git clone https://github.com/pashamasr01287654800/privilege-escalation-playground.git
cd enterprise-privesc-lab
chmod +x lab.sh
sudo ./lab.sh