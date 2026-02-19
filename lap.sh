#!/bin/bash
# 15-Level Enterprise Realistic Linux PrivEsc Lab
# STRICT PROGRESSION — NO SKIPPING
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
    echo "[!] Invalid choice."
  fi
done

echo "[+] Selected shell: $USER_SHELL"

# ================= USERS =================
for i in $(seq 1 $LEVELS); do
  useradd -m -s "$USER_SHELL" user$i
  chmod 700 /home/user$i
  mkdir -p /home/user$i/progress
  chmod 700 /home/user$i/progress
  chown -R user$i:user$i /home/user$i
done

# ================= PASSWORDS =================
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
  echo "user$i:${PASS[$((i-1))]}" | chpasswd
done

# ================= L1 — sudo log abuse =================
cat << EOF > /var/log/app.log
service_user=user2
service_pass=${PASS[1]}
EOF

cat << 'EOF' > /usr/local/bin/log_parser.sh
#!/bin/bash
cat /var/log/app.log
EOF
chmod 750 /usr/local/bin/log_parser.sh
chown root:user1 /usr/local/bin/log_parser.sh

echo "user1 ALL=(root) /usr/local/bin/log_parser.sh" > /etc/sudoers.d/u1
chmod 440 /etc/sudoers.d/u1

# ================= L2 — backup leak =================
cat << EOF > /home/user2/progress/db.conf
db_user=user3
db_pass=${PASS[2]}
EOF
chmod 600 /home/user2/progress/db.conf
chown user2:user2 /home/user2/progress/db.conf

# ================= L3 — SUID env abuse =================
cp /usr/bin/env /opt/env_suid
chmod 4755 /opt/env_suid
chown root:root /opt/env_suid

cat << EOF > /home/user3/progress/next.txt
NEXT_USER=user4
PASS=${PASS[3]}
EOF
chmod 600 /home/user3/progress/next.txt
chown user3:user3 /home/user3/progress/next.txt

# ================= L4 — cron writable log =================
touch /var/log/rotate.log
chmod 666 /var/log/rotate.log

cat << 'EOF' > /opt/rotate.sh
#!/bin/bash
bash /var/log/rotate.log
EOF
chmod 755 /opt/rotate.sh
echo "* * * * * user4 /opt/rotate.sh" > /etc/cron.d/rotate

cat << EOF > /home/user4/progress/creds
user5:${PASS[4]}
EOF
chmod 600 /home/user4/progress/creds
chown user4:user4 /home/user4/progress/creds

# ================= L5 — sudo tar =================
cat << 'EOF' > /usr/local/bin/cleanup.sh
#!/bin/bash
tar -czf /tmp/app.tgz /var/log
EOF
chmod 755 /usr/local/bin/cleanup.sh

echo "user5 ALL=(root) /usr/local/bin/cleanup.sh" > /etc/sudoers.d/u5
chmod 440 /etc/sudoers.d/u5

cat << EOF > /home/user5/progress/next
user6:${PASS[5]}
EOF
chmod 600 /home/user5/progress/next
chown user5:user5 /home/user5/progress/next

# ================= L6 — sudo find =================
echo "user6 ALL=(root) /usr/bin/find /home/user6" > /etc/sudoers.d/u6
chmod 440 /etc/sudoers.d/u6

cat << EOF > /home/user6/progress/key
user7:${PASS[6]}
EOF
chmod 600 /home/user6/progress/key
chown user6:user6 /home/user6/progress/key

# ================= L7 — capabilities python =================
cp /usr/bin/python3 /opt/pycap
setcap cap_dac_read_search+ep /opt/pycap

cat << EOF > /home/user7/progress/next
user8:${PASS[7]}
EOF
chmod 600 /home/user7/progress/next
chown user7:user7 /home/user7/progress/next

# ================= L8 — sudo env =================
echo "user8 ALL=(root) /usr/bin/env" > /etc/sudoers.d/u8
chmod 440 /etc/sudoers.d/u8

cat << EOF > /home/user8/progress/next
user9:${PASS[8]}
EOF
chmod 600 /home/user8/progress/next
chown user8:user8 /home/user8/progress/next

# ================= L9 — sudo tar =================
echo "user9 ALL=(root) /bin/tar" > /etc/sudoers.d/u9
chmod 440 /etc/sudoers.d/u9

cat << EOF > /home/user9/progress/next
user10:${PASS[9]}
EOF
chmod 600 /home/user9/progress/next
chown user9:user9 /home/user9/progress/next

# ================= L10 — sudo less =================
echo "user10 ALL=(root) /usr/bin/less" > /etc/sudoers.d/u10
chmod 440 /etc/sudoers.d/u10

cat << EOF > /home/user10/progress/next
user11:${PASS[10]}
EOF
chmod 600 /home/user10/progress/next
chown user10:user10 /home/user10/progress/next

# ================= L11 — SUID bash =================
cp /bin/bash /opt/bash_suid
chmod 4755 /opt/bash_suid

cat << EOF > /home/user11/progress/next
user12:${PASS[11]}
EOF
chmod 600 /home/user11/progress/next
chown user11:user11 /home/user11/progress/next

# ================= L12 — sudo awk =================
echo "user12 ALL=(root) /usr/bin/awk *" > /etc/sudoers.d/u12
chmod 440 /etc/sudoers.d/u12

cat << EOF > /home/user12/progress/next
user13:${PASS[12]}
EOF
chmod 600 /home/user12/progress/next
chown user12:user12 /home/user12/progress/next

# ================= L13 — systemd =================
cat << EOF > /etc/systemd/system/app.service
[Service]
ExecStart=/bin/cat /home/user13/progress/app.conf
EOF

cat << EOF > /home/user13/progress/app.conf
user14:${PASS[13]}
EOF
chmod 600 /home/user13/progress/app.conf
chown user13:user13 /home/user13/progress/app.conf

echo "user13 ALL=(root) /bin/systemctl restart app" > /etc/sudoers.d/u13
chmod 440 /etc/sudoers.d/u13

# ================= L14 — sudo tar (final pivot) =================
echo "user14 ALL=(root) /bin/tar" > /etc/sudoers.d/u14
chmod 440 /etc/sudoers.d/u14

cat << EOF > /home/user14/progress/root.txt
ROOT_PASS=${PASS[14]}
EOF
chmod 600 /home/user14/progress/root.txt
chown user14:user14 /home/user14/progress/root.txt

# ================= L15 =================
echo "FLAG{ROOT_REACHED_VIA_REAL_ENTERPRISE_CHAIN}" > /root/root.flag
chmod 400 /root/root.flag

echo "[+] LAB READY — NO SKIP — ENTERPRISE GRADE"
echo "[+] Entry point: user1"




