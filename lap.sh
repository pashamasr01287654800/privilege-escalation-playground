#!/bin/bash
# 15-Level Enterprise Realistic Linux PrivEsc Lab
# ENTRY: user1
# FLOW: Misconfig → Data Leak → Legit su
# RUN AS ROOT ONLY

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
    echo "[!] Invalid choice. You MUST enter 1 or 2."
  fi
done

echo "[+] Selected shell: $USER_SHELL"
echo

# ================= USER CREATION =================
echo "[+] Creating users..."
for i in $(seq 1 $LEVELS); do
  useradd -m -s "$USER_SHELL" user$i
done

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

echo "[+] Setting passwords..."
for i in $(seq 1 $LEVELS); do
  echo "user$i:${PASS[$((i-1))]}" | chpasswd
  chmod 700 /home/user$i
done

# ================= DATA LEAK SOURCES =================

mkdir -p /var/log/app /var/backups /opt/app /opt/tools
chmod 777 /opt/tools

# ---------------- L1 ----------------
cat << EOF > /var/log/app/app.log
[DEBUG] service_user=user2
[DEBUG] service_pass=${PASS[1]}
EOF

cat << 'EOF' > /usr/local/bin/log_parser.sh
#!/bin/bash
awk '{print $0}' /var/log/app/app.log
EOF
chmod 750 /usr/local/bin/log_parser.sh
chown root:user1 /usr/local/bin/log_parser.sh

cat << EOF > /etc/sudoers.d/u1
user1 ALL=(root) /usr/local/bin/log_parser.sh
EOF
chmod 440 /etc/sudoers.d/u1

# ---------------- L2 ----------------
cat << EOF > /var/backups/user2.conf.bak
db_user=user3
db_pass=${PASS[2]}
EOF
chown user2:user2 /var/backups/user2.conf.bak
chmod 640 /var/backups/user2.conf.bak

# ---------------- L3 ----------------
cp /usr/bin/env /opt/env_reader
chmod 4755 /opt/env_reader
chown root:root /opt/env_reader

cat << EOF > /opt/app/.env
NEXT_USER=user4
PASSWORD=${PASS[3]}
EOF
chmod 640 /opt/app/.env
chown user3:user3 /opt/app/.env

# ---------------- L4 ----------------
touch /var/log/rotate.log
chmod 666 /var/log/rotate.log

cat << 'EOF' > /opt/rotate.sh
#!/bin/bash
bash /var/log/rotate.log
EOF
chmod 755 /opt/rotate.sh
echo "* * * * * user4 /opt/rotate.sh" > /etc/cron.d/rotate

cat << EOF > /var/backups/user4.txt
user5:${PASS[4]}
EOF

# ---------------- L5 ----------------
cat << 'EOF' > /usr/local/bin/cleanup.sh
#!/bin/bash
tar -czf /tmp/app_logs.tgz /var/log/app
EOF
chmod 755 /usr/local/bin/cleanup.sh

cat << EOF > /etc/sudoers.d/u5
user5 ALL=(root) /usr/local/bin/cleanup.sh
EOF
chmod 440 /etc/sudoers.d/u5

cat << EOF > /var/backups/user5.bak
user6:${PASS[5]}
EOF

# ---------------- L6 ----------------
cat << EOF > /etc/sudoers.d/u6
user6 ALL=(root) /usr/bin/find /var/backups
EOF
chmod 440 /etc/sudoers.d/u6

cat << EOF > /var/backups/user6.secret
user7:${PASS[6]}
EOF

# ---------------- L7 ----------------
cp /usr/bin/python3 /opt/pyread
setcap cap_dac_read_search+ep /opt/pyread

cat << EOF > /opt/app/config.yml
user: user8
pass: ${PASS[7]}
EOF
chmod 600 /opt/app/config.yml
chown user7:user7 /opt/app/config.yml

# ---------------- L8 ----------------
cat << EOF > /etc/sudoers.d/u8
user8 ALL=(root) /usr/bin/env
EOF
chmod 440 /etc/sudoers.d/u8

cat << EOF > /var/backups/user8.txt
user9:${PASS[8]}
EOF

# ---------------- L9 ----------------
cat << EOF > /etc/sudoers.d/u9
user9 ALL=(root) /bin/tar
EOF
chmod 440 /etc/sudoers.d/u9

cat << EOF > /var/backups/user9.conf
user10:${PASS[9]}
EOF

# ---------------- L10 ----------------
cat << EOF > /etc/sudoers.d/u10
user10 ALL=(root) /usr/bin/less
EOF
chmod 440 /etc/sudoers.d/u10

cat << EOF > /var/backups/user10.log
login=user11
password=${PASS[10]}
EOF

# ---------------- L11 ----------------
cp /bin/bash /opt/bash_ro
chmod 4755 /opt/bash_ro
chown root:root /opt/bash_ro

cat << EOF > /var/backups/user11.note
user12:${PASS[11]}
EOF

# ---------------- L12 ----------------
cat << EOF > /etc/sudoers.d/u12
user12 ALL=(root) /usr/bin/awk *
EOF
chmod 440 /etc/sudoers.d/u12

cat << EOF > /opt/app/app.conf
user=user13
pass=${PASS[12]}
EOF

# ---------------- L13 ----------------
cat << EOF > /etc/systemd/system/app.service
[Service]
ExecStart=/bin/cat /opt/app/app.conf
EOF

cat << EOF > /etc/sudoers.d/u13
user13 ALL=(root) /bin/systemctl restart app
EOF
chmod 440 /etc/sudoers.d/u13

# ---------------- L14 ----------------
cat << EOF > /etc/sudoers.d/u14
user14 ALL=(root) /bin/tar
EOF
chmod 440 /etc/sudoers.d/u14

cat << EOF > /var/backups/user14.creds
user15:${PASS[14]}
EOF

# ---------------- L15 ----------------
echo "FLAG{ROOT_REACHED_VIA_REAL_ENTERPRISE_CHAIN}" > /root/root.flag
chmod 400 /root/root.flag

echo "[+] LAB READY — ENTERPRISE MODE"
echo "[+] Entry point: user1"
