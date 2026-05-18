# Panduan Setup Linux Server — LKS SMK TKJ

**Sistem Operasi**: Debian 13 (Trixie)
**Peran**: Server administrasi jaringan sekolah

> Baca seluruh panduan sebelum mulai mengerjakan. Setiap tugas memiliki langkah
> instalasi, konfigurasi, dan verifikasi. Jangan lewatkan langkah verifikasi
> karena juri akan mengecek layanan berjalan dengan benar.

---

## Daftar Isi

1. [Persiapan Awal](#1-persiapan-awal)
2. [Tugas 0 — Konfigurasi Jaringan Lengkap](#tugas-0--konfigurasi-jaringan-lengkap)
3. [Tugas 1 — DHCP Server](#tugas-1--dhcp-server)
4. [Tugas 2 — DNS Server](#tugas-2--dns-server)
5. [Tugas 3 — Web Server](#tugas-3--web-server)
6. [Tugas 4 — Upload File via SCP](#tugas-4--upload-file-via-scp)
7. [Tugas 5 — Mail Server](#tugas-5--mail-server)
8. [Tugas 6 — Uji Coba Email](#tugas-6--uji-coba-email)

---

## 1. Persiapan Awal

### 1.1 Login sebagai root

Semua perintah konfigurasi dijalankan sebagai **root**. Login langsung sebagai root
atau gunakan `sudo` jika akun biasa yang digunakan:

```bash
su -
# atau
sudo -i
```

### 1.2 Update sistem

```bash
apt update && apt upgrade -y
```

### 1.3 Cek Nama Interface Jaringan

Sebelum mengkonfigurasi apapun, identifikasi nama interface yang ada di server ini.
Nama interface di VMware bisa berbeda antar mesin.

```bash
ip link show
```

Catat nama interface:

- Interface ke **internet (WAN)**: biasanya `ens18`
- Interface ke **client/LAN**: biasanya `ens19`

---

### 1.4 Konfigurasi IP Address ens19

`ens18` sudah dikonfigurasi otomatis oleh installer Debian (DHCP client, auto up).
Yang perlu dikonfigurasi manual hanya `ens19` sebagai interface LAN ke client.

IP untuk setiap peserta sudah ditentukan di soal lomba.

Cek isi `/etc/network/interfaces` yang sudah ada dari installer:

```bash
cat /etc/network/interfaces
```

Biasanya sudah berisi:

```text
auto lo
iface lo inet loopback

auto ens18
iface ens18 inet dhcp
```

Tambahkan konfigurasi ens19 di bawah baris ens18 yang sudah ada:

```bash
nano /etc/network/interfaces
```

```text
auto lo
iface lo inet loopback

auto ens18
iface ens18 inet dhcp

auto ens19
iface ens19 inet static
    address IP_SERVER
    netmask 255.255.255.0
```

Aktifkan ens19 secara manual:

```bash
ifup ens19
```

Verifikasi IP sudah terpasang:

```bash
ip addr show ens19
```

Output yang diharapkan: `inet IP_SERVER/24`

---

### 1.5 Set Hostname

Hostname dikonfigurasi setelah IP diketahui sehingga `/etc/hosts` dapat
langsung diisi dengan IP nyata — tidak perlu workaround `127.0.1.1`.

Format hostname: `mail.NAMASEKOLAH.lan`

#### Set hostname sistem

```bash
hostnamectl set-hostname mail.NAMASEKOLAH.lan
```

Contoh:

```bash
hostnamectl set-hostname mail.lombokcyber.lan
```

#### Update `/etc/hosts`

`hostname -f` mencari nama di `/etc/hosts`, **bukan** lewat DNS.
Wajib ada entri yang memetakan IP nyata ke hostname.

```bash
nano /etc/hosts
```

```text
127.0.0.1       localhost
IP_SERVER       mail.NAMASEKOLAH.lan   mail   NAMASEKOLAH.lan
```

Contoh untuk lombokcyber.lan (IP 10.100.100.1):

```text
127.0.0.1       localhost
10.100.100.1    mail.lombokcyber.lan   mail   lombokcyber.lan
```

---

### 1.6 Verifikasi Hostname dan IP Address

```bash
hostname
```

Output yang diharapkan: `mail.NAMASEKOLAH.lan`

```bash
hostname -f
```

Output yang diharapkan: `mail.NAMASEKOLAH.lan` — berhasil karena `/etc/hosts` sudah diisi IP nyata.

```bash
hostnamectl status
```

```bash
ip addr show ens19
```

Jika `hostname -f` masih error **"Name or service not known"**, periksa:

1. Entri di `/etc/hosts` — apakah nama persis sama dengan output `hostname`?
2. Apakah IP di `/etc/hosts` sudah sesuai dengan IP ens19?

---

### 1.7 Install tools dasar

Install tool bantu yang diperlukan selama konfigurasi berlangsung:

```bash
apt install -y net-tools curl wget vim
```

> Paket layanan (DHCP, DNS, Web, Mail) diinstall masing-masing tepat sebelum
> tahap konfigurasinya dimulai.

---

## Tugas 0 — Konfigurasi Jaringan Lengkap

**Tujuan:**

Mengaktifkan IP forwarding dan NAT agar client (ens19) dapat mengakses
internet melalui server (ens18).

> `ens18` sudah auto up via DHCP sejak boot.
> `ens19` sudah dikonfigurasi manual di Persiapan Awal (1.4).

### Langkah 1 — Verifikasi Kedua Interface

```bash
ip addr show
```

Pastikan ens18 sudah mendapat IP dari DHCP internet dan ens19 menampilkan `IP_SERVER/24`.

Pastikan ens18 bisa akses internet:

```bash
ping -c 3 8.8.8.8
```

### Langkah 2 — Aktifkan IP Forwarding

IP Forwarding memungkinkan server meneruskan paket dari client (ens19)
ke internet (ens18) — fungsi dasar sebagai gateway/router.

Aktifkan sementara (langsung berlaku tanpa reboot):

```bash
sysctl -w net.ipv4.ip_forward=1
```

Aktifkan permanen (bertahan setelah reboot):

```bash
nano /etc/sysctl.conf
```

Cari baris berikut dan hapus tanda `#`:

```text
net.ipv4.ip_forward=1
```

Terapkan:

```bash
sysctl -p
```

### Langkah 3 — Konfigurasi NAT (nftables) *(Opsional — Nilai Plus)*

> **Catatan**: Langkah ini **tidak mempengaruhi penilaian utama**. Namun jika berhasil dikonfigurasi, peserta mendapat **nilai plus (bonus)**. Lewati langkah ini jika waktu tidak cukup.

NAT (masquerade) mengganti IP sumber paket dari client dengan IP ens18,
sehingga paket dapat keluar ke internet dan balasannya kembali ke client.

```bash
systemctl enable nftables
systemctl start nftables
```

Edit konfigurasi nftables:

```bash
nano /etc/nftables.conf
```

Tambahkan tabel NAT di bagian bawah file:

```text
table ip nat {
    chain postrouting {
        type nat hook postrouting priority srcnat;
        policy accept;
        oifname "ens18" masquerade
    }
}
```

**Keterangan:**

- `table ip nat` — tabel untuk IPv4 (`ip`), nama `nat` adalah konvensi
- `chain postrouting` — rantai aturan yang berjalan **setelah** keputusan routing selesai, tepat sebelum paket keluar dari interface
- `hook postrouting` — titik di kernel tempat chain ini dipasang; paket di sini sudah tahu akan keluar lewat interface mana
- `priority srcnat` — urutan pemrosesan untuk NAT sumber (alias nilai `100`)
- `policy accept` — jika tidak ada rule yang cocok, paket tetap diteruskan (tidak diblok)
- `oifname "ens18"` — cocokkan paket yang keluar lewat `ens18` (interface internet/WAN)
- `masquerade` — ganti IP sumber paket dengan IP `ens18` secara otomatis; berbeda dengan `snat` yang butuh IP statis, `masquerade` cocok untuk IP dinamis (DHCP)

Terapkan:

```bash
nft -f /etc/nftables.conf
systemctl reload nftables
```

> **Referensi belajar nftables lebih lanjut:**
>
> - Dokumentasi resmi: [wiki.nftables.org](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page)
> - Quick reference: [nftables in 10 minutes](https://wiki.nftables.org/wiki-nftables/index.php/Quick_reference-nftables_in_10_minutes)
> - Arch Linux Wiki (lengkap): [wiki.archlinux.org/title/nftables](https://wiki.archlinux.org/title/nftables)

### Verifikasi

```bash
ip addr show
cat /proc/sys/net/ipv4/ip_forward
ip route show
nft list table ip nat
ping -c 3 8.8.8.8
```

- `ip addr show` — cek semua interface dan IP yang terpasang
- `cat /proc/sys/net/ipv4/ip_forward` — cek IP forwarding aktif (harus bernilai `1`)
- `ip route show` — cek routing table
- `nft list table ip nat` — cek rule NAT aktif
- `ping -c 3 8.8.8.8` — cek koneksi internet dari server

---

## Tugas 1 — DHCP Server

**Tujuan:**
Server membagikan IP otomatis ke client yang terhubung ke interface `ens19`.

### Instalasi Paket DHCP

```bash
apt install -y isc-dhcp-server
```

### Langkah 1: Tentukan interface DHCP

Edit file `/etc/default/isc-dhcp-server` untuk menentukan interface yang digunakan:

```bash
nano /etc/default/isc-dhcp-server
```

Cari baris `INTERFACESv4` dan isi dengan interface LAN:

```text
INTERFACESv4="ens19"
INTERFACESv6=""
```

### Langkah 2: Konfigurasi DHCP

```bash
nano /etc/dhcp/dhcpd.conf
```

Hapus semua isi default, ganti dengan konfigurasi berikut:

```text
default-lease-time 43200;
max-lease-time 86400;
authoritative;

subnet IP_NETWORK netmask 255.255.255.0 {
    range IP_RANGE_START IP_RANGE_END;
    option routers IP_SERVER;
    option subnet-mask 255.255.255.0;
    option domain-name-servers IP_SERVER;
    option domain-name "NAMASEKOLAH.lan";
    option broadcast-address IP_BROADCAST;
}
```

- `default-lease-time 43200` — waktu sewa IP default: 43200 detik (12 jam)
- `max-lease-time 86400` — waktu sewa IP maksimum: 86400 detik (24 jam)
- `authoritative` — server ini adalah DHCP server otoritatif untuk subnet ini
- `subnet ... netmask ...` — definisi subnet yang dilayani
- `range` — range IP yang akan dibagikan ke client
- `option routers` — gateway yang diberikan ke client (IP server di LAN)
- `option subnet-mask` — subnet mask yang diberikan ke client
- `option domain-name-servers` — DNS server yang diberikan ke client (IP server sendiri)
- `option domain-name` — nama domain yang diberikan ke client
- `option broadcast-address` — broadcast address subnet

**Contoh untuk lombokcyber (IP server: 10.100.100.1):**

```text
default-lease-time 43200;
max-lease-time 86400;
authoritative;

subnet 10.100.100.0 netmask 255.255.255.0 {
    range 10.100.100.100 10.100.100.200;
    option routers 10.100.100.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 10.100.100.1;
    option domain-name "lombokcyber.lan";
    option broadcast-address 10.100.100.255;
}
```

### Langkah 3: Aktifkan dan jalankan layanan

```bash
systemctl enable isc-dhcp-server
systemctl start isc-dhcp-server
systemctl status isc-dhcp-server
```

### Verifikasi DHCP

```bash
systemctl status isc-dhcp-server
journalctl -u isc-dhcp-server -n 30
cat /var/lib/dhcp/dhcpd.leases
```

- `systemctl status isc-dhcp-server` — cek status layanan
- `journalctl -u isc-dhcp-server -n 30` — cek log jika ada error
- `cat /var/lib/dhcp/dhcpd.leases` — lihat IP yang sudah disewa client

Di sisi client (Debian Desktop), jalankan:

```bash
dhclient ens18
ip addr show ens18
```

- `dhclient ens18` — minta IP dari DHCP server
- `ip addr show ens18` — cek IP yang diterima

---

## Tugas 2 — DNS Server

**Tujuan:**
Server menjawab query nama domain → IP address untuk domain sekolah Anda.

### Instalasi Paket DNS

```bash
apt install -y bind9 bind9utils bind9-doc
```

### Penjelasan Konsep DNS Zone

Sebuah zone DNS terdiri dari dua file:

1. **Forward zone** — mengubah nama domain → IP address (A record)
2. **Reverse zone** — mengubah IP address → nama domain (PTR record)

### Penjelasan SOA Record (Start of Authority)

SOA adalah record pertama di setiap file zone. Berisi informasi otoritas dan
parameter sinkronisasi untuk DNS sekunder (secondary DNS).

```text
@   IN  SOA  ns1.NAMASEKOLAH.lan. admin.NAMASEKOLAH.lan. (
               2026051801   ; Serial  — format YYYYMMDDNN
                                        Y=tahun, M=bulan, D=tanggal, NN=urutan
                                        INCREMENT setiap kali file zone diubah!
               3600         ; Refresh — (1 jam)
                                        Seberapa sering DNS sekunder cek ke primary
                                        Rumus: pilih 1-24 jam (3600-86400 detik)
               1800         ; Retry   — (30 menit)
                                        Jika refresh gagal, berapa lama tunggu sebelum retry
                                        Rumus: harus < Refresh, biasanya 1/2 dari Refresh
               604800       ; Expire  — (7 hari)
                                        Jika DNS primary tidak bisa dicapai terus,
                                        DNS sekunder masih melayani data sampai waktu ini habis
                                        Rumus: pilih 1-4 minggu (604800-2419200 detik)
               86400        ; Negative TTL — (1 hari)
                                        Berapa lama resolver menyimpan jawaban "domain tidak ada"
                                        Rumus: 1/7 dari Expire, biasanya 1 hari (86400 detik)
)
```

### Langkah 1: Konfigurasi named.conf.local

```bash
nano /etc/bind/named.conf.local
```

```text
zone "NAMASEKOLAH.lan" {
    type master;
    file "/etc/bind/zones/db.NAMASEKOLAH.lan";
};

zone "IP_REVERSE_OCTET.IP_REVERSE_OCTET2.IP_REVERSE_OCTET3.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.IP_NETWORK";
};
```

- Blok pertama adalah **forward zone** — memetakan nama domain ke IP address
- `type master` — server ini adalah primary DNS yang berwenang untuk zone ini
- `file` — lokasi file zone yang berisi record-record DNS
- Blok kedua adalah **reverse zone** — memetakan IP address ke nama domain
- Nama zone reverse: oktet-oktet IP jaringan dibalik, tanpa oktet terakhir, ditambah `.in-addr.arpa`. Contoh untuk jaringan `10.100.100.0/24`: `100.100.10.in-addr.arpa`

**Contoh untuk lombokcyber (jaringan 10.100.100.0/24):**

```text
zone "lombokcyber.lan" {
    type master;
    file "/etc/bind/zones/db.lombokcyber.lan";
};

zone "100.100.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.100.100";
};
```

> **Penjelasan nama reverse zone**: Jaringan `10.100.100.0/24` → oktet dibalik
> menjadi `100.100.10` → ditambah `.in-addr.arpa` → `100.100.10.in-addr.arpa`

### Langkah 2: Buat direktori zones

```bash
mkdir -p /etc/bind/zones
```

### Langkah 3: Buat file forward zone

```bash
nano /etc/bind/zones/db.NAMASEKOLAH.lan
```

```text
$TTL 86400

@   IN  SOA  ns1.NAMASEKOLAH.lan. admin.NAMASEKOLAH.lan. (
               2026051801   ; Serial
               3600         ; Refresh (1 jam)
               1800         ; Retry   (30 menit)
               604800       ; Expire  (7 hari)
               86400 )      ; Negative TTL (1 hari)

@       IN  NS      ns1.NAMASEKOLAH.lan.

@       IN  A       IP_SERVER
ns1     IN  A       IP_SERVER
www     IN  A       IP_SERVER
mail    IN  A       IP_SERVER

@       IN  MX  10  mail.NAMASEKOLAH.lan.
```

Jenis record yang digunakan:

- `$TTL` — default Time-To-Live: berapa lama record di-cache oleh resolver (86400 detik = 1 hari)
- `SOA` — Start of Authority, harus ada di setiap file zone; berisi parameter sinkronisasi DNS
- `NS` — nameserver yang bertanggung jawab untuk domain ini
- `A` — pemetaan nama host ke IP address; `@` berarti domain utama (`NAMASEKOLAH.lan`)
- `MX` — mail server untuk domain ini; angka `10` adalah prioritas (semakin kecil, semakin diprioritaskan)
- `CNAME` — alias/nama lain untuk host yang sudah ada (contoh: `ftp IN CNAME www.NAMASEKOLAH.lan.`)

**Contoh untuk lombokcyber:**

```text
$TTL 86400

@   IN  SOA  ns1.lombokcyber.lan. admin.lombokcyber.lan. (
               2026051801
               3600
               1800
               604800
               86400 )

@       IN  NS      ns1.lombokcyber.lan.

@       IN  A       10.100.100.1
ns1     IN  A       10.100.100.1
www     IN  A       10.100.100.1
mail    IN  A       10.100.100.1

@       IN  MX  10  mail.lombokcyber.lan.
```

### Langkah 4: Buat file reverse zone

```bash
nano /etc/bind/zones/db.IP_NETWORK
```

```text
$TTL 86400

@   IN  SOA  ns1.NAMASEKOLAH.lan. admin.NAMASEKOLAH.lan. (
               2026051801   ; Serial (samakan dengan forward zone)
               3600         ; Refresh
               1800         ; Retry
               604800       ; Expire
               86400 )      ; Negative TTL

@       IN  NS      ns1.NAMASEKOLAH.lan.

1       IN  PTR     ns1.NAMASEKOLAH.lan.
1       IN  PTR     NAMASEKOLAH.lan.
1       IN  PTR     www.NAMASEKOLAH.lan.
1       IN  PTR     mail.NAMASEKOLAH.lan.
```

- `PTR` — record kebalikan dari A record; memetakan IP address ke nama domain
- Format entri: `oktet_terakhir_IP  IN  PTR  nama_lengkap.` — contoh: IP `10.100.100.1` menggunakan oktet terakhir `1`
- Serial SOA harus disamakan dengan forward zone agar konsisten

**Contoh untuk lombokcyber (IP server 10.100.100.1):**

```text
$TTL 86400

@   IN  SOA  ns1.lombokcyber.lan. admin.lombokcyber.lan. (
               2026051801
               3600
               1800
               604800
               86400 )

@       IN  NS      ns1.lombokcyber.lan.

1       IN  PTR     ns1.lombokcyber.lan.
1       IN  PTR     lombokcyber.lan.
1       IN  PTR     www.lombokcyber.lan.
1       IN  PTR     mail.lombokcyber.lan.
```

### Langkah 5: Set kepemilikan file

```bash
chown -R bind:bind /etc/bind/zones/
chmod 640 /etc/bind/zones/*
```

### Langkah 6: Konfigurasi forwarder (agar bisa resolve domain luar)

```bash
nano /etc/bind/named.conf.options
```

Cari blok `options { ... }` dan tambahkan/ubah bagian `forwarders`:

```text
options {
    directory "/var/cache/bind";

    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;
    listen-on { any; };
    allow-query { any; };
};
```

- `forwarders` — teruskan query yang tidak bisa dijawab secara lokal ke DNS publik; `8.8.8.8` dan `8.8.4.4` adalah Google DNS
- `listen-on { any; }` — dengarkan query dari semua interface
- `allow-query { any; }` — izinkan query dari semua client

### Langkah 7: Cek konfigurasi

```bash
named-checkconf
named-checkzone NAMASEKOLAH.lan /etc/bind/zones/db.NAMASEKOLAH.lan
named-checkzone 100.100.10.in-addr.arpa /etc/bind/zones/db.10.100.100
```

- `named-checkconf` — cek sintaks `named.conf` dan semua file yang di-include
- `named-checkzone NAMASEKOLAH.lan ...` — cek sintaks file zone forward
- `named-checkzone 100.100.10.in-addr.arpa ...` — cek sintaks file zone reverse

Jika tidak ada output error, lanjutkan.

### Langkah 8: Aktifkan dan restart BIND

```bash
systemctl enable named
systemctl restart named
systemctl status named
```

### Langkah 9: Set DNS server ke diri sendiri

```bash
nano /etc/resolv.conf
```

```text
nameserver IP_SERVER
nameserver 8.8.8.8
```

- `nameserver IP_SERVER` — gunakan DNS server sendiri sebagai resolver utama
- `nameserver 8.8.8.8` — fallback ke Google DNS jika server lokal tidak bisa menjawab

**Contoh untuk lombokcyber (IP server: 10.100.100.1):**

```text
nameserver 10.100.100.1
nameserver 8.8.8.8
```

Atau lebih permanen via `/etc/network/interfaces`, tambahkan di blok `ens19`:

```text
    dns-nameservers IP_SERVER 8.8.8.8
    dns-search NAMASEKOLAH.lan
```

**Contoh untuk lombokcyber:**

```text
    dns-nameservers 10.100.100.1 8.8.8.8
    dns-search lombokcyber.lan
```

### Verifikasi DNS

```bash
dig NAMASEKOLAH.lan
dig www.NAMASEKOLAH.lan
dig mail.NAMASEKOLAH.lan
dig MX NAMASEKOLAH.lan
dig -x IP_SERVER
nslookup NAMASEKOLAH.lan
nslookup IP_SERVER
ss -ulnp | grep :53
```

- `dig NAMASEKOLAH.lan` / `dig www...` / `dig mail...` — query forward (nama → IP)
- `dig MX NAMASEKOLAH.lan` — query record mail server
- `dig -x IP_SERVER` — query reverse (IP → nama)
- `nslookup` — alternatif query DNS
- `ss -ulnp | grep :53` — cek apakah DNS server mendengarkan port 53

---

## Tugas 3 — Web Server

**Tujuan:**
Server menyajikan halaman web untuk domain `NAMASEKOLAH.lan` dan `www.NAMASEKOLAH.lan`.

### Instalasi Paket Web

```bash
apt install -y apache2
```

### Langkah 1: Buat user dan direktori web

```bash
adduser NAMAUSER
mkdir -p /home/NAMAUSER/public_html
chown NAMAUSER:NAMAUSER /home/NAMAUSER/public_html
chmod 711 /home/NAMAUSER
chmod 755 /home/NAMAUSER/public_html
```

- `adduser NAMAUSER` — buat user sekolah; `adduser` otomatis membuat `/home/NAMAUSER` dengan kepemilikan yang benar
- `mkdir -p /home/NAMAUSER/public_html` — buat direktori web; karena dijalankan sebagai root, direktori ini awalnya milik `root:root`
- `chown NAMAUSER:NAMAUSER /home/NAMAUSER/public_html` — pindahkan kepemilikan ke user yang bersangkutan agar user bisa menulis file di sini
- `chmod 711 /home/NAMAUSER` — izinkan Apache masuk ke direktori home (execute), tanpa mengekspos isinya ke publik
- `chmod 755 /home/NAMAUSER/public_html` — izinkan Apache membaca dan mengakses isi direktori web

**Contoh untuk lombokcyber (user: peserta):**

```bash
adduser peserta
mkdir -p /home/peserta/public_html
chown peserta:peserta /home/peserta/public_html
chmod 711 /home/peserta
chmod 755 /home/peserta/public_html
```

### Langkah 2: Buat file HTML placeholder

```bash
nano /home/NAMAUSER/public_html/index.html
```

Isi sementara (akan diganti file asli via SCP di Tugas 4):

```html
<!DOCTYPE html>
<html>
<head><title>NAMASEKOLAH.lan</title></head>
<body>
<h1>Selamat Datang di NAMASEKOLAH</h1>
<p>Halaman ini akan diupdate oleh peserta.</p>
</body>
</html>
```

Set kepemilikan:

```bash
chown -R NAMAUSER:NAMAUSER /home/NAMAUSER/public_html
```

### Langkah 3: Buat konfigurasi VirtualHost

```bash
nano /etc/apache2/sites-available/NAMASEKOLAH.lan.conf
```

```apache
<VirtualHost *:80>
    ServerName NAMASEKOLAH.lan
    ServerAlias www.NAMASEKOLAH.lan
    DocumentRoot /home/NAMAUSER/public_html
    ServerAdmin webmaster@NAMASEKOLAH.lan

    <Directory /home/NAMAUSER/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/NAMASEKOLAH.lan-error.log
    CustomLog ${APACHE_LOG_DIR}/NAMASEKOLAH.lan-access.log combined
</VirtualHost>
```

- `ServerName` — nama domain utama yang dilayani VirtualHost ini
- `ServerAlias` — alias domain; `www.NAMASEKOLAH.lan` juga diarahkan ke VirtualHost ini
- `DocumentRoot` — direktori root tempat file web disimpan
- `ServerAdmin` — email administrator yang muncul di halaman error Apache
- `<Directory>` — blok izin akses ke direktori DocumentRoot
- `ErrorLog` / `CustomLog` — lokasi file log akses dan error khusus VirtualHost ini

**Contoh untuk lombokcyber (user: peserta, IP: 10.100.100.1):**

```apache
<VirtualHost *:80>
    ServerName lombokcyber.lan
    ServerAlias www.lombokcyber.lan
    DocumentRoot /home/peserta/public_html
    ServerAdmin webmaster@lombokcyber.lan

    <Directory /home/peserta/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/lombokcyber.lan-error.log
    CustomLog ${APACHE_LOG_DIR}/lombokcyber.lan-access.log combined
</VirtualHost>
```

### Langkah 4: Aktifkan VirtualHost

```bash
a2ensite NAMASEKOLAH.lan.conf
a2dissite 000-default.conf
apache2ctl configtest
systemctl reload apache2
systemctl status apache2
```

- `a2ensite NAMASEKOLAH.lan.conf` — membuat symlink dari `sites-available/` ke `sites-enabled/` secara otomatis; tidak perlu membuat symlink manual dengan `ln -s`
- `a2dissite 000-default.conf` — hapus symlink site default agar tidak konflik (opsional tapi disarankan)
- `apache2ctl configtest` — cek sintaks konfigurasi sebelum reload; harus menampilkan `Syntax OK`
- `systemctl reload apache2` — reload Apache agar konfigurasi baru berlaku tanpa memutus koneksi aktif

### Verifikasi Web Server

Dari server sendiri:

```bash
curl http://NAMASEKOLAH.lan
curl http://www.NAMASEKOLAH.lan
ss -tlnp | grep :80
```

Dari client/desktop (buka browser atau jalankan):

```bash
curl http://NAMASEKOLAH.lan
```

- `curl http://NAMASEKOLAH.lan` — cek halaman web dapat diakses
- `ss -tlnp | grep :80` — cek Apache mendengarkan port 80

---

## Tugas 4 — Upload File via SCP

**Tujuan:**
Peserta mengupload file HTML dari Debian Desktop ke server menggunakan `scp`.

### File yang diupload

File `index.html` berisi informasi: nama sekolah, nama guru pendamping, nama peserta.

### Langkah di sisi Desktop (client)

Format perintah SCP: `scp [file_lokal] [user]@[ip_server]:[path_tujuan]`

```bash
scp /path/ke/index.html NAMAUSER@IP_SERVER:/home/NAMAUSER/public_html/index.html
```

**Contoh:**

```bash
scp ~/Desktop/index.html peserta@10.100.100.1:/home/peserta/public_html/index.html
```

Masukkan password user saat diminta.

### Langkah di sisi Server (verifikasi)

```bash
ls -la /home/NAMAUSER/public_html/
cat /home/NAMAUSER/public_html/index.html
chmod 644 /home/NAMAUSER/public_html/index.html
```

- `ls -la` — pastikan file sudah berhasil dikirim via SCP
- `cat` — cek isi file HTML yang diupload
- `chmod 644` — pastikan izin file memungkinkan Apache membacanya

### Verifikasi via browser

Buka browser di Debian Desktop, akses:

- `http://NAMASEKOLAH.lan`
- `http://www.NAMASEKOLAH.lan`

Halaman web harus menampilkan konten file HTML yang diupload.

---

## Tugas 5 — Mail Server

**Tujuan:**
Server menerima dan mengirim email untuk domain `NAMASEKOLAH.lan`.

### Instalasi Paket Mail

```bash
apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d mailutils bsd-mailx
```

> **Catatan**: Saat instalasi `postfix`, akan muncul dialog konfigurasi. Pilih **"Internet Site"** dan masukkan nama domain Anda (contoh: `lombokcyber.lan`).

### Penjelasan Komponen

- **Postfix** = Mail Transfer Agent (MTA). Bertugas mengirim dan menerima email antar server (protokol SMTP port 25).
- **Dovecot** = Mail Delivery Agent (MDA). Bertugas menyimpan email dan melayani client email (protokol IMAP port 143, POP3 port 110).
- **Maildir** = Format penyimpanan email: satu file per pesan, tersimpan di `~/Maildir/`. Lebih aman dari mbox untuk akses bersamaan.

### Langkah 1: Konfigurasi Postfix

```bash
nano /etc/postfix/main.cf
```

Cari dan ubah/tambahkan baris berikut (baris yang sudah ada cukup dimodifikasi):

```text
myhostname = mail.NAMASEKOLAH.lan
mydomain = NAMASEKOLAH.lan
myorigin = $mydomain
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, NAMASEKOLAH.lan, localhost.NAMASEKOLAH.lan, localhost
mynetworks = 127.0.0.0/8 IP_NETWORK/24
home_mailbox = Maildir/
mailbox_size_limit = 0
recipient_delimiter = +
```

- `myhostname` — nama hostname server email (FQDN)
- `mydomain` — domain yang dilayani; email dengan alamat `@NAMASEKOLAH.lan` diterima oleh server ini
- `myorigin` — gunakan `$mydomain` sebagai domain asal email yang dikirim
- `inet_interfaces = all` — dengarkan koneksi dari semua interface
- `inet_protocols = ipv4` — gunakan hanya IPv4
- `mydestination` — daftar domain yang dianggap "lokal"; email ke domain ini diterima, tidak diteruskan ke server lain
- `mynetworks` — jaringan yang diizinkan melakukan relay (mengirim email melalui server ini)
- `home_mailbox = Maildir/` — format penyimpanan email Maildir; garis miring di akhir menandakan format Maildir (bukan mbox)
- `mailbox_size_limit = 0` — ukuran maksimum mailbox per user; `0` berarti tidak terbatas
- `recipient_delimiter = +` — karakter pemisah alias untuk subaddress seperti `user+tag@domain`

**Contoh untuk lombokcyber (IP server: 10.100.100.1):**

```text
myhostname = mail.lombokcyber.lan
mydomain = lombokcyber.lan
myorigin = $mydomain
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, lombokcyber.lan, localhost.lombokcyber.lan, localhost
mynetworks = 127.0.0.0/8 10.100.100.0/24
home_mailbox = Maildir/
mailbox_size_limit = 0
recipient_delimiter = +
```

Restart Postfix:

```bash
systemctl restart postfix
systemctl status postfix
```

### Langkah 2: Konfigurasi Dovecot

Edit konfigurasi utama:

```bash
nano /etc/dovecot/dovecot.conf
```

Pastikan protokol aktif:

```text
protocols = imap pop3
```

Baris ini mengaktifkan protokol IMAP (port 143) dan POP3 (port 110).

Edit konfigurasi mail location:

```bash
nano /etc/dovecot/conf.d/10-mail.conf
```

Cari baris `mail_driver` dan `mail_path` (Debian defaults), ubah dari format mbox ke Maildir:

```text
mail_driver = maildir
mail_path = ~/Maildir
```

> **Catatan**: Dovecot 2.4 (Debian 13) menggunakan `mail_driver` + `mail_path` menggantikan `mail_location` yang dipakai versi sebelumnya. Format lama `mail_location = maildir:~/Maildir` tidak lagi dikenali.

- `mail_driver = maildir` — gunakan format Maildir (satu file per pesan), menggantikan default mbox
- `mail_path = ~/Maildir` — lokasi direktori Maildir di home directory setiap user

Edit konfigurasi autentikasi:

```bash
nano /etc/dovecot/conf.d/10-auth.conf
```

Ubah/pastikan baris berikut:

```text
disable_plaintext_auth = no
auth_mechanisms = plain login
```

- `disable_plaintext_auth = no` — izinkan autentikasi plaintext; diperlukan untuk lingkungan lab dan lomba tanpa enkripsi TLS
- `auth_mechanisms = plain login` — mekanisme autentikasi yang didukung server

Edit konfigurasi listener:

```bash
nano /etc/dovecot/conf.d/10-master.conf
```

Pastikan blok Postfix auth socket ada (untuk integrasi Postfix-Dovecot):

```text
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

- `unix_listener` — membuat socket Unix yang bisa diakses Postfix untuk memverifikasi kredensial user
- `mode = 0660` — izin file socket; hanya owner dan group yang bisa baca/tulis
- `user = postfix` / `group = postfix` — socket dimiliki oleh proses Postfix agar keduanya dapat berkomunikasi

Restart Dovecot:

```bash
systemctl restart dovecot
systemctl status dovecot
```

### Langkah 3: Buat akun email

Akun email = akun user Linux biasa. Buat dua akun:

```bash
adduser NAMAUSER
adduser NAMA_GURU
```

Buat dua akun user Linux: satu untuk peserta (`NAMAUSER`) dan satu untuk guru (`NAMA_GURU`). Masukkan password saat diminta untuk masing-masing akun.

> Setelah user login pertama kali dan ada email masuk, direktori `~/Maildir`
> akan dibuat otomatis oleh Dovecot. Untuk membuat Maildir secara manual:

```bash
maildirmake.dovecot /home/NAMAUSER/Maildir
chown -R NAMAUSER:NAMAUSER /home/NAMAUSER/Maildir
```

### Verifikasi Mail Server

```bash
ss -tlnp | grep :25
ss -tlnp | grep -E ':143|:110'
echo "Ini adalah pesan uji coba" | mail -s "Test Email" NAMAUSER@NAMASEKOLAH.lan
tail -f /var/log/mail.log
```

- `ss -tlnp | grep :25` — cek Postfix mendengarkan port 25 (SMTP)
- `ss -tlnp | grep -E ':143|:110'` — cek Dovecot mendengarkan port 143 (IMAP) dan 110 (POP3)
- `echo ... | mail` — test kirim email lokal ke akun user yang baru dibuat
- `tail -f /var/log/mail.log` — monitor log email secara real-time

---

## Tugas 6 — Uji Coba Email

### 6.1 Kirim Email via Terminal

#### Kirim email lokal (sesama user di server yang sama)

Masuk sebagai user pengirim:

```bash
su - NAMAUSER
```

Kirim email ke user lain (cara cepat):

```bash
echo "Halo NAMA_GURU, ini pesan dari NAMAUSER." | mail -s "Pesan dari NAMAUSER" NAMA_GURU@NAMASEKOLAH.lan
```

Atau cara interaktif:

```bash
mail NAMA_GURU@NAMASEKOLAH.lan
```

Setelah perintah `mail` dijalankan secara interaktif: ketik subjek lalu Enter, ketik isi pesan, kemudian akhiri dengan baris berisi titik (`.`) dan Enter. Isi `Cc:` bisa dikosongkan.

#### Baca email yang masuk

Login sebagai penerima, lalu buka inbox:

```bash
su - NAMA_GURU
mail
```

Di dalam program `mail`: tekan nomor pesan untuk membaca, `r` untuk reply, `q` untuk keluar.

#### Reply email via terminal

Di dalam program `mail` setelah membuka email, ketik nomor pesan (contoh: `1`) lalu ketik `r`. Subject akan terisi otomatis dengan prefix `Re:`. Ketik balasan dan akhiri dengan baris berisi titik (`.`) lalu Enter.

### 6.2 Kirim Email Lintas Server

Untuk mengirim email antar server (misalnya dari `lombokcyber.lan` ke `hadiwijaya.lan`),
Postfix perlu tahu bagaimana mencapai server tujuan. Karena DNS lokal masing-masing server
tidak mengetahui domain server lain, kita gunakan **transport maps** untuk mengarahkan email
langsung ke IP server tujuan.

Lakukan langkah berikut di **kedua server**.

#### Langkah 1 — Pastikan domain sendiri ada di `mydestination`

Di masing-masing server, pastikan nama domain utama sudah ada di `mydestination` di
`/etc/postfix/main.cf`. Ini penting agar server mau menerima email dari luar yang ditujukan
ke domain sendiri:

```text
mydestination = $myhostname, NAMASEKOLAH.lan, localhost.NAMASEKOLAH.lan, localhost
```

- `$myhostname` — nama FQDN server (misal `mail.lombokcyber.lan`)
- `NAMASEKOLAH.lan` — domain utama yang diterima sebagai lokal

**Contoh untuk lombokcyber:**

```text
mydestination = $myhostname, mail.lombokcyber.lan, lombokcyber.lan, localhost.lombokcyber.lan, localhost
```

Terapkan perubahan:

```bash
postconf -e "mydestination = \$myhostname, mail.lombokcyber.lan, lombokcyber.lan, localhost.lombokcyber.lan, localhost"
systemctl restart postfix
```

#### Langkah 2 — Buat transport map di kedua server

Transport map memberitahu Postfix: "untuk email ke domain X, kirim langsung ke IP ini, bypass DNS".

**Di Server 1 (lombokcyber.lan)**, buat file `/etc/postfix/transport`:

```bash
nano /etc/postfix/transport
```

Isi file:

```text
hadiwijaya.lan   smtp:[IP_SERVER_2]
```

- `hadiwijaya.lan` — domain tujuan
- `smtp:[IP_SERVER_2]` — kirim langsung ke IP server 2 via SMTP (tanda `[ ]` berarti bypass MX lookup)

**Contoh jika IP Server 2 adalah 192.168.198.249:**

```text
hadiwijaya.lan   smtp:[192.168.198.249]
```

Kompilasi file transport dan aktifkan:

```bash
postmap /etc/postfix/transport
postconf -e "transport_maps = hash:/etc/postfix/transport"
systemctl restart postfix
```

**Di Server 2 (hadiwijaya.lan)**, buat file `/etc/postfix/transport`:

```bash
nano /etc/postfix/transport
```

Isi file:

```text
lombokcyber.lan   smtp:[IP_SERVER_1]
```

**Contoh jika IP Server 1 adalah 192.168.198.250:**

```text
lombokcyber.lan   smtp:[192.168.198.250]
```

Kompilasi dan aktifkan:

```bash
postmap /etc/postfix/transport
postconf -e "transport_maps = hash:/etc/postfix/transport"
systemctl restart postfix
```

#### Langkah 3 — Kirim email lintas server

Di Server 1, login sebagai user pengirim:

```bash
su - NAMAUSER
```

Kirim email ke user di server lain:

```bash
echo "Halo, ini pesan dari NAMAUSER@lombokcyber.lan" | \
    mail -s "Test Lintas Server" nadhila@hadiwijaya.lan
```

#### Cek log pengiriman

```bash
journalctl -u postfix -n 20
```

Cari baris yang menunjukkan `status=sent` untuk konfirmasi pengiriman berhasil. Contoh output sukses:

```text
postfix/smtp[...]: to=<nadhila@hadiwijaya.lan>, relay=192.168.198.249[192.168.198.249]:25, status=sent (250 2.0.0 Ok)
```

### 6.3 Konfigurasi Thunderbird di Desktop

#### Instalasi Thunderbird

Di Debian Desktop, jalankan sebagai root:

```bash
apt install -y thunderbird
```

#### Setup akun di Thunderbird

1. Buka Thunderbird
2. Pilih **Create a new account** → **Email**
3. Isi data:
   - **Your name**: Nama Lengkap Anda
   - **Email address**: `NAMAUSER@NAMASEKOLAH.lan`
   - **Password**: password user Linux
4. Klik **Configure manually**
5. Isi pengaturan:

| Setting | Nilai |
| ------- | ----- |
| Incoming (IMAP) Server | IP_SERVER |
| Port IMAP | 143 |
| Connection Security | None |
| Authentication | Normal password |
| Outgoing (SMTP) Server | IP_SERVER |
| Port SMTP | 25 |
| Connection Security | None |
| Authentication | Normal password |

- Klik **Done** / **Re-test**
- Jika muncul peringatan security, klik **I understand the risks** / **Confirm**

#### Kirim dan reply email via Thunderbird

1. Klik **Write** untuk email baru
2. Isi **To**, **Subject**, dan isi pesan
3. Klik **Send**
4. Untuk reply: klik email yang masuk → klik **Reply**

---

## Ringkasan Perintah Penting

| Perintah | Fungsi |
| -------- | ------ |
| `systemctl status SERVICE` | Cek status layanan |
| `systemctl restart SERVICE` | Restart layanan |
| `journalctl -u SERVICE -n 50` | Lihat log layanan |
| `named-checkconf` | Cek sintaks konfigurasi BIND |
| `named-checkzone ZONE FILE` | Cek sintaks file zone |
| `apache2ctl configtest` | Cek sintaks konfigurasi Apache |
| `dig DOMAIN` | Query DNS |
| `nslookup DOMAIN` | Query DNS (alternatif) |
| `ss -tlnp` | Lihat port yang aktif |
| `journalctl -u postfix -f` | Monitor log mail secara real-time |

---

## Troubleshooting Umum

### DHCP server gagal start

```bash
journalctl -u isc-dhcp-server -n 20
```

Periksa apakah interface di `/etc/default/isc-dhcp-server` sudah benar dan apakah ada subnet yang sesuai dengan IP interface di `dhcpd.conf`.

### DNS tidak bisa resolve

```bash
named-checkconf
named-checkzone ...
systemctl restart named
```

Pastikan `/etc/resolv.conf` mengarah ke IP server sendiri.

### Apache error 403 Forbidden

Cek dan perbaiki permission direktori:

```bash
ls -la /home/NAMAUSER/
ls -la /home/NAMAUSER/public_html/
chmod 711 /home/NAMAUSER
chmod 755 /home/NAMAUSER/public_html
chmod 644 /home/NAMAUSER/public_html/index.html
```

### Email tidak terkirim

```bash
journalctl -u postfix -n 30
```

Pastikan `mydestination` di `main.cf` mencakup nama domain sendiri (bukan hanya `$myhostname`).
Untuk email lintas server, pastikan transport map dikonfigurasi dan `postmap` sudah dijalankan
setelah edit file transport.

### Email lintas server ditolak (Relay access denied)

Server tujuan menolak email karena domain pengirim tidak dikenali sebagai lokal. Perbaiki
`mydestination` di server penerima agar mencakup domain utamanya:

```bash
postconf mydestination
postconf -e "mydestination = \$myhostname, NAMASEKOLAH.lan, localhost.NAMASEKOLAH.lan, localhost"
systemctl restart postfix
```
