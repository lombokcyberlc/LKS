#!/bin/bash
# verify.sh — Script Verifikasi Layanan LKS SMK TKJ
# Jalankan sebagai root: bash verify.sh
# Script ini memeriksa semua layanan yang dikonfigurasi peserta

# ============================================================
# KONFIGURASI — Ubah sesuai data peserta
# ============================================================
DOMAIN="NAMASEKOLAH.lan"          # contoh: lombokcyber.lan
SERVER_IP="IP_SERVER"             # contoh: 10.100.100.1
LAN_IFACE="ens19"                 # interface LAN ke client
WAN_IFACE="ens18"                 # interface WAN ke internet
WEB_USER="NAMAUSER"               # user pemilik public_html
MAIL_USER1="NAMAUSER"             # akun email pertama
MAIL_USER2="NAMA_GURU"            # akun email kedua

# ============================================================
# FUNGSI HELPER
# ============================================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

ok()   { echo -e "  ${GREEN}[OK]${NC}    $1"; ((PASS++)); }
fail() { echo -e "  ${RED}[FAIL]${NC}  $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}[WARN]${NC}  $1"; }
section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"; }

# ============================================================
# MULAI VERIFIKASI
# ============================================================
echo ""
echo -e "${BOLD}=====================================================${NC}"
echo -e "${BOLD}   VERIFIKASI LAYANAN — LKS SMK TKJ${NC}"
echo -e "${BOLD}   Domain : ${DOMAIN}${NC}"
echo -e "${BOLD}   Server : ${SERVER_IP}${NC}"
echo -e "${BOLD}=====================================================${NC}"

# ============================================================
section "1. NETWORK & IP ADDRESS"
# ============================================================

# Cek IP di WAN interface
WAN_IP=$(ip addr show $WAN_IFACE 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
if [ -n "$WAN_IP" ]; then
    ok "$WAN_IFACE mendapat IP: $WAN_IP"
else
    fail "$WAN_IFACE tidak mendapat IP (DHCP gagal atau interface salah)"
fi

# Cek IP statis di LAN interface
LAN_IP=$(ip addr show $LAN_IFACE 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
if [ "$LAN_IP" = "$SERVER_IP" ]; then
    ok "$LAN_IFACE IP statis: $LAN_IP"
else
    fail "$LAN_IFACE IP tidak sesuai. Diharapkan: $SERVER_IP, Ditemukan: ${LAN_IP:-TIDAK ADA}"
fi

# Cek IP forwarding
IPFWD=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
if [ "$IPFWD" = "1" ]; then
    ok "IP forwarding aktif"
else
    fail "IP forwarding tidak aktif (nilai: ${IPFWD:-tidak terbaca})"
fi

# Cek NAT rule (nftables — default di Debian 13)
NAT=$(nft list ruleset 2>/dev/null | grep -c "masquerade")
if [ "$NAT" -gt 0 ]; then
    ok "NAT (masquerade) dikonfigurasi di nftables"
else
    warn "NAT masquerade tidak ditemukan di nftables — client mungkin tidak bisa akses internet"
fi

# ============================================================
section "2. DHCP SERVER"
# ============================================================

# Cek service status
if systemctl is-active --quiet isc-dhcp-server; then
    ok "isc-dhcp-server berjalan (active)"
else
    fail "isc-dhcp-server tidak berjalan"
fi

# Cek konfigurasi interface
DHCP_IFACE=$(grep INTERFACESv4 /etc/default/isc-dhcp-server 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if echo "$DHCP_IFACE" | grep -q "$LAN_IFACE"; then
    ok "Interface DHCP dikonfigurasi: $DHCP_IFACE"
else
    fail "Interface DHCP tidak sesuai. Diharapkan: $LAN_IFACE, Ditemukan: ${DHCP_IFACE:-tidak dikonfigurasi}"
fi

# Cek subnet di dhcpd.conf
if grep -q "subnet" /etc/dhcp/dhcpd.conf 2>/dev/null; then
    ok "Konfigurasi subnet ada di dhcpd.conf"
else
    fail "Konfigurasi subnet tidak ditemukan di /etc/dhcp/dhcpd.conf"
fi

# Cek domain name di dhcpd.conf
if grep -q "$DOMAIN" /etc/dhcp/dhcpd.conf 2>/dev/null; then
    ok "Domain name \"$DOMAIN\" ada di dhcpd.conf"
else
    fail "Domain name \"$DOMAIN\" tidak ditemukan di dhcpd.conf"
fi

# ============================================================
section "3. DNS SERVER"
# ============================================================

# Cek service
if systemctl is-active --quiet named; then
    ok "named (bind9) berjalan (active)"
else
    fail "named (bind9) tidak berjalan"
fi

# Cek port 53
if ss -ulnp 2>/dev/null | grep -q ':53'; then
    ok "DNS mendengarkan port 53 (UDP)"
else
    fail "DNS tidak mendengarkan port 53"
fi

# Cek named.conf
if named-checkconf 2>/dev/null; then
    ok "named-checkconf: sintaks konfigurasi valid"
else
    fail "named-checkconf: ada error di konfigurasi BIND"
fi

# Cek forward zone
ZONE_FILE=$(grep -A3 "zone \"$DOMAIN\"" /etc/bind/named.conf.local 2>/dev/null | grep "file" | awk -F'"' '{print $2}')
if [ -n "$ZONE_FILE" ] && [ -f "$ZONE_FILE" ]; then
    if named-checkzone "$DOMAIN" "$ZONE_FILE" 2>/dev/null | grep -q "OK"; then
        ok "Forward zone file valid: $ZONE_FILE"
    else
        fail "Forward zone file ada error: $ZONE_FILE"
    fi
else
    fail "Forward zone file tidak ditemukan (cek named.conf.local)"
fi

# Cek A record via dig
A_RESULT=$(dig +short @127.0.0.1 "$DOMAIN" A 2>/dev/null)
if [ "$A_RESULT" = "$SERVER_IP" ]; then
    ok "A record $DOMAIN → $A_RESULT (benar)"
else
    fail "A record $DOMAIN tidak sesuai. Diharapkan: $SERVER_IP, Ditemukan: ${A_RESULT:-tidak ada response}"
fi

# Cek www record
WWW_RESULT=$(dig +short @127.0.0.1 "www.$DOMAIN" A 2>/dev/null)
if [ "$WWW_RESULT" = "$SERVER_IP" ]; then
    ok "A record www.$DOMAIN → $WWW_RESULT (benar)"
else
    fail "A record www.$DOMAIN tidak sesuai. Ditemukan: ${WWW_RESULT:-tidak ada}"
fi

# Cek MX record
MX_RESULT=$(dig +short @127.0.0.1 "$DOMAIN" MX 2>/dev/null)
if [ -n "$MX_RESULT" ]; then
    ok "MX record $DOMAIN: $MX_RESULT"
else
    fail "MX record $DOMAIN tidak ditemukan"
fi

# Cek reverse zone
REV_RESULT=$(dig +short @127.0.0.1 -x "$SERVER_IP" 2>/dev/null)
if [ -n "$REV_RESULT" ]; then
    ok "Reverse DNS $SERVER_IP → $REV_RESULT"
else
    fail "Reverse DNS $SERVER_IP tidak ada PTR record"
fi

# ============================================================
section "4. WEB SERVER"
# ============================================================

# Cek service
if systemctl is-active --quiet apache2; then
    ok "apache2 berjalan (active)"
else
    fail "apache2 tidak berjalan"
fi

# Cek port 80
if ss -tlnp 2>/dev/null | grep -q ':80'; then
    ok "Apache mendengarkan port 80"
else
    fail "Apache tidak mendengarkan port 80"
fi

# Cek VirtualHost config
VHOST_FILE="/etc/apache2/sites-enabled/${DOMAIN}.conf"
if [ -f "$VHOST_FILE" ]; then
    ok "VirtualHost aktif: $VHOST_FILE"
else
    # Cek di sites-available juga
    if [ -f "/etc/apache2/sites-available/${DOMAIN}.conf" ]; then
        fail "VirtualHost ada tapi BELUM diaktifkan (jalankan: a2ensite ${DOMAIN}.conf)"
    else
        fail "File VirtualHost tidak ditemukan: $VHOST_FILE"
    fi
fi

# Cek DocumentRoot
DOC_ROOT="/home/$WEB_USER/public_html"
if [ -d "$DOC_ROOT" ]; then
    ok "DocumentRoot ada: $DOC_ROOT"
else
    fail "DocumentRoot tidak ditemukan: $DOC_ROOT"
fi

# Cek index.html
INDEX_FILE="$DOC_ROOT/index.html"
if [ -f "$INDEX_FILE" ]; then
    ok "index.html ada: $INDEX_FILE"
    # Cek konten placeholder
    if grep -qi "ISI:" "$INDEX_FILE" 2>/dev/null; then
        warn "index.html masih mengandung placeholder yang belum diisi"
    fi
else
    fail "index.html tidak ditemukan di $DOC_ROOT"
fi

# Cek apache configtest
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    ok "apache2ctl configtest: Syntax OK"
else
    fail "apache2ctl configtest: ada error konfigurasi"
fi

# Cek akses HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP" --max-time 5 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    ok "HTTP akses ke $SERVER_IP: 200 OK"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    warn "HTTP akses ke $SERVER_IP: $HTTP_CODE (redirect)"
else
    fail "HTTP akses ke $SERVER_IP gagal: HTTP $HTTP_CODE"
fi

# ============================================================
section "5. MAIL SERVER"
# ============================================================

# Cek Postfix
if systemctl is-active --quiet postfix; then
    ok "postfix berjalan (active)"
else
    fail "postfix tidak berjalan"
fi

# Cek port 25
if ss -tlnp 2>/dev/null | grep -q ':25'; then
    ok "Postfix mendengarkan port 25 (SMTP)"
else
    fail "Postfix tidak mendengarkan port 25"
fi

# Cek Dovecot
if systemctl is-active --quiet dovecot; then
    ok "dovecot berjalan (active)"
else
    fail "dovecot tidak berjalan"
fi

# Cek port 143 (IMAP)
if ss -tlnp 2>/dev/null | grep -q ':143'; then
    ok "Dovecot mendengarkan port 143 (IMAP)"
else
    fail "Dovecot tidak mendengarkan port 143"
fi

# Cek port 110 (POP3)
if ss -tlnp 2>/dev/null | grep -q ':110'; then
    ok "Dovecot mendengarkan port 110 (POP3)"
else
    fail "Dovecot tidak mendengarkan port 110"
fi

# Cek konfigurasi Maildir di Postfix
if grep -q "home_mailbox = Maildir/" /etc/postfix/main.cf 2>/dev/null; then
    ok "Postfix: home_mailbox = Maildir/ (format benar)"
else
    fail "Postfix: home_mailbox = Maildir/ tidak dikonfigurasi"
fi

# Cek mydomain di Postfix
if grep -q "mydomain = $DOMAIN" /etc/postfix/main.cf 2>/dev/null; then
    ok "Postfix: mydomain = $DOMAIN"
else
    fail "Postfix: mydomain = $DOMAIN tidak dikonfigurasi"
fi

# Cek akun user
if id "$MAIL_USER1" &>/dev/null; then
    ok "Akun email user 1 ada: $MAIL_USER1"
else
    fail "Akun email user 1 tidak ada: $MAIL_USER1 (jalankan: adduser $MAIL_USER1)"
fi

if id "$MAIL_USER2" &>/dev/null; then
    ok "Akun email user 2 ada: $MAIL_USER2"
else
    fail "Akun email user 2 tidak ada: $MAIL_USER2 (jalankan: adduser $MAIL_USER2)"
fi

# Cek konfigurasi Maildir di Dovecot
# Dovecot 2.4+ (Debian 13) menggunakan mail_driver + mail_path
# Dovecot 2.3 dan sebelumnya menggunakan mail_location
if grep -rq "mail_driver = maildir" /etc/dovecot/ 2>/dev/null && \
   grep -rq "mail_path = ~/Maildir" /etc/dovecot/ 2>/dev/null; then
    ok "Dovecot: mail_driver = maildir, mail_path = ~/Maildir (benar)"
elif grep -rq "maildir:~/Maildir" /etc/dovecot/ 2>/dev/null; then
    ok "Dovecot: mail_location = maildir:~/Maildir (benar)"
else
    fail "Dovecot: format Maildir tidak dikonfigurasi di /etc/dovecot/conf.d/10-mail.conf"
fi

# ============================================================
# RINGKASAN
# ============================================================
TOTAL=$((PASS + FAIL))
echo ""
echo -e "${BOLD}=====================================================${NC}"
echo -e "${BOLD}   RINGKASAN HASIL VERIFIKASI${NC}"
echo -e "${BOLD}=====================================================${NC}"
echo -e "  ${GREEN}PASS${NC}: $PASS dari $TOTAL"
echo -e "  ${RED}FAIL${NC}: $FAIL dari $TOTAL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}SEMUA LAYANAN BERHASIL DIKONFIGURASI!${NC}"
else
    echo -e "  ${YELLOW}Ada $FAIL item yang perlu diperbaiki.${NC}"
    echo -e "  Periksa pesan FAIL di atas untuk detail."
fi
echo ""
