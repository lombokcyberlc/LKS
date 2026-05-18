# Referensi Perintah Email — LKS SMK TKJ

Dokumen ini berisi semua perintah yang diperlukan untuk mengirim, menerima,
dan membalas email dalam konteks lomba.

---

## Skenario Simulasi

| Server | Domain | IP LAN | Akun Email |
| --- | --- | --- | --- |
| Server 1 | lombokcyber.lan | 10.100.100.1 | `hadi@lombokcyber.lan`, `guru@lombokcyber.lan` |
| Server 2 | hadiwijaya.lan | 10.200.200.1 | `matni@hadiwijaya.lan`, `nadhila@hadiwijaya.lan` |
| PC 1 | — | DHCP dari Server 1 | client Thunderbird untuk Server 1 |
| PC 2 | — | DHCP dari Server 2 | client Thunderbird untuk Server 2 |

---

## 1. Persiapan: Pastikan Akun User Ada

```bash
# Di Server 1 — buat akun jika belum ada
adduser hadi
adduser guru

# Di Server 2 — buat akun jika belum ada
adduser matni
adduser nadhila
```

---

## 2. Kirim Email Lokal (Sesama Server yang Sama)

### 2.1 Cara singkat (non-interaktif)

```bash
# Login sebagai hadi
su - hadi

# Kirim email ke guru (di server yang sama)
echo "Halo Guru, ini pesan dari Hadi." | mail -s "Salam dari Hadi" guru@lombokcyber.lan
```

### 2.2 Cara interaktif

```bash
su - hadi

mail guru@lombokcyber.lan
# Tekan Enter setelah perintah di atas
# Prompt akan muncul:
# Subject: [ketik subjek, lalu Enter]
# [ketik isi pesan, bisa beberapa baris]
# [untuk mengakhiri: tekan Enter, lalu ketik titik (.) dan Enter]
# Cc: [kosongkan, Enter]
```

**Contoh sesi interaktif:**

```text
$ mail guru@lombokcyber.lan
Subject: Pesan Pertama
Halo Guru, ini adalah email pertama dari Hadi.
Semoga kamu baik-baik saja.
.
Cc:
$
```

---

## 3. Membaca Email (Inbox)

Email disimpan di format **Maildir** (`~/Maildir/`). Gunakan opsi `-f` untuk membaca
dari Maildir, atau baca langsung via file.

### 3.1 Membuka inbox dengan `mail`

```bash
# Login sebagai penerima
su - guru

# Buka mailbox Maildir
mail -f ~/Maildir/
```

**Tampilan inbox:**

```text
Maildir mailbox "/home/guru/Maildir/": 1 message 1 new
>N  1 hadi@lombokcyber.lan  Mon May 18 10:00  14/512  "Pesan Pertama"
?
```

**Perintah di dalam `mail`:**

| Perintah | Fungsi |
| --- | --- |
| `1` (nomor) | Baca pesan nomor 1 |
| `r` | Reply ke pengirim pesan yang sedang dibuka |
| `r 1` | Reply ke pesan nomor 1 |
| `d` | Hapus pesan yang sedang dibuka |
| `d 1` | Hapus pesan nomor 1 |
| `q` | Keluar dan simpan perubahan |
| `x` | Keluar tanpa menyimpan perubahan |
| `?` | Tampilkan bantuan |

### 3.2 Cek email langsung via file (alternatif)

```bash
# Lihat daftar email masuk
ls ~/Maildir/new/

# Baca isi email
cat ~/Maildir/new/[nama-file]
```

---

## 4. Reply Email via Terminal

```bash
# Masih sebagai guru, buka inbox
mail -f ~/Maildir/

# Baca pesan nomor 1
? 1

# Balas pesan tersebut
? r
# Subject otomatis: Re: Pesan Pertama
# [ketik balasan]
# [akhiri dengan titik (.) dan Enter]
# Cc: [kosongkan, Enter]

# Keluar
? q
```

**Contoh sesi reply:**

```text
? r
To: hadi@lombokcyber.lan
Subject: Re: Pesan Pertama
Halo Hadi, terima kasih atas pesannya.
Saya baik-baik saja, terima kasih sudah bertanya.
.
Cc:
? q
```

---

## 5. Kirim Email Lintas Server

Email lintas server dirutekan menggunakan **Postfix transport maps** — koneksi langsung
ke IP WAN server tujuan, tanpa bergantung pada DNS.

### 5.1 Persiapan: Transport Map di Postfix (WAJIB di kedua server)

**Di Server 1 (lombokcyber.lan)** — buat `/etc/postfix/transport`:

```bash
nano /etc/postfix/transport
```

Isi:

```text
hadiwijaya.lan   smtp:[192.168.198.249]
```

Kompilasi dan aktifkan:

```bash
postmap /etc/postfix/transport
postconf -e "transport_maps = hash:/etc/postfix/transport"
postconf -e "mydestination = \$myhostname, lombokcyber.lan, localhost.lombokcyber.lan, localhost"
systemctl restart postfix
```

**Di Server 2 (hadiwijaya.lan)** — buat `/etc/postfix/transport`:

```bash
nano /etc/postfix/transport
```

Isi:

```text
lombokcyber.lan   smtp:[192.168.198.250]
```

Kompilasi dan aktifkan:

```bash
postmap /etc/postfix/transport
postconf -e "transport_maps = hash:/etc/postfix/transport"
postconf -e "mydestination = \$myhostname, hadiwijaya.lan, localhost.hadiwijaya.lan, localhost"
systemctl restart postfix
```

### 5.2 Kirim email dari Server 1 ke Server 2

```bash
# Di Server 1, login sebagai hadi
su - hadi

# Kirim ke nadhila di server lain
echo "Halo Nadhila, ini pesan dari Hadi di server lombokcyber.lan." | \
    mail -s "Test Lintas Server" nadhila@hadiwijaya.lan
```

### 5.3 Verifikasi pengiriman

```bash
# Di Server 1 — pantau log pengiriman
journalctl -u postfix -n 20

# Cari baris yang mengandung "status=sent" untuk konfirmasi berhasil
# Contoh log berhasil:
# postfix/smtp[...]: to=<nadhila@hadiwijaya.lan>, relay=192.168.198.249[192.168.198.249]:25, status=sent (250 2.0.0 Ok)
```

### 5.4 Baca dan reply dari Server 2

```bash
# Di Server 2, login sebagai nadhila
su - nadhila

# Buka inbox
mail -f ~/Maildir/

# Baca pesan dari hadi
? 1

# Reply
? r
Halo Hadi, saya sudah terima pesanmu dari lombokcyber.lan.
Ini adalah balasan dari nadhila@hadiwijaya.lan.
.
Cc:
? q
```

### 5.5 Verifikasi reply diterima Server 1

```bash
# Di Server 1, login sebagai hadi
su - hadi

# Buka inbox
mail -f ~/Maildir/

# Cek apakah reply dari nadhila sudah masuk
```

---

## 6. Monitoring dan Troubleshooting

### Pantau log mail secara real-time

```bash
# Di server manapun (sebagai root)
journalctl -u postfix -f
```

### Cek antrian email yang tertunda

```bash
# Lihat antrian (sebagai root)
postqueue -p

# Paksa kirim ulang antrian
postqueue -f
```

### Cek layanan berjalan

```bash
# Postfix (SMTP port 25)
systemctl status postfix
ss -tlnp | grep :25

# Dovecot (IMAP port 143, POP3 port 110)
systemctl status dovecot
ss -tlnp | grep -E ':143|:110'
```

### Tes koneksi SMTP manual (telnet)

```bash
# Test koneksi ke port 25 server lain (gunakan IP WAN)
telnet 192.168.198.249 25

# Jika koneksi berhasil, akan muncul banner seperti:
# 220 hadiwijaya.lan ESMTP Postfix (Debian/GNU)
# Ketik QUIT untuk keluar
```

### Cek mailbox Maildir secara langsung

```bash
# Lihat file email yang masuk (sebagai root atau pemilik akun)
ls -la /home/nadhila/Maildir/new/

# Baca isi file email
cat /home/nadhila/Maildir/new/[nama-file]
```

---

## 7. Konfigurasi Thunderbird di PC Client

### 7.1 Instalasi

```bash
# Di PC 1 atau PC 2 (sebagai root)
apt install -y thunderbird
```

### 7.2 Setup Akun — PC 1 (terhubung ke Server 1)

PC 1 mendapat IP dari Server 1 (10.100.100.x) dan dikonfigurasi untuk akun
`hadi@lombokcyber.lan` atau `guru@lombokcyber.lan`.

1. Buka **Thunderbird**
2. Pilih **Create a new account** → **Email**
3. Isi form:
   - **Your full name**: Nama lengkap Anda
   - **Email address**: `hadi@lombokcyber.lan`
   - **Password**: password user Linux `hadi`
4. Klik **Configure manually**

**Incoming Mail (IMAP):**

| Field | Nilai |
| --- | --- |
| Protocol | IMAP |
| Server hostname | `10.100.100.1` |
| Port | `143` |
| Connection security | `None` |
| Authentication method | `Normal password` |
| Username | `hadi` |

**Outgoing Mail (SMTP):**

| Field | Nilai |
| --- | --- |
| Server hostname | `10.100.100.1` |
| Port | `25` |
| Connection security | `None` |
| Authentication method | `Normal password` |
| Username | `hadi` |

Klik **Re-test** atau **Done**. Jika muncul peringatan keamanan → klik **I understand the risks** / **Confirm Security Exception**.

### 7.3 Setup Akun — PC 2 (terhubung ke Server 2)

PC 2 mendapat IP dari Server 2 (10.200.200.x) dan dikonfigurasi untuk akun
`matni@hadiwijaya.lan` atau `nadhila@hadiwijaya.lan`.

1. Buka **Thunderbird**
2. Pilih **Create a new account** → **Email**
3. Isi form:
   - **Your full name**: Nama lengkap Anda
   - **Email address**: `nadhila@hadiwijaya.lan`
   - **Password**: password user Linux `nadhila`
4. Klik **Configure manually**

**Incoming Mail (IMAP):**

| Field | Nilai |
| --- | --- |
| Protocol | IMAP |
| Server hostname | `10.200.200.1` |
| Port | `143` |
| Connection security | `None` |
| Authentication method | `Normal password` |
| Username | `nadhila` |

**Outgoing Mail (SMTP):**

| Field | Nilai |
| --- | --- |
| Server hostname | `10.200.200.1` |
| Port | `25` |
| Connection security | `None` |
| Authentication method | `Normal password` |
| Username | `nadhila` |

Klik **Re-test** atau **Done**. Jika muncul peringatan keamanan → klik **I understand the risks** / **Confirm Security Exception**.

### 7.4 Kirim Email via Thunderbird

1. Klik tombol **Write** (ikon pensil)
2. Isi:
   - **To**: alamat email tujuan (lokal atau lintas server)
   - **Subject**: judul email
   - Area isi: ketik pesan
3. Klik **Send**

### 7.5 Reply Email via Thunderbird

1. Klik email yang ingin dibalas di inbox
2. Klik tombol **Reply** (atau tekan `Ctrl+R`)
3. Alamat pengirim otomatis terisi di kolom **To**
4. Ketik balasan
5. Klik **Send**

---

## 8. Perintah Ringkas — Quick Reference

```bash
# Kirim email (1 baris)
echo "ISI PESAN" | mail -s "SUBJEK" PENERIMA@DOMAIN.LAN

# Buka inbox (Maildir format)
su - NAMAUSER
mail -f ~/Maildir/

# Baca email langsung dari file
ls ~/Maildir/new/
cat ~/Maildir/new/[nama-file]

# Monitor log real-time
journalctl -u postfix -f

# Cek port aktif
ss -tlnp | grep -E ':25|:110|:143'

# Cek antrian Postfix
postqueue -p

# Restart semua layanan mail
systemctl restart postfix dovecot
```
