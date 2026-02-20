#!/bin/bash
# =====================================================
# 15-Level Enterprise Linux PrivEsc Lab (REALISTIC)
# Author: Red Team Training Lab
# RUN AS ROOT ONLY
# =====================================================

set -Eeuo pipefail
LEVELS=15

[[ $EUID -ne 0 ]] && { echo "[!] Run as root"; exit 1; }

# ================= SHELL SELECTION =================
while true; do
  echo "[?] Choose default shell for ALL users:"
  echo "    1) bash"
  echo "    2) zsh"
  read -rp "[>] Enter choice (1 or 2): " SHELL_CHOICE
  case "$SHELL_CHOICE" in
    1) USER_SHELL="/bin/bash"; break ;;
    2) USER_SHELL="/bin/zsh"; break ;;
    *) echo "[!] Invalid choice" ;;
  esac
done

echo "[+] Shell selected: $USER_SHELL"

# ================= USERS & PASSWORDS =================
PASS=(
"X9!kR@2#M7QZt8Lp"
"Q@Z8!kM2R7t9#Lp"
"R7#Q!9Zk2@Mt8Lp"
"9@k!RZ2Q7M#8tLp"
"Z2R!Q@k7#M9t8Lp"
"M9#R@Q!Zk2t7Lp8"
"Q7@Zk!M2R#9tLp8"
"R@9Z!k2Q7M#tLp8"
"Zk2R!@Q7#M9tLp8"
"Q@k7Z!R2#M9tLp8"
"RZ!Q@k2#M7t9Lp8"
"kQ!Z@R2#M7t9Lp8"
"Z!kQ@R2#M7t9Lp8"
"QZ!k@R2#M7t9Lp8"
"FINAL_ROOT_LOCK"
)

for i in $(seq 1 $LEVELS); do
  useradd -m -s "$USER_SHELL" user$i
  echo "user$i:${PASS[$((i-1))]}" | chpasswd
  chmod 700 /home/user$i
  mkdir -p /home/user$i/progress
  chown -R user$i:user$i /home/user$i
done

# ================= LEVEL 1 — HelpDesk Logs =================
mkdir -p /var/log/helpdesk
cat > /var/log/helpdesk/tickets.log <<EOF
service_user=user2
service_pass=${PASS[1]}
EOF
chmod 640 /var/log/helpdesk/tickets.log

cat > /usr/local/bin/log_reader.sh <<'EOF'
#!/bin/bash
cat /var/log/helpdesk/tickets.log
EOF
chmod 750 /usr/local/bin/log_reader.sh
chown root:user1 /usr/local/bin/log_reader.sh

echo "user1 ALL=(root) NOPASSWD: /usr/local/bin/log_reader.sh" \
  > /etc/sudoers.d/u1
chmod 440 /etc/sudoers.d/u1

# ================= LEVEL 2 — Backup Leak =================
mkdir -p /var/backups/app
cat > /var/backups/app/db_backup.sql <<EOF
CREATE USER 'user3'@'localhost' IDENTIFIED BY '${PASS[2]}';
EOF
chmod 644 /var/backups/app/db_backup.sql

# ================= LEVEL 3 — Git Secret Leak =================
mkdir -p /srv/apps/internal
cd /srv/apps/internal
git init -q
git config user.email "dev@corp.local"
git config user.name "internal-dev"

cat > config.php <<EOF
<?php
\$USER="user4";
\$PASS="${PASS[3]}";
?>
EOF
git add config.php
git commit -m "initial commit" -q
rm -f config.php

# ================= LEVEL 4 — Writable Cron =================
cat > /etc/cron.d/qa-sync <<'EOF'
* * * * * root bash /tmp/qa-tmp.sh
EOF
chmod 644 /etc/cron.d/qa-sync

echo "echo 'user5:${PASS[4]}' | chpasswd" > /tmp/qa-tmp.sh
chmod 777 /tmp/qa-tmp.sh   # intentional misconfig

# ================= LEVEL 5 — SUID Binary =================
mkdir -p /opt/ops
cat > /opt/ops/healthcheck.c <<'EOF'
#include <unistd.h>
int main(){ setuid(0); execl("/bin/sh","sh","-p",NULL); }
EOF
gcc /opt/ops/healthcheck.c -o /opt/ops/healthcheck
chmod 4755 /opt/ops/healthcheck

# ================= LEVEL 6 — Sudo Vim =================
echo "user6 ALL=(root) NOPASSWD: /usr/bin/vim /etc/sysconfig/app.env" \
  > /etc/sudoers.d/u6
chmod 440 /etc/sudoers.d/u6

mkdir -p /etc/sysconfig
cat > /etc/sysconfig/app.env <<EOF
NEXT_USER=user7
PASS=${PASS[6]}
EOF
chmod 600 /etc/sysconfig/app.env

# ================= LEVEL 7 — Capabilities =================
cp /usr/sbin/tcpdump /opt/tcpdump_cap
setcap cap_net_raw,cap_net_admin+ep /opt/tcpdump_cap

# ================= LEVEL 8 — systemd override =================
cat > /etc/systemd/system/app.service <<'EOF'
[Service]
ExecStart=/bin/true
EOF

mkdir -p /etc/systemd/system/app.service.d
cat > /etc/systemd/system/app.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/bin/bash -c 'cp /bin/bash /tmp/rootbash; chmod 4755 /tmp/rootbash'
EOF

echo "user8 ALL=(root) NOPASSWD: systemctl restart app" \
  > /etc/sudoers.d/u8
chmod 440 /etc/sudoers.d/u8

# ================= LEVEL 9 — Rsync Cron =================
mkdir -p /etc/backup
cat > /etc/cron.d/backup-sync <<'EOF'
* * * * * user9 rsync -a /var/backups/ /etc/backup/
EOF
chmod 644 /etc/cron.d/backup-sync

# ================= LEVEL 10 — MySQL Leak =================
mkdir -p /etc/mysql
echo "user11=${PASS[10]}" > /etc/mysql/my.cnf
chmod 644 /etc/mysql/my.cnf

# ================= LEVEL 11 — Docker =================
usermod -aG docker user11 || true

# ================= LEVEL 12 — NFS =================
mkdir -p /mnt/internal_share
chmod 777 /mnt/internal_share

# ================= LEVEL 13 — Logrotate =================
cat > /etc/logrotate.d/security <<'EOF'
/var/log/auth.log {
  weekly
  postrotate
    cp /bin/bash /tmp/logbash
    chmod 4755 /tmp/logbash
  endscript
}
EOF

# ================= LEVEL 14 — Full sudo =================
echo "user14 ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/u14
chmod 440 /etc/sudoers.d/u14

# ================= LEVEL 15 — ROOT FLAG =================
echo "FLAG{ROOT_REACHED_VIA_ENTERPRISE_CHAIN}" > /root/enterprise.flag
chmod 400 /root/enterprise.flag

echo "[+] LAB READY — ENTERPRISE PRIVESc ENVIRONMENT"
echo "[+] Entry point: user1"




































