#!/bin/bash
# =============================================================================
# 15-Level Enterprise Linux Privilege Escalation Lab - MAIN SCRIPT (FIXED)
# =============================================================================
# Description: A realistic, linear CTF-style lab where each user (userX) must
#              find a way to become the next user (user<X+1>) to progress.
#              The final goal is to reach the root flag.
#              Supports both Bash and Zsh as user shells.
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
declare -a PASS  # Array to store generated passwords

# =============================================================================
# FUNCTIONS
# =============================================================================

# --- Cleanup Function: Removes all users, files, and directories created by the lab. ---
cleanup_lab() {
    echo -e "\n${RED}[*] Starting Comprehensive Lab Cleanup...${NC}"
    
    # Confirm cleanup
    echo -e "${RED}[!] WARNING: This will delete ALL lab users, their home directories, and all lab files!${NC}"
    echo -e "${RED}[!] This action is IRREVERSIBLE!${NC}"
    read -rp "  ➜ Type 'YES' to confirm deletion: " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo -e "  ${GREEN}Cleanup cancelled.${NC}"
        return 0
    fi

    # 1. Kill any processes owned by lab users
    echo -e "${YELLOW}[*] Terminating any processes from lab users...${NC}"
    for i in $(seq 1 $LEVELS); do
        pkill -u "user$i" 2>/dev/null || true
    done

    # 2. Remove ALL lab directories and files
    echo -e "${YELLOW}[*] Removing all lab files and directories...${NC}"
    rm -rf /opt/tools /opt/deployment /opt/scripts /srv/dev /var/log/helpdesk \
           /var/backups /usr/local/bin/python3-cap /usr/local/bin/monitor.sh \
           /usr/local/bin/system_rotate.sh /etc/app.conf /etc/db.conf \
           /etc/passwd.bak "$PASSWORD_FILE" "$FLAG_FILE" 2>/dev/null || true
    
    # Remove all lab-specific files from home directories
    for i in $(seq 1 $LEVELS); do
        # Remove specific files
        rm -f "/home/user$i/pass.txt" "/home/user$i/secret.txt" 2>/dev/null || true
        rm -rf "/home/user$i/.config" "/home/user$i/.zshrc" "/home/user$i/.zhistory" 2>/dev/null || true
    done

    # 3. Remove sudoers fragments
    echo -e "${YELLOW}[*] Removing sudoers.d entries...${NC}"
    rm -f /etc/sudoers.d/u{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15} 2>/dev/null || true

    # 4. Delete the lab users and their home directories
    echo -e "${YELLOW}[*] Deleting lab users and their home directories...${NC}"
    for i in $(seq 1 $LEVELS); do
        if id "user$i" &>/dev/null; then
            userdel -rf "user$i" 2>/dev/null && echo -e "   - user$i ${GREEN}removed${NC}" || echo -e "   - user$i ${RED}removal failed${NC}"
        fi
    done

    echo -e "\n${GREEN}[✓] Lab cleanup completed successfully.${NC}"
    echo -e "${YELLOW}[✓] All users, home directories, and lab files have been removed.${NC}"
}

# --- Check prerequisites (only zsh if selected) ---
check_prerequisites() {
    local missing=()
    # Check for zsh only if the user selected it
    if [[ "$USER_SHELL" == "/bin/zsh" ]] && ! command -v zsh >/dev/null 2>&1; then
        missing+=("zsh")
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[!] Missing required packages: ${missing[*]}${NC}" >&2
        echo -e "${YELLOW}Please install them and rerun the script.${NC}" >&2
        exit 1
    fi
}

# --- Generate secure passwords ---
generate_passwords() {
    echo -e "\n${YELLOW}[*] Generating secure passwords...${NC}"
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

    # FIX: Use a while loop instead of mapfile for better compatibility
    PASS=()
    while IFS=: read -r user pass; do
        PASS+=("$pass")
    done < "$PASSWORD_FILE"

    if [[ ${#PASS[@]} -ne 15 ]]; then
        echo -e "${RED}[!] Error: Password array size is ${#PASS[@]}, expected 15.${NC}" >&2
        exit 1
    fi
    echo -e "   ${GREEN}[✓] Passwords saved to: ${PASSWORD_FILE}${NC}"
}

# --- Create users ---
create_users() {
    echo -e "\n${YELLOW}[*] Creating lab users...${NC}"
    for i in $(seq 1 $LEVELS); do
        # Remove old user if exists (including group)
        userdel -rf "user$i" 2>/dev/null || true
        groupdel "user$i" 2>/dev/null || true
        
        # Create group and user
        groupadd -f "user$i"
        useradd -m -u $((BASE_UID + i)) -g "user$i" -s "$USER_SHELL" "user$i"
        echo "user$i:${PASS[$((i-1))]}" | chpasswd
        chmod 700 "/home/user$i"
        echo -e "   - user$i ${GREEN}created${NC}"
    done
}

# --- Configuration functions for each level ---
configure_level1() {
    mkdir -p /var/log/helpdesk
    echo "user2:${PASS[1]}" > /var/log/helpdesk/tickets.log
    chown user2:user2 /var/log/helpdesk/tickets.log
    chmod 640 /var/log/helpdesk/tickets.log
    echo "user1 ALL=(user2) NOPASSWD: /bin/cat /var/log/helpdesk/tickets.log" > /etc/sudoers.d/u1
    chmod 440 /etc/sudoers.d/u1
    echo -e "   ${GREEN}[✓]${NC} Level 1 (user1) configured."
}

configure_level2() {
    mkdir -p /var/backups/app
    echo "DB_USER=user3" > /var/backups/app/creds.txt
    echo "DB_PASS=${PASS[2]}" >> /var/backups/app/creds.txt
    chown root:user2 /var/backups/app/creds.txt
    chmod 640 /var/backups/app/creds.txt
    echo -e "   ${GREEN}[✓]${NC} Level 2 (user2) configured."
}

configure_level3() {
    mkdir -p /opt/tools
    cat > /opt/tools/backup.sh <<EOF
#!/bin/bash
echo "user4:${PASS[3]}"
EOF
    chmod 750 /opt/tools/backup.sh
    chown user4:user4 /opt/tools/backup.sh
    echo "user3 ALL=(user4) NOPASSWD: /opt/tools/backup.sh" > /etc/sudoers.d/u3
    chmod 440 /etc/sudoers.d/u3
    echo -e "   ${GREEN}[✓]${NC} Level 3 (user3) configured."
}

configure_level4() {
    mkdir -p /home/user5
    echo "user5:${PASS[4]}" > /home/user5/secret.txt
    chown user5:user5 /home/user5/secret.txt
    chmod 600 /home/user5/secret.txt

    mkdir -p /opt/deployment/scripts
    cat > /opt/deployment/scripts/deploy_app.sh <<EOF
#!/bin/bash
cat /home/user5/secret.txt
EOF
    chmod 750 /opt/deployment/scripts/deploy_app.sh
    chown user5:user5 /opt/deployment/scripts/deploy_app.sh

    echo "user4 ALL=(user5) NOPASSWD: /opt/deployment/scripts/deploy_app.sh" > /etc/sudoers.d/u4
    chmod 440 /etc/sudoers.d/u4
    echo -e "   ${GREEN}[✓]${NC} Level 4 (user4) configured."
}

configure_level5() {
    mkdir -p /home/user6
    echo "user6:${PASS[5]}" > /home/user6/pass.txt
    chown user6:user6 /home/user6/pass.txt
    chmod 600 /home/user6/pass.txt

    echo "user5 ALL=(user6) NOPASSWD: /bin/cat /home/user6/pass.txt" > /etc/sudoers.d/u5
    chmod 440 /etc/sudoers.d/u5
    echo -e "   ${GREEN}[✓]${NC} Level 5 (user5) configured."
}

configure_level6() {
    groupadd -f user7
    install -m 640 -o user7 -g user7 /dev/null /etc/app.conf
    echo "DB_USER=user7" > /etc/app.conf
    echo "DB_PASS=${PASS[6]}" >> /etc/app.conf
    echo "user6 ALL=(user7) NOPASSWD: /usr/bin/less /etc/app.conf" > /etc/sudoers.d/u6
    chmod 440 /etc/sudoers.d/u6
    echo -e "   ${GREEN}[✓]${NC} Level 6 (user6) configured."
}

configure_level7() {
    mkdir -p /home/user8
    echo "user8:${PASS[7]}" > /home/user8/secret.txt
    chown user8:user8 /home/user8/secret.txt
    chmod 600 /home/user8/secret.txt
    echo "user7 ALL=(user8) NOPASSWD: /usr/bin/cat /home/user8/secret.txt" > /etc/sudoers.d/u7
    chmod 440 /etc/sudoers.d/u7
    echo -e "   ${GREEN}[✓]${NC} Level 7 (user7) configured."
}

configure_level8() {
    mkdir -p /opt/scripts
    echo "user9:${PASS[8]}" > /opt/scripts/backup.sh
    chown user9:user8 /opt/scripts/backup.sh
    chmod 755 /opt/scripts/backup.sh
    echo -e "   ${GREEN}[✓]${NC} Level 8 (user8) configured."
}

configure_level9() {
    mkdir -p /home/user9/.config
    echo "user=user10" > /home/user9/.config/user_data
    echo "password=${PASS[9]}" >> /home/user9/.config/user_data
    chown -R user9:user9 /home/user9/.config
    chmod 700 /home/user9/.config
    chmod 600 /home/user9/.config/user_data
    echo -e "   ${GREEN}[✓]${NC} Level 9 (user9) configured."
}

configure_level10() {
    echo "user=user11" > /etc/db.conf
    echo "password=${PASS[10]}" >> /etc/db.conf
    chmod 644 /etc/db.conf
    echo -e "   ${GREEN}[✓]${NC} Level 10 (user10) configured."
}

configure_level11() {
    echo "user12:${PASS[11]}" > /usr/local/bin/monitor.sh
    chmod 755 /usr/local/bin/monitor.sh
    chown user12:user12 /usr/local/bin/monitor.sh
    echo "user11 ALL=(user12) NOPASSWD: /usr/local/bin/monitor.sh" > /etc/sudoers.d/u11
    chmod 440 /etc/sudoers.d/u11
    echo -e "   ${GREEN}[✓]${NC} Level 11 (user11) configured."
}

configure_level12() {
    echo "user13:${PASS[12]}" > /etc/passwd.bak
    chmod 644 /etc/passwd.bak
    echo -e "   ${GREEN}[✓]${NC} Level 12 (user12) configured."
}

configure_level13() {
    cat > /usr/local/bin/system_rotate.sh <<EOF
#!/bin/bash
echo 'user14:${PASS[13]}'
EOF
    chmod 775 /usr/local/bin/system_rotate.sh
    chown user14:user13 /usr/local/bin/system_rotate.sh
    echo -e "   ${GREEN}[✓]${NC} Level 13 (user13) configured."
}

configure_level14() {
    echo "user14 ALL=(user15) NOPASSWD: /bin/bash" > /etc/sudoers.d/u14
    chmod 440 /etc/sudoers.d/u14
    echo -e "   ${GREEN}[✓]${NC} Level 14 (user14) configured."
}

configure_level15() {
    echo "user15 ALL=(root) NOPASSWD: /bin/cat /root/flag.txt" > /etc/sudoers.d/u15
    chmod 440 /etc/sudoers.d/u15
    echo -e "   ${GREEN}[✓]${NC} Level 15 (user15) configured."
}

# --- Main installation function ---
install_lab() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Starting 15-Level Enterprise PrivEsc Lab Installation (Fixed)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"

    # --- Shell Selection ---
    echo -e "\n${YELLOW}[?] Select the default shell for lab users:${NC}"
    echo "   1) Bash (Standard)"
    echo "   2) Zsh"
    while true; do
        read -rp "   ➜ Choice [1-2]: " shell_choice
        case $shell_choice in
            1)
                USER_SHELL="/bin/bash"
                break
                ;;
            2)
                USER_SHELL="/bin/zsh"
                break
                ;;
            *) echo -e "   ${RED}Invalid input. Please enter 1 or 2.${NC}" ;;
        esac
    done
    echo -e "   ${GREEN}[✓] Shell set to: ${USER_SHELL}${NC}"

    # --- Check prerequisites (only zsh if selected) ---
    check_prerequisites

    # --- Generate passwords and create users ---
    generate_passwords
    create_users

    # --- Configure privilege escalation levels ---
    echo -e "\n${YELLOW}[*] Configuring privilege escalation levels...${NC}"
    configure_level1
    configure_level2
    configure_level3
    configure_level4
    configure_level5
    configure_level6
    configure_level7
    configure_level8
    configure_level9
    configure_level10
    configure_level11
    configure_level12
    configure_level13
    configure_level14
    configure_level15

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
    echo -e "  ${YELLOW}User Shell:${NC} $USER_SHELL"
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
    echo -e "    ${RED}[2]${NC} Cleanup Lab (Remove everything - users, homes, files)"
    echo -e "    ${YELLOW}[3]${NC} Exit"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────${NC}"
    read -rp "  ➜ Enter choice [1-3]: " main_choice

    case $main_choice in
        1)
            install_lab
            ;;
        2)
            cleanup_lab
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





































































































