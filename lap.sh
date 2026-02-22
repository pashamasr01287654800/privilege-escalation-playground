#!/bin/bash
# =====================================================
# 15-Level Enterprise Linux PrivEsc Lab - MAIN SCRIPT
# Installation and Cleanup in One Script
# =====================================================

set -Eeuo pipefail
[[ $EUID -ne 0 ]] && { echo "[!] Run as root"; exit 1; }

# ================= COLOR CODES =================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ================= MAIN MENU =================
while true; do
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🏢 15-Level Enterprise Linux PrivEsc Lab${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "Choose an option:"
    echo -e "  ${GREEN}[1]${NC} Install Lab - Create all users and levels"
    echo -e "  ${RED}[2]${NC} Cleanup Lab - Remove everything"
    echo -e "  ${YELLOW}[3]${NC} Exit"
    echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"
    
    read -rp "➜ Enter choice (1, 2, or 3): " main_choice
    
    case $main_choice in
        1)
            # ================ INSTALLATION =================
            echo -e "\n${GREEN}▶ Starting Lab Installation${NC}"
            
            # ================= SHELL SELECTION =================
            echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}⚠️  SHELL SELECTION IS REQUIRED ⚠️${NC}"
            echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
            echo -e "Choose the default shell for all users:"
            echo -e "  ${GREEN}[1]${NC} Bash (/bin/bash) - Standard Linux shell"
            echo -e "  ${GREEN}[2]${NC} Zsh (/bin/zsh) - Enhanced shell"
            echo -e "${BLUE}───────────────────────────────────────────────────────${NC}"

            while true; do
                read -rp "➜ Enter choice (1 or 2): " shell_choice
                
                case $shell_choice in
                    1)
                        USER_SHELL="/bin/bash"
                        echo -e "${GREEN}✓${NC} Selected: Bash shell"
                        break
                        ;;
                    2)
                        # Check if zsh is installed
                        if [ -f /bin/zsh ] || [ -f /usr/bin/zsh ] || command -v zsh &>/dev/null; then
                            USER_SHELL="/bin/zsh"
                            echo -e "${GREEN}✓${NC} Selected: Zsh shell"
                            break
                        else
                            echo -e "${RED}✗ ERROR: Zsh is not installed on this system!${NC}"
                            echo -e "${YELLOW}Please install zsh first or choose Bash (option 1).${NC}\n"
                            # Continue the loop - ask again
                        fi
                        ;;
                    *)
                        echo -e "${RED}✗ Invalid choice! Please enter 1 or 2 only.${NC}\n"
                        ;;
                esac
            done

            echo -e "${GREEN}✓${NC} Shell set to: $USER_SHELL"
            
            # ================= INSTALLATION VARIABLES =================
            BASE_UID=1001
            LEVELS=15

            # ================= PASSWORDS =================
            cat <<EOF >/root/passwords.txt
user1 : X9!kR@2#M7QZt8Lp
user2 : Q@Z8!kM2R7t9#Lp
user3 : R7#Q!9Zk2@Mt8Lp
user4 : 9@k!RZ2Q7M#8tLp
user5 : Z2R!Q@k7#M9t8Lp
user6 : M9#R@Q!Zk2t7Lp8
user7 : Q7@Zk!M2R#9tLp8
user8 : R@9Z!k2Q7M#tLp8
user9 : Zk2R!@Q7#M9tLp8
user10: Q@k7Z!R2#M9tLp8
user11: RZ!Q@k2#M7t9Lp8
user12: kQ!Z@R2#M7t9Lp8
user13: Z!kQ@R2#M7t9Lp8
user14: QZ!k@R2#M7t9Lp8
user15: CHAIN_COMPLETE_ACCESS_ROOT
EOF
            chmod 600 /root/passwords.txt

            PASS=( $(awk '{print $3}' /root/passwords.txt) )

            # ================= USERS =================
            echo -e "\n${GREEN}[+] Creating users...${NC}"
            for i in $(seq 1 $LEVELS); do
              useradd -m -u $((BASE_UID+i)) -s "$USER_SHELL" user$i
              echo "user$i:${PASS[$((i-1))]}" | chpasswd
              chmod 700 /home/user$i
              echo -e "  ${GREEN}✓${NC} Created user$i (UID: $((BASE_UID+i))) with shell: $USER_SHELL"
            done

            # ================= LEVEL 1 → 2 =================
            echo -e "\n${GREEN}[+] Setting up Level 1 → 2${NC}"
            mkdir -p /var/log/helpdesk
            cat >/var/log/helpdesk/tickets.log <<EOF
[2024-01-15] Ticket #2341: Backup service failing on server app02
[2024-01-15] Ticket #2342: User reports slow login - UID: 1003
[2024-01-16] Ticket #2345: Credentials backup - user2:${PASS[1]}
[2024-01-16] Ticket #2346: Permission issue on /usr/local/bin/script
EOF
            chmod 640 /var/log/helpdesk/tickets.log
            chown root:user1 /var/log/helpdesk/tickets.log

            cat >/usr/local/bin/log_reader.py <<'EOF'
#!/usr/bin/python3
import os
import sys

def read_logs():
    try:
        with open('/var/log/helpdesk/tickets.log', 'r') as f:
            print(f.read())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("This script must be run as root")
        sys.exit(1)
    read_logs()
EOF
            chmod 750 /usr/local/bin/log_reader.py
            chown root:user1 /usr/local/bin/log_reader.py

            echo "user1 ALL=(root) NOPASSWD: /usr/local/bin/log_reader.py" >/etc/sudoers.d/u1
            chmod 440 /etc/sudoers.d/u1

            # ================= LEVEL 2 → 3 =================
            echo -e "${GREEN}[+] Setting up Level 2 → 3${NC}"
            mkdir -p /var/backups/app
            cat >/var/backups/app/creds.txt <<EOF
# Application credentials backup - DO NOT COMMIT
DB_USER=app_service
DB_PASS=${PASS[2]}
API_KEY=sk_live_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)
EOF
            chmod 640 /var/backups/app/creds.txt
            chown root:user2 /var/backups/app/creds.txt

            # ================= LEVEL 3 → 4 =================
            echo -e "${GREEN}[+] Setting up Level 3 → 4${NC}"
            mkdir -p /srv/dev/app
            cd /srv/dev/app
            git init -q
            git config user.email "dev@corp.local"
            git config user.name "Developer"
            cat >config.env <<EOF
# Production configuration
APP_ENV=production
APP_DEBUG=false
DB_HOST=localhost
DB_USER=app_user
DB_PASS=${PASS[3]}
REDIS_HOST=redis.internal
EOF
            git add config.env
            git commit -m "Initial commit with production config" -q
            git checkout -b feature/update-config -q
            echo "# TESTING ONLY - DO NOT USE IN PROD" >test_config.env
            git add test_config.env
            git commit -m "Add test config" -q
            git checkout main -q
            rm -f config.env test_config.env
            chown -R root:user3 /srv/dev
            chmod 750 /srv/dev
            find /srv/dev -type d -exec chmod 750 {} \;
            find /srv/dev -type f -exec chmod 640 {} \;

            # ================= LEVEL 4 → 5 =================
            echo -e "${GREEN}[+] Setting up Level 4 → 5${NC}"
            mkdir -p /opt/deployment/scripts

            cat >/opt/deployment/scripts/deploy_app.sh <<'EOF'
#!/bin/bash
# Deployment script - handles application deployment
# Usage: ./deploy_app.sh <environment>

DEPLOY_DIR="/opt/deployment"
LOG_FILE="$DEPLOY_DIR/logs/deploy.log"
CONFIG_DIR="$DEPLOY_DIR/config"

check_permissions() {
    if [ "$EUID" -ne 1005 ]; then
        echo "[!] This script must be run as user5 (UID: 1005)"
        exit 1
    fi
}

deploy_app() {
    local env=$1
    echo "[+] Deploying to $env environment..."
    
    if [ "$env" == "production" ]; then
        echo "Production deployment key: $(cat $CONFIG_DIR/prod.key 2>/dev/null || echo 'NONE')"
        echo "[+] Production deployment complete"
        echo "[+] Switching to deployment user..."
        exec /bin/bash
    else
        echo "[+] Test deployment complete"
    fi
}

main() {
    check_permissions
    mkdir -p "$DEPLOY_DIR/logs"
    deploy_app "${1:-development}"
}

main "$@"
EOF

            mkdir -p /opt/deployment/config
            echo "PROD_DEPLOY_KEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)" >/opt/deployment/config/prod.key
            echo "user5:${PASS[4]}" >>/opt/deployment/config/prod.key

            chown -R user5:user5 /opt/deployment/config
            chmod 750 /opt/deployment/config
            chmod 640 /opt/deployment/config/prod.key
            chown user5:user4 /opt/deployment/scripts/deploy_app.sh
            chmod 750 /opt/deployment/scripts/deploy_app.sh

            cat >/usr/local/bin/deploy <<'EOF'
#!/bin/bash
/opt/deployment/scripts/deploy_app.sh "$@"
EOF
            chmod 755 /usr/local/bin/deploy

            echo "user4 ALL=(user5) NOPASSWD: /usr/local/bin/deploy" >/etc/sudoers.d/u4
            chmod 440 /etc/sudoers.d/u4

            # ================= LEVEL 5 → 6 =================
            echo -e "${GREEN}[+] Setting up Level 5 → 6${NC}"
            cat >/opt/tools/pivot.c <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    setuid(1006);
    setgid(1006);
    printf("[+] Pivoting to user6 (UID: 1006)\n");
    execl("/bin/bash", "bash", "-p", NULL);
    return 1;
}
EOF

            mkdir -p /opt/tools
            gcc /opt/tools/pivot.c -o /opt/tools/pivot 2>/dev/null || {
                echo "Warning: gcc not found, creating binary alternative"
                cp /bin/bash /opt/tools/pivot
                chmod 755 /opt/tools/pivot
            }
            chmod 4755 /opt/tools/pivot
            chown root:root /opt/tools/pivot

            # ================= LEVEL 6 → 7 =================
            echo -e "${GREEN}[+] Setting up Level 6 → 7${NC}"
            mkdir -p /etc/app/config
            cat >/etc/app/config/app.conf <<EOF
# Application Configuration
APP_NAME=EnterprisePortal
APP_ENV=production
APP_KEY=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
DB_PASSWORD=${PASS[6]}
CACHE_DRIVER=redis
SESSION_DRIVER=cookie
EOF
            chmod 640 /etc/app/config/app.conf
            chown root:user6 /etc/app/config/app.conf
            echo "user6 ALL=(root) NOPASSWD: /usr/bin/less /etc/app/config/app.conf" >/etc/sudoers.d/u6
            chmod 440 /etc/sudoers.d/u6

            # ================= LEVEL 7 → 8 =================
            echo -e "${GREEN}[+] Setting up Level 7 → 8${NC}"
            cp /usr/bin/python3 /usr/local/bin/python3-custom
            setcap cap_setuid+ep /usr/local/bin/python3-custom

            # ================= LEVEL 8 → 9 =================
            echo -e "${GREEN}[+] Setting up Level 8 → 9${NC}"
            mkdir -p /opt/scripts/maintenance
            cat >/opt/scripts/maintenance/backup.sh <<'EOF'
#!/bin/bash
echo "[+] Running system backup..."
echo "user9:${PASS[8]}" > /tmp/backup_creds.txt
sleep 2
echo "[+] Backup complete"
/bin/bash
EOF
            chmod 755 /opt/scripts/maintenance/backup.sh
            chown user9:user8 /opt/scripts/maintenance/backup.sh

            # ================= LEVEL 9 → 10 =================
            echo -e "${GREEN}[+] Setting up Level 9 → 10${NC}"
            mkdir -p /home/user9/.config /home/user10/.local
            cat >/home/user9/.config/user_data <<EOF
[user]
name=user9
next_level=user10
password=${PASS[9]}
EOF
            chmod 600 /home/user9/.config/user_data
            chown user9:user9 /home/user9/.config/user_data

            # ================= LEVEL 10 → 11 =================
            echo -e "${GREEN}[+] Setting up Level 10 → 11${NC}"
            mkdir -p /etc/db/credentials
            cat >/etc/db/credentials/connection.ini <<EOF
[database]
host=db01.internal
port=5432
name=enterprise_prod
user=app_user
password=${PASS[10]}
ssl_mode=require
EOF
            chmod 640 /etc/db/credentials/connection.ini
            chown root:user10 /etc/db/credentials/connection.ini

            # ================= LEVEL 11 → 12 =================
            echo -e "${GREEN}[+] Setting up Level 11 → 12${NC}"
            cat >/usr/local/bin/monitor.sh <<'EOF'
#!/bin/bash
echo "=== System Status ==="
date
uptime
df -h
echo "=== User Info ==="
id
echo "=== Next Level ==="
echo "user12:${PASS[11]}"
exec /bin/bash
EOF
            chmod 755 /usr/local/bin/monitor.sh
            chown root:user11 /usr/local/bin/monitor.sh
            echo "user11 ALL=(root) NOPASSWD: /usr/local/bin/monitor.sh" >/etc/sudoers.d/u11
            echo "Defaults:user11 env_keep += \"PATH\"" >>/etc/sudoers.d/u11
            chmod 440 /etc/sudoers.d/u11

            # ================= LEVEL 12 → 13 =================
            echo -e "${GREEN}[+] Setting up Level 12 → 13${NC}"
            mkdir -p /mnt/nfs_share
            chmod 777 /mnt/nfs_share
            cat >/mnt/nfs_share/note.txt <<EOF
User13 credentials are in /etc/passwd.bak
EOF
            chmod 644 /mnt/nfs_share/note.txt
            cp /etc/passwd /etc/passwd.bak
            echo "# user13:${PASS[12]}" >>/etc/passwd.bak
            chmod 644 /etc/passwd.bak

            # ================= LEVEL 13 → 14 =================
            echo -e "${GREEN}[+] Setting up Level 13 → 14${NC}"
            cat >/usr/local/bin/system_rotate.sh <<'EOF'
#!/bin/bash
if [ "$EUID" -ne 1014 ]; then
    echo "This script must be run as user14"
    exit 1
fi
echo "[+] Log rotation complete"
exec /bin/bash
EOF
            chmod 755 /usr/local/bin/system_rotate.sh
            chown user14:user13 /usr/local/bin/system_rotate.sh

            # ================= LEVEL 14 → 15 =================
            echo -e "${GREEN}[+] Setting up Level 14 → 15${NC}"
            echo "user14 ALL=(user15) NOPASSWD: /bin/bash" >/etc/sudoers.d/u14
            chmod 440 /etc/sudoers.d/u14

            # ================= FINAL FLAG =================
            echo -e "${GREEN}[+] Creating final flag${NC}"
            cat >/root/flag.txt <<EOF
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   🏆 ENTERPRISE PRIVESC CHAIN COMPLETED 🏆              ║
║                                                          ║
║   FLAG{PRIVESC_CHAIN_15_LEVELS_MASTER}                  ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
            chmod 400 /root/flag.txt

            # ================= VALIDATION =================
            echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}✅ LAB INSTALLED SUCCESSFULLY${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}Entry point:${NC} user1"
            echo -e "${YELLOW}Password:${NC} ${PASS[0]}"
            echo -e "${YELLOW}Shell used:${NC} $USER_SHELL"
            echo -e "${YELLOW}Final flag:${NC} /root/flag.txt"
            echo -e "\n${RED}NOTE:${NC} All passwords in /root/passwords.txt"
            echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
            
            # Exit installation loop
            break
            ;;
            
        2)
            # ================ CLEANUP =================
            echo -e "\n${RED}▶ Starting Lab Cleanup${NC}"
            
            # ================= CONFIRMATION =================
            while true; do
                echo -e "\n${YELLOW}Are you ABSOLUTELY SURE you want to remove everything?${NC}"
                echo -e "  ${GREEN}[y]${NC} Yes, clean everything"
                echo -e "  ${RED}[n]${NC} No, go back"
                read -rp "➜ Enter choice (y/n): " confirm
                
                case $confirm in
                    [Yy]*)
                        echo -e "\n${RED}Starting cleanup...${NC}\n"
                        break
                        ;;
                    [Nn]*)
                        echo -e "${GREEN}Cleanup aborted. Returning to menu.${NC}"
                        continue 2  # Go back to main menu
                        ;;
                    *)
                        echo -e "${RED}✗ Invalid choice! Please enter y or n.${NC}"
                        ;;
                esac
            done

            # ================= REMOVE SUDOERS =================
            echo -e "${BLUE}[1/8]${NC} Removing sudoers configurations..."
            for i in {1..15}; do
                [ -f "/etc/sudoers.d/u$i" ] && rm -f "/etc/sudoers.d/u$i" && echo -e "  ${GREEN}✓${NC} Removed /etc/sudoers.d/u$i"
            done

            # ================= REMOVE LAB FILES =================
            echo -e "${BLUE}[2/8]${NC} Removing lab files and directories..."
            LAB_DIRS=(
                "/var/log/helpdesk" "/var/backups/app" "/srv/dev" "/opt/deployment"
                "/opt/tools" "/opt/qa" "/opt/services" "/opt/scripts" "/etc/app"
                "/etc/db" "/usr/local/bin/log_reader.py" "/usr/local/bin/deploy"
                "/usr/local/bin/python3-custom" "/usr/local/bin/monitor.sh"
                "/usr/local/bin/system_rotate.sh" "/opt/pivot" "/opt/pycap"
                "/mnt/nfs_share" "/mnt/share" "/home/user9/.config"
                "/etc/passwd.bak" "/root/passwords.txt" "/root/flag.txt"
            )
            
            for dir in "${LAB_DIRS[@]}"; do
                [ -e "$dir" ] && rm -rf "$dir" && echo -e "  ${GREEN}✓${NC} Removed $dir"
            done

            # ================= REMOVE USERS =================
            echo -e "${BLUE}[3/8]${NC} Removing lab users..."
            for i in {15..1}; do
                if id "user$i" &>/dev/null; then
                    pkill -u "user$i" 2>/dev/null || true
                    userdel -r "user$i" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Removed user$i"
                fi
            done

            # ================= CLEANUP HOME DIRS =================
            echo -e "${BLUE}[4/8]${NC} Cleaning up home directories..."
            for i in {1..15}; do
                [ -d "/home/user$i" ] && rm -rf "/home/user$i" && echo -e "  ${GREEN}✓${NC} Removed /home/user$i"
            done

            # ================= CLEANUP TEMP FILES =================
            echo -e "${BLUE}[5/8]${NC} Cleaning up temporary files..."
            [ -f "/tmp/backup_creds.txt" ] && rm -f "/tmp/backup_creds.txt" && echo -e "  ${GREEN}✓${NC} Removed /tmp/backup_creds.txt"

            # ================= REMOVE CAPABILITIES =================
            echo -e "${BLUE}[6/8]${NC} Removing file capabilities..."
            [ -f "/usr/local/bin/python3-custom" ] && setcap -r "/usr/local/bin/python3-custom" 2>/dev/null || true

            # ================= KILL PROCESSES =================
            echo -e "${BLUE}[7/8]${NC} Killing remaining user processes..."
            for i in {1..15}; do
                pgrep -u "user$i" &>/dev/null && pkill -9 -u "user$i" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Killed processes for user$i"
            done

            # ================= VERIFY =================
            echo -e "${BLUE}[8/8]${NC} Verifying cleanup..."
            REMAINING=0
            for i in {1..15}; do
                id "user$i" &>/dev/null && REMAINING=$((REMAINING + 1))
            done
            
            if [ $REMAINING -eq 0 ]; then
                echo -e "  ${GREEN}✓${NC} All users removed successfully"
                echo -e "\n${GREEN}✅ CLEANUP COMPLETED SUCCESSFULLY${NC}"
            else
                echo -e "\n${YELLOW}⚠️  CLEANUP PARTIALLY COMPLETED${NC}"
            fi
            
            echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
            
            # Ask if user wants to return to menu or exit
            echo -e "\n${YELLOW}Press Enter to return to menu or 'q' to quit:${NC}"
            read -rp "➜ " return_choice
            [[ "$return_choice" == "q" ]] && exit 0
            # Continue to main menu loop
            ;;
            
        3)
            echo -e "\n${GREEN}Exiting. Goodbye!${NC}"
            exit 0
            ;;
            
        *)
            echo -e "\n${RED}✗ Invalid choice! Please enter 1, 2, or 3.${NC}"
            ;;
    esac
done
