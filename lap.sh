#!/bin/bash
# ==============================================
# 15-Level Enterprise Linux PrivEsc Lab
# Each user has unique scenario
# RUN AS ROOT ONLY
# ==============================================
set -e
LEVELS=15

# ================= SHELL SELECTION =================
while true; do
  echo "[?] Choose default shell for ALL users:"
  echo "    1) bash"
  echo "    2) zsh"
  read -rp "[>] Enter choice (1 or 2): " SHELL_CHOICE

  if [[ "$SHELL_CHOICE" == "1" ]]; then
    USER_SHELL="/bin/bash"
    break
  elif [[ "$SHELL_CHOICE" == "2" ]]; then
    USER_SHELL="/bin/zsh"
    break
  else
    echo "[!] Invalid choice."
  fi
done
echo "[+] Selected shell: $USER_SHELL"

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
  chmod 700 /home/user$i/progress
  chown -R user$i:user$i /home/user$i
done

echo "[+] Users created with unique passwords"

# ================= LEVEL 1 — HelpDesk Logs =================
mkdir -p /var/log/helpdesk
cat << EOF > /var/log/helpdesk/tickets.log
service_user=user2
service_pass=${PASS[1]}
EOF
chmod 640 /var/log/helpdesk/tickets.log

cat << 'EOF' > /usr/local/bin/log_reader.sh
#!/bin/bash
cat /var/log/helpdesk/tickets.log
EOF
chmod 750 /usr/local/bin/log_reader.sh
chown root:user1 /usr/local/bin/log_reader.sh
echo "user1 ALL=(root) /usr/local/bin/log_reader.sh" > /etc/sudoers.d/u1
chmod 440 /etc/sudoers.d/u1

# ================= LEVEL 2 — Backup Leak =================
mkdir -p /var/backups/app
cat << EOF > /var/backups/app/db_backup.sql
-- internal dump
CREATE USER 'user3'@'localhost' IDENTIFIED BY '${PASS[2]}';
EOF
chmod 644 /var/backups/app/db_backup.sql

# ================= LEVEL 3 — Git Secret Leak =================
mkdir -p /srv/apps/internal/.git
cd /srv/apps/internal
git init
cat << EOF > config.php
<?php
\$USER="user4";
\$PASS="${PASS[3]}";
?>
EOF
git add .
git commit -m "initial commit"
rm config.php

# ================= LEVEL 4 — Writable Cron =================
cat << 'EOF' > /etc/cron.hourly/qa-sync
#!/bin/bash
bash /tmp/qa-tmp.sh
EOF
chmod 755 /etc/cron.hourly/qa-sync
echo "echo 'user5:${PASS[4]}' > /tmp/qa-tmp.sh" > /tmp/qa-tmp.sh
chmod 700 /tmp/qa-tmp.sh

# ================= LEVEL 5 — Custom SUID Binary =================
cat << 'EOF' > /opt/ops/healthcheck.c
#include <unistd.h>
int main(){ setuid(0); system("/bin/sh"); return 0; }
EOF
gcc /opt/ops/healthcheck.c -o /opt/ops/healthcheck
chmod 4755 /opt/ops/healthcheck

# ================= LEVEL 6 — Sudo Vim =================
echo "user6 ALL=(root) /usr/bin/vim /etc/sysconfig/app.env" > /etc/sudoers.d/u6
chmod 440 /etc/sudoers.d/u6
cat << EOF > /etc/sysconfig/app.env
NEXT_USER=user7
PASS=${PASS[6]}
EOF
chmod 600 /etc/sysconfig/app.env

# ================= LEVEL 7 — Capabilities =================
cp /usr/sbin/tcpdump /opt/tcpdump_cap
setcap cap_net_raw,cap_net_admin+ep /opt/tcpdump_cap

# ================= LEVEL 8 — Systemd override =================
mkdir -p /etc/systemd/system/app.service.d
cat << EOF > /etc/systemd/system/app.service.d/override.conf
[Service]
ExecStart=
ExecStart=/bin/bash -c 'cp /bin/bash /tmp/rootbash; chmod 4755 /tmp/rootbash'
EOF
echo "user8 ALL=(root) systemctl restart app" > /etc/sudoers.d/u8
chmod 440 /etc/sudoers.d/u8

# ================= LEVEL 9 — Rsync misconfig =================
mkdir -p /etc/cron.d/
echo "* * * * * user9 rsync -a /var/backups/ /etc/backup/" > /etc/cron.d/backup-sync
chmod 644 /etc/cron.d/backup-sync

# ================= LEVEL 10 — MySQL Config Leak =================
cat << EOF > /etc/mysql/my.cnf
user11=${PASS[10]}
EOF
chmod 644 /etc/mysql/my.cnf

# ================= LEVEL 11 — Docker Sock =================
usermod -aG docker user11

# ================= LEVEL 12 — NFS no_root_squash =================
mkdir -p /mnt/internal_share
chmod 777 /mnt/internal_share

# ================= LEVEL 13 — Logrotate abuse =================
cat << EOF > /etc/logrotate.d/security
/var/log/auth.log {
    weekly
    postrotate
        cp /bin/bash /tmp/logbash
        chmod 4755 /tmp/logbash
    endscript
}
EOF

# ================= LEVEL 14 — Senior Admin sudo env =================
echo "user14 ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/u14
chmod 440 /etc/sudoers.d/u14

# ================= LEVEL 15 — ROOT =================
echo "FLAG{ROOT_REACHED_VIA_ENTERPRISE_CHAIN}" > /root/enterprise.flag
chmod 400 /root/enterprise.flag

echo "[+] LAB READY — 15 Users, 15 Scenarios"
echo "[+] Entry point: user1"
