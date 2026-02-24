#!/bin/bash
# =============================================================================
# 15-Level Enterprise Linux Privilege Escalation Lab - MAIN SCRIPT (ENHANCED)
# =============================================================================
# Description: A realistic, linear CTF-style lab where each user (userX) must
#              find a way to become the next user (user<X+1>) to progress.
#              The final goal is to reach the root flag.
# =============================================================================

set -Eeuo pipefail

# --- Safety & Initial Checks ---
if [[ $EUID -ne 0 ]]; then
    echo "[!] Critical Error: This script must be run as root." >&2
    exit 1
fi

# --- Color Codes for Pretty Output ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Constants ---
readonly BASE_UID=2000
readonly LEVELS=15
readonly PASSWORD_FILE="/root/lab_passwords.txt"
readonly FLAG_FILE="/root/flag.txt"

# --- Global Variables ---
USER_SHELL=""

# =============================================================================
# FUNCTIONS
# =============================================================================

# --- Cleanup Function: Removes all users, files, and directories created by the lab. ---
cleanup_lab() {
    echo -e "\n${RED}[*] Starting Comprehensive Lab Cleanup...${NC}"

    # 1. Remove user-specific crontabs, print queues, etc. (though not used here, good practice)
    # 2. Kill any processes owned by lab users (optional, but safe)
    echo -e "${YELLOW}[*] Terminating any processes from lab users...${NC}"
    for i in $(seq 1 $LEVELS); do
        pkill -u "user$i" 2>/dev/null || true
    done

    # 3. Remove lab directories
    echo -e "${YELLOW}[*] Removing lab directories...${NC}"
    rm -rf /opt/tools /opt/deployment /opt/scripts /srv/dev /var/log/helpdesk \
           /var/backups /usr/local/bin/python3-cap /usr/local/bin/monitor.sh \
           /usr/local/bin/system_rotate.sh /etc/app.conf /etc/db.conf \
           /etc/passwd.bak "$PASSWORD_FILE" "$FLAG_FILE" \
           /home/user*/.config 2>/dev/null || true

    # 4. Remove sudoers fragments
    echo -e "${YELLOW}[*] Removing sudoers.d entries...${NC}"
    rm -f /etc/sudoers.d/u{1,3,4,6,7,11,14,15} 2>/dev/null || true

    # 5. Delete the lab users and their home directories
    echo -e "${YELLOW}[*] Deleting lab users...${NC}"
    for i in $(seq 1 $LEVELS); do
        if id "user$i" &>/dev/null; then
            userdel -rf "user$i" 2>/dev/null && echo -e "   - user$i ${GREEN}removed${NC}" || echo -e "   - user$i ${RED}removal failed${NC}"
        fi
    done

    echo -e "\n${GREEN}[✓] Lab cleanup completed successfully.${NC}"
}

# --- Installation Function: Creates the entire lab environment. ---
install_lab() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Starting 15-Level Enterprise PrivEsc Lab Installation (Enhanced)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"

    # --- Shell Selection ---
    echo -e "\n${YELLOW}[?] Select the default shell for lab users:${NC}"
    echo "   1) Bash (Standard)"
    echo "   2) Zsh (If installed)"
    while true; do
        read -rp "   ➜ Choice [1-2]: " shell_choice
        case $shell_choice in
            1) USER_SHELL="/bin/bash"; break ;;
            2)
                if command -v zsh &>/dev/null; then
                    USER_SHELL="/bin/zsh"
                    break
                else
                    echo -e "   ${RED}[!] Zsh is not installed. Please choose Bash.${NC}"
                fi
                ;;
            *) echo -e "   ${RED}Invalid input. Please enter 1 or 2.${NC}" ;;
        esac
    done
    echo -e "   ${GREEN}[✓] Shell set to: ${USER_SHELL}${NC}"

    # --- Generate Secure Passwords ---
    echo -e "\n${YELLOW}[*] Generating secure passwords...${NC}"
    # Using openssl for better randomness. Last one is a hint, not a password.
    cat > "$PASSWORD_FILE" <<EOF
user1:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user2:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user3:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user4:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user5:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user6:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user7:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user8:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user9:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user10:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user11:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user12:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user13:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user14:$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
user15:CHAIN_COMPLETE_ACCESS_ROOT
EOF
    chmod 600 "$PASSWORD_FILE"
    # Read passwords into an array
    mapfile -t PASS < <(awk -F: '{print $2}' "$PASSWORD_FILE")
    echo -e "   ${GREEN}[✓] Passwords saved to: ${PASSWORD_FILE}${NC}"

    # --- Create Users ---
    echo -e "\n${YELLOW}[*] Creating lab users...${NC}"
    for i in $(seq 1 $LEVELS); do
        # Delete user if exists (from a previous partial install)
        userdel -rf "user$i" 2>/dev/null || true
        # Create user with specific UID and home directory
        useradd -m -u $((BASE_UID + i)) -s "$USER_SHELL" "user$i"
        echo "user$i:${PASS[$((i-1))]}" | chpasswd
        chmod 700 "/home/user$i"
        echo -e "   - user$i ${GREEN}created${NC}"
    done

    # --- Setup Privilege Escalation Levels ---
    echo -e "\n${YELLOW}[*] Configuring privilege escalation levels...${NC}"

    # ---- Level 1: user1 -> user2 (Sudo - File Read) ----
    # user1 can run /bin/cat as root to read a log file containing user2's password.
    mkdir -p /var/log/helpdesk
    echo "user2:${PASS[1]}" > /var/log/helpdesk/tickets.log
    chown root:user1 /var/log/helpdesk/tickets.log
    chmod 640 /var/log/helpdesk/tickets.log
    echo "user1 ALL=(root) NOPASSWD: /bin/cat /var/log/helpdesk/tickets.log" > /etc/sudoers.d/u1
    echo -e "   ${GREEN}[✓]${NC} Level 1 (user1) configured."

    # ---- Level 2: user2 -> user3 (Unix Groups - File Read) ----
    # user2 is in the group that owns the file /var/backups/app/creds.txt, allowing them to read it.
    mkdir -p /var/backups/app
    echo "DB_USER=user3" > /var/backups/app/creds.txt
    echo "DB_PASS=${PASS[2]}" >> /var/backups/app/creds.txt
    chown root:user2 /var/backups/app/creds.txt
    chmod 640 /var/backups/app/creds.txt
    echo -e "   ${GREEN}[✓]${NC} Level 2 (user2) configured."

    # ---- Level 3: user3 -> user4 (Sudo - Script Execution) ----
    # user3 can execute a script as root via sudo. This script, owned by user4, prints user4's password.
    mkdir -p /opt/tools
    cat > /opt/tools/backup.sh <<EOF
#!/bin/bash
# This script simulates a backup utility and leaks the next user's credentials.
echo "user4:${PASS[3]}"
EOF
    chmod 750 /opt/tools/backup.sh
    chown user4:user4 /opt/tools/backup.sh
    echo "user3 ALL=(root) NOPASSWD: /opt/tools/backup.sh" > /etc/sudoers.d/u3
    echo -e "   ${GREEN}[✓]${NC} Level 3 (user3) configured."

    # ---- Level 4: user4 -> user5 (Sudo - Command Execution as Another User) ----
    # user4 can run a script as user5 via sudo. This script executes a shell, granting user5's privileges.
    mkdir -p /opt/deployment/scripts
    cat > /opt/deployment/scripts/deploy_app.sh <<EOF
#!/bin/bash
# Deployment script that drops into a shell as the user running it (user5 via sudo).
exec /bin/bash -i
EOF
    chmod 750 /opt/deployment/scripts/deploy_app.sh
    chown user5:user5 /opt/deployment/scripts/deploy_app.sh
    echo "user4 ALL=(user5) NOPASSWD: /opt/deployment/scripts/deploy_app.sh" > /etc/sudoers.d/u4
    echo -e "   ${GREEN}[✓]${NC} Level 4 (user4) configured."

    # ---- Level 5: user5 -> user6 (Git - Information Leak in History) ----
    # A git repository contains a config file that was committed, then deleted. The password for user6 is in the history.
    mkdir -p /srv/dev/app
    pushd /srv/dev/app > /dev/null
    git init -q
    echo "DB_USER=user6" > config.env
    echo "DB_PASS=${PASS[5]}" >> config.env
    git add config.env && git commit -m "Initial commit with DB config" -q
    # Oops! The file is deleted, but the secret remains in the git history.
    rm -f config.env
    popd > /dev/null
    chown -R root:user5 /srv/dev
    chmod -R 750 /srv/dev
    echo -e "   ${GREEN}[✓]${NC} Level 5 (user5) configured."

    # ---- Level 6: user6 -> user7 (Sudo - File Read with 'less') ----
    # user6 can run 'less' as root to view a config file. 'less' has an interactive command to run a shell.
    echo "DB_USER=user7" > /etc/app.conf
    echo "DB_PASS=${PASS[6]}" >> /etc/app.conf
    chmod 640 /etc/app.conf
    chown root:user6 /etc/app.conf
    echo "user6 ALL=(root) NOPASSWD: /usr/bin/less /etc/app.conf" > /etc/sudoers.d/u6
    echo -e "   ${GREEN}[✓]${NC} Level 6 (user6) configured."

    # ---- Level 7: user7 -> user8 (Python Insecure Deserialization) ----
    # A Python script owned by user8 loads a pickle file from a writable location.
    # user7 can control the pickle file and achieve code execution as user8.
    mkdir -p /opt/tools /var/tmp/pickles

    cat > /opt/tools/loader.py <<EOF
#!/usr/bin/env python3
import pickle
with open("/var/tmp/pickles/data.pkl", "rb") as f:
    pickle.load(f)
EOF
    chmod 750 /opt/tools/loader.py
    chown user8:user8 /opt/tools/loader.py
    chmod 777 /var/tmp/pickles
    echo "user7 ALL=(user8) NOPASSWD: /usr/bin/python3 /opt/tools/loader.py" > /etc/sudoers.d/u7
    chmod 440 /etc/sudoers.d/u7
    echo -e "   ${GREEN}[✓]${NC} Level 7 (user7) configured."

    # ---- Level 8: user8 -> user9 (Misconfigured Script) ----
    # A world-readable/writable? No, it's 755, but it's owned by user9 and contains their password.
    # Any user (like user8) can read it.
    mkdir -p /opt/scripts
    echo "user9:${PASS[8]}" > /opt/scripts/backup.sh
    chown user9:user8 /opt/scripts/backup.sh
    chmod 755 /opt/scripts/backup.sh
    echo -e "   ${GREEN}[✓]${NC} Level 8 (user8) configured."

    # ---- Level 9: user9 -> user10 (Hidden Directory & File) ----
    # A hidden .config directory in user9's home contains a file with user10's password.
    mkdir -p /home/user9/.config
    echo "user=user10" > /home/user9/.config/user_data
    echo "password=${PASS[9]}" >> /home/user9/.config/user_data
    chown -R user9:user9 /home/user9/.config
    chmod 700 /home/user9/.config
    chmod 600 /home/user9/.config/user_data
    echo -e "   ${GREEN}[✓]${NC} Level 9 (user9) configured."

    # ---- Level 10: user10 -> user11 (World-Readable Config) ----
    # A system config file is world-readable and contains user11's password.
    echo "user=user11" > /etc/db.conf
    echo "password=${PASS[10]}" >> /etc/db.conf
    chmod 644 /etc/db.conf
    echo -e "   ${GREEN}[✓]${NC} Level 10 (user10) configured."

    # ---- Level 11: user11 -> user12 (Sudo + Script Reading) ----
    # user11 can run a script as root. The script, owned by user12, contains user12's password.
    echo "user12:${PASS[11]}" > /usr/local/bin/monitor.sh
    chmod 755 /usr/local/bin/monitor.sh
    chown user12:root /usr/local/bin/monitor.sh
    echo "user11 ALL=(root) NOPASSWD: /usr/local/bin/monitor.sh" > /etc/sudoers.d/u11
    echo -e "   ${GREEN}[✓]${NC} Level 11 (user11) configured."

    # ---- Level 12: user12 -> user13 (World-Readable Backup) ----
    # A backup passwd file is world-readable and contains user13's password.
    echo "user13:${PASS[12]}" > /etc/passwd.bak
    chmod 644 /etc/passwd.bak
    echo -e "   ${GREEN}[✓]${NC} Level 12 (user12) configured."

    # ---- Level 13: user13 -> user14 (Group-Executable Script) ----
    # A script, owned by user14 and group user13, is executable by the group. It prints user14's password.
    cat > /usr/local/bin/system_rotate.sh <<EOF
#!/bin/bash
# System rotation script that leaks credentials.
echo 'user14:${PASS[13]}'
EOF
    chmod 775 /usr/local/bin/system_rotate.sh
    chown user14:user13 /usr/local/bin/system_rotate.sh
    echo -e "   ${GREEN}[✓]${NC} Level 13 (user13) configured."

    # ---- Level 14: user14 -> user15 (Sudo - Shell as Another User) ----
    # user14 can run /bin/bash as user15 without a password.
    echo "user14 ALL=(user15) NOPASSWD: /bin/bash" > /etc/sudoers.d/u14
    echo -e "   ${GREEN}[✓]${NC} Level 14 (user14) configured."

    # ---- Level 15: user15 -> root (Final Sudo Privilege) ----
    # user15 can run /bin/bash as root without a password, granting access to the final flag.
    echo "user15 ALL=(root) NOPASSWD: /bin/bash" > /etc/sudoers.d/u15
    echo -e "   ${GREEN}[✓]${NC} Level 15 (user15) configured."

    # --- Final Flag ---
    echo "FLAG{PrivEsc_Chain_Complete_Well_Done!}" > "$FLAG_FILE"
    chmod 400 "$FLAG_FILE"
    chown root:root "$FLAG_FILE"

    # --- Completion Message ---
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ LAB INSTALLATION COMPLETE!${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${YELLOW}Start User:${NC} user1"
    echo -e "  ${YELLOW}Goal:${NC} Reach user2 -> user3 ... -> user15 -> root"
    echo -e "  ${YELLOW}Password File:${NC} $PASSWORD_FILE (root only)"
    echo -e "  ${YELLOW}Final Flag:${NC} $FLAG_FILE (readable only by root)"
    echo -e "\n  ${BLUE}Tip:${NC} Use 'su - user1' to begin your challenge. Good luck!"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────${NC}\n"
}

# =============================================================================
# MAIN MENU
# =============================================================================
while true; do
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🏢 15-Level Enterprise Linux PrivEsc Lab - Manager${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "  Choose an option:"
    echo -e "    ${GREEN}[1]${NC} Install / Reinstall Lab"
    echo -e "    ${RED}[2]${NC} Cleanup Lab (Remove everything)"
    echo -e "    ${YELLOW}[3]${NC} Exit"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────${NC}"
    read -rp "  ➜ Enter choice [1-3]: " main_choice

    case $main_choice in
        1)
            install_lab
            ;;
        2)
            echo -e "\n${RED}[!] Are you sure you want to completely remove the lab?${NC}"
            read -rp "  ➜ Type 'yes' to confirm: " confirm
            if [[ "$confirm" == "yes" ]]; then
                cleanup_lab
            else
                echo -e "  ${YELLOW}Cleanup cancelled.${NC}"
            fi
            ;;
        3)
            echo -e "\n${GREEN}Exiting. Good luck with your training!${NC}"
            exit 0
            ;;
        *)
            echo -e "  ${RED}Invalid choice. Please enter 1, 2, or 3.${NC}"
            ;;
    esac
done











