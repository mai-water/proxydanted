bash <(cat <<'EOF'
set -e

echo -n "Введите порт [1080]: "
read PORT
PORT=${PORT:-1080}

echo "[+] Установка Dante..."
apt update -qq
apt install -y dante-server curl >/dev/null

USER=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8)
PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8)

IFACE=$(ip route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -n1)
IP=$(curl -4 -s ifconfig.me)

useradd -r -s /usr/sbin/nologin "$USER" 2>/dev/null || true
echo "$USER:$PASS" | chpasswd

cat > /etc/danted.conf <<CONF
logoutput: syslog

user.privileged: root
user.unprivileged: nobody

internal: 0.0.0.0 port=$PORT
external: $IFACE

socksmethod: username
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
CONF

if command -v ufw >/dev/null 2>&1; then
    ufw allow "$PORT"/tcp >/dev/null 2>&1 || true
fi

systemctl enable danted >/dev/null 2>&1
systemctl restart danted

echo
echo -e "\033[1;32m========================================"
echo
echo "        Ваши прокси готовы!"
echo
echo "========================================"
echo
echo
echo "SOCKS5://$IP:$PORT:$USER:$PASS"
echo
echo
echo "========================================"
echo -e "\033[0m"

EOF
)
