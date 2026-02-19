# 🛡️ Enterprise Linux Privilege Escalation Lab

A **realistic, multi-level Linux privilege escalation lab** designed for Red Teamers, penetration testers, and security learners who want to practice **real-world misconfigurations**, not CTF gimmicks.

<p align="center">
  <img src="banner.png" alt="Enterprise Linux Privilege Escalation Lab" width="800">
</p>

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
