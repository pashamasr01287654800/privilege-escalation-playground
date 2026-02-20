#!/bin/bash
# =====================================================
# 15-Level Enterprise Linux PrivEsc Lab (STRICT CHAIN)
# Rule: NO DIRECT ROOT UNTIL LEVEL 15
# =====================================================

set -Eeuo pipefail
[[ $EUID -ne 0 ]] && { echo "[!] Run as root"; exit 1; }

LEVELS=15
BASE_UID=1001

# ================= SHELL SELECTION =================
while true; do
  echo "[?] Choose shell:"
  echo "1) bash"
  echo "2) zsh"
  read -rp "> " c
  [[ "$c" == "1" ]] && USER_SHELL="/bin/bash" && break
  [[ "$c" == "2" ]] && USER_SHELL="/bin/zsh" && break
done

# ================= USERS =================
PASS=(
"X9!kR@2#M7QZt8Lp" "Q@Z8!kM2R7t9#Lp" "R7#Q!9Zk2@Mt8Lp"
"9@k!RZ2Q7M#8tLp" "Z2R!Q@k7#M9t8Lp" "M9#R@Q!Zk2t7Lp8"
"Q7@Zk!M2R#9tLp8" "R@9Z!k2Q7M#tLp8" "Zk2R!@Q7#M9tLp8"
"Q@k7Z!R2#M9tLp8" "RZ!Q@k2#M7t9Lp8" "kQ!Z@R2#M7t9Lp8"
"Z!kQ@R2#M7t9Lp8" "QZ!k@R2#M7t9Lp8" "FINAL_ROOT"
)

for i in $(seq 1 $LEVELS); do
  useradd -m -u $((BASE_UID+i)) -s "$USER_SHELL" user$i
  echo "user$i:${PASS[$((i-1))]}" | chpasswd
  chmod 700 /home/user$i
done

# ================= LEVEL 1 → 2 (Log Leak) =================
mkdir -p /var/log/helpdesk
echo -e "u=user2\np=${PASS[1]}" > /var/log/helpdesk/tickets.log
chmod 640 /var/log/helpdesk/tickets.log

cat > /usr/local/bin/read_logs.sh <<'EOF'
#!/bin/bash
cat /var/log/helpdesk/tickets.log
EOF
chmod 750 /usr/local/bin/read_logs.sh
chown root:user1 /usr/local/bin/read_logs.sh
echo "user1 ALL=(root) NOPASSWD: /usr/local/bin/read_logs.sh" > /etc/sudoers.d/u1
chmod 440 /etc/sudoers.d/u1

# ================= LEVEL 2 → 3 (Backup Leak) =================
mkdir -p /var/backups/app
echo "user3:${PASS[2]}" > /var/backups/app/creds.txt
chmod 644 /var/backups/app/creds.txt

# ================= LEVEL 3 → 4 (Git History) =================
mkdir -p /srv/dev/app && cd /srv/dev/app
git init -q
git config user.email dev@corp.local
git config user.name dev
echo "USER=user4 PASS=${PASS[3]}" > config.env
git add config.env && git commit -m init -q
rm -f config.env

# ================= LEVEL 4 → 5 (Cron Pivot) =================
echo "* * * * * root su user5 -c /home/user5/next.sh" > /etc/cron.d/qa
chmod 644 /etc/cron.d/qa
echo "#!/bin/bash" > /home/user5/next.sh
chmod 755 /home/user5/next.sh

# ================= LEVEL 5 → 6 (SUID user binary) =================
mkdir -p /opt/tools
cat > /opt/tools/pivot.c <<'EOF'
#include <unistd.h>
int main(){ setuid(1007); execl("/bin/bash","bash",NULL); }
EOF
gcc /opt/tools/pivot.c -o /opt/tools/pivot
chmod 4755 /opt/tools/pivot

# ================= LEVEL 6 → 7 (sudo editor) =================
mkdir -p /etc/app
echo "NEXT=user7 PASS=${PASS[6]}" > /etc/app/env
chmod 640 /etc/app/env
echo "user6 ALL=(root) NOPASSWD: /usr/bin/vim /etc/app/env" > /etc/sudoers.d/u6
chmod 440 /etc/sudoers.d/u6

# ================= LEVEL 7 → 8 (Capabilities) =================
cp /usr/bin/python3 /opt/pycap
setcap cap_setuid+ep /opt/pycap

# ================= LEVEL 8 → 9 (systemd user pivot) =================
cat > /etc/systemd/system/pivot.service <<EOF
[Service]
ExecStart=/bin/su user9 -c /bin/bash
EOF
echo "user8 ALL=(root) NOPASSWD: systemctl restart pivot" > /etc/sudoers.d/u8
chmod 440 /etc/sudoers.d/u8

# ================= LEVEL 9 → 10 (rsync cron) =================
mkdir -p /etc/backup
echo "* * * * * user9 rsync -a /home/user9/share/ /home/user10/" > /etc/cron.d/sync
chmod 644 /etc/cron.d/sync
mkdir -p /home/user9/share /home/user10

# ================= LEVEL 10 → 11 (config leak) =================
mkdir -p /etc/db
echo "user11:${PASS[10]}" > /etc/db/app.conf
chmod 644 /etc/db/app.conf

# ================= LEVEL 11 → 12 (PATH hijack) =================
cat > /usr/local/bin/syscheck.sh <<'EOF'
#!/bin/bash
date
su user12 -c /bin/bash
EOF
chmod 755 /usr/local/bin/syscheck.sh
echo "Defaults:user11 !secure_path" > /etc/sudoers.d/u11
echo "user11 ALL=(root) NOPASSWD: /usr/local/bin/syscheck.sh" >> /etc/sudoers.d/u11
chmod 440 /etc/sudoers.d/u11

# ================= LEVEL 12 → 13 (NFS-like share) =================
mkdir -p /mnt/share
chmod 777 /mnt/share
ln -s /mnt/share /home/user12/share

# ================= LEVEL 13 → 14 (logrotate pivot) =================
cat > /etc/logrotate.d/app <<'EOF'
/var/log/syslog {
 weekly
 postrotate
  su user14 -c /bin/bash
 endscript
}
EOF

# ================= LEVEL 14 → 15 (FINAL SUDO) =================
echo "user14 ALL=(root) NOPASSWD: /bin/su user15" > /etc/sudoers.d/u14
chmod 440 /etc/sudoers.d/u14

# ================= LEVEL 15 =================
echo "FLAG{ENTERPRISE_CHAIN_COMPLETE}" > /root/flag.txt
chmod 400 /root/flag.txt

echo "[+] LAB READY — STRICT CHAIN, NO ROOT SKIPS"
echo "[+] Entry: user1"



