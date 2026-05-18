# Lembar Penilaian Juri — LKS SMK TKJ
# Linux Server Administration (Debian 13)

**Nama Peserta** : ___________________________________
**Nama Sekolah** : ___________________________________
**Nama Guru Pendamping** : ___________________________________
**Domain** : ___________________________________.lan
**Tanggal** : ___________________________________

---

> **Sistem Penilaian**
> - Teknikal (konfigurasi berjalan): **60 poin**
> - Pemahaman (lisan + demonstrasi): **40 poin**
> - **Total: 100 poin**
>
> Kolom Status: ✓ (berhasil) / ✗ (gagal) / ½ (sebagian)

---

## BAGIAN A — PENILAIAN TEKNIKAL (60 poin)

### A1. Konfigurasi IP Address (6 poin)

| # | Item Penilaian | Poin | Status | Catatan |
|---|----------------|------|--------|---------|
| 1 | Interface `ens18` mendapat IP dari DHCP internet | 1 | | |
| 2 | Interface `ens19` memiliki IP statis sesuai ketentuan | 2 | | |
| 3 | IP forwarding aktif (`cat /proc/sys/net/ipv4/ip_forward` = 1) | 2 | | |
| 4 | Konfigurasi permanen (survive reboot) | 1 | | |

**Subtotal A1**: ___ / 6

> **Nilai Plus (Opsional)**: NAT dikonfigurasi dengan nftables sehingga client dapat akses internet — **+2 poin bonus** jika berhasil. Tidak mengurangi nilai jika tidak dikerjakan.

### A2. DHCP Server (10 poin)

| # | Item Penilaian | Poin | Status | Catatan |
|---|----------------|------|--------|---------|
| 1 | Paket `isc-dhcp-server` terinstall | 1 | | |
| 2 | Interface yang dilayani dikonfigurasi di `/etc/default/isc-dhcp-server` | 1 | | |
| 3 | Subnet, range IP, gateway dikonfigurasi dengan benar | 3 | | |
| 4 | DNS server dan domain name diberikan ke client | 2 | | |
| 5 | Layanan aktif dan berjalan (`systemctl status`) | 1 | | |
| 6 | Client mendapat IP dari DHCP (verifikasi lease atau `ip addr` di desktop) | 2 | | |

**Subtotal A2**: ___ / 10

### A3. DNS Server (15 poin)

| # | Item Penilaian | Poin | Status | Catatan |
|---|----------------|------|--------|---------|
| 1 | Paket `bind9` terinstall | 1 | | |
| 2 | `named.conf.local` mendefinisikan forward zone dengan benar | 2 | | |
| 3 | `named.conf.local` mendefinisikan reverse zone dengan benar | 2 | | |
| 4 | File forward zone: SOA, NS, A record untuk domain, www, mail | 3 | | |
| 5 | File forward zone: MX record dikonfigurasi | 1 | | |
| 6 | File reverse zone: PTR record untuk IP server | 2 | | |
| 7 | `named-checkconf` dan `named-checkzone` tanpa error | 1 | | |
| 8 | Layanan `named` aktif | 1 | | |
| 9 | `dig NAMASEKOLAH.lan` memberikan hasil yang benar | 1 | | |
| 10 | `dig -x IP_SERVER` memberikan hasil yang benar (reverse) | 1 | | |

**Subtotal A3**: ___ / 15

### A4. Web Server (12 poin)

| # | Item Penilaian | Poin | Status | Catatan |
|---|----------------|------|--------|---------|
| 1 | Paket `apache2` terinstall | 1 | | |
| 2 | User Linux dibuat, direktori `/home/NAMAUSER/public_html` ada | 1 | | |
| 3 | Permission direktori benar (711 home, 755 public_html) | 1 | | |
| 4 | VirtualHost dikonfigurasi dengan `ServerName` yang benar | 2 | | |
| 5 | `ServerAlias www.NAMASEKOLAH.lan` dikonfigurasi | 1 | | |
| 6 | `DocumentRoot` menunjuk ke `/home/NAMAUSER/public_html` | 1 | | |
| 7 | VirtualHost diaktifkan dengan `a2ensite` | 1 | | |
| 8 | `apache2ctl configtest` OK | 1 | | |
| 9 | Layanan `apache2` aktif | 1 | | |
| 10 | `http://NAMASEKOLAH.lan` dapat diakses dari desktop | 2 | | |

**Subtotal A4**: ___ / 12

### A5. Upload File via SCP (5 poin)

| # | Item Penilaian | Poin | Status | Catatan |
|---|----------------|------|--------|---------|
| 1 | File `index.html` berisi nama sekolah | 1 | | |
| 2 | File `index.html` berisi nama peserta | 1 | | |
| 3 | File `index.html` berisi nama guru pendamping | 1 | | |
| 4 | File diupload menggunakan perintah `scp` (bukan copy manual) | 1 | | |
| 5 | File tampil dengan benar di browser | 1 | | |

**Subtotal A5**: ___ / 5

### A6. Mail Server (10 poin)

| # | Item Penilaian | Poin | Status | Catatan |
|---|----------------|------|--------|---------|
| 1 | Paket `postfix` terinstall dan dikonfigurasi | 2 | | |
| 2 | `mydomain`, `myhostname`, `mydestination` dikonfigurasi benar | 1 | | |
| 3 | `home_mailbox = Maildir/` dikonfigurasi di Postfix | 1 | | |
| 4 | Paket `dovecot` terinstall (`dovecot-core`, `dovecot-imapd`, `dovecot-pop3d`) | 1 | | |
| 5 | `mail_location = maildir:~/Maildir` dikonfigurasi di Dovecot | 1 | | |
| 6 | Dua akun email (user Linux) dibuat | 1 | | |
| 7 | Layanan `postfix` aktif (port 25 terbuka) | 1 | | |
| 8 | Layanan `dovecot` aktif (port 143 dan 110 terbuka) | 1 | | |
| 9 | Email lokal dapat dikirim dan diterima (cek via `mail` atau log) | 1 | | |

**Subtotal A6**: ___ / 10

---

**TOTAL PENILAIAN TEKNIKAL (A1-A6)**: ___ / 60

---

## BAGIAN B — PENILAIAN PEMAHAMAN (40 poin)

### B1. DHCP Server (8 poin)

Juri bertanya secara lisan. Peserta menjawab dan/atau mendemonstrasikan.

| # | Pertanyaan | Poin | Nilai | Catatan |
|---|-----------|------|-------|---------|
| 1 | **Apa fungsi `authoritative` dalam `dhcpd.conf`?** *(Jawaban: Server ini dinyatakan sebagai server DHCP resmi untuk subnet tersebut. Jika ada konflik lease dari server lain, server ini yang menang.)* | 2 | | |
| 2 | **Apa perbedaan `default-lease-time` dan `max-lease-time`?** *(Jawaban: default = durasi sewa jika client tidak minta durasi spesifik; max = batas maksimum durasi sewa yang boleh diminta client.)* | 2 | | |
| 3 | **Demonstrasikan cara melihat IP yang sedang disewa oleh client.** *(Jawaban: `cat /var/lib/dhcp/dhcpd.leases`)* | 2 | | |
| 4 | **Mengapa `option domain-name-servers` diisi dengan IP server sendiri?** *(Jawaban: Karena server ini juga menjalankan DNS server (bind9), sehingga client akan menggunakan server ini untuk resolusi nama domain.)* | 2 | | |

**Subtotal B1**: ___ / 8

### B2. DNS Server (12 poin)

| # | Pertanyaan | Poin | Nilai | Catatan |
|---|-----------|------|-------|---------|
| 1 | **Jelaskan apa itu SOA record dan mengapa wajib ada di setiap file zone.** *(Jawaban: Start of Authority — mendeklarasikan server DNS yang paling otoritatif untuk zone tersebut, berisi parameter sinkronisasi untuk secondary DNS, dan wajib ada sebagai record pertama di setiap zone file.)* | 3 | | |
| 2 | **Jelaskan fungsi nilai Refresh, Retry, dan Expire di SOA.** *(Jawaban: Refresh=seberapa sering secondary DNS cek ke primary; Retry=jika refresh gagal, tunggu berapa lama sebelum coba lagi; Expire=jika primary terus tidak bisa dicapai, secondary masih melayani data sampai waktu ini habis, setelah itu dianggap kadaluarsa.)* | 3 | | |
| 3 | **Apa perbedaan A record dan PTR record?** *(Jawaban: A record = forward, mengubah nama domain → IP; PTR record = reverse, mengubah IP → nama domain. PTR ada di reverse zone.)* | 2 | | |
| 4 | **Demonstrasikan cara cek apakah DNS server berjalan dan menjawab query dengan benar.** *(Jawaban: `dig NAMASEKOLAH.lan`, `dig -x IP_SERVER`, `named-checkconf`)* | 2 | | |
| 5 | **Apa fungsi MX record dan mengapa angka prioritas itu penting?** *(Jawaban: MX record mendaftarkan mail server untuk domain. Angka kecil = prioritas lebih tinggi. Jika ada beberapa MX, email dikirim ke yang prioritasnya paling tinggi dulu.)* | 2 | | |

**Subtotal B2**: ___ / 12

### B3. Web Server (10 poin)

| # | Pertanyaan | Poin | Nilai | Catatan |
|---|-----------|------|-------|---------|
| 1 | **Apa fungsi `ServerAlias` di konfigurasi VirtualHost?** *(Jawaban: Mendefinisikan nama domain tambahan yang juga dilayani VirtualHost ini. Contoh: `www.NAMASEKOLAH.lan` adalah alias dari `NAMASEKOLAH.lan`.)* | 2 | | |
| 2 | **Mengapa permission direktori home harus 711, bukan 755 atau 700?** *(Jawaban: 711 = owner rwx, group x, other x. Apache perlu bisa masuk (execute) ke direktori home untuk membaca public_html. 755 juga benar tapi kurang aman. 700 akan block Apache karena Apache tidak bisa execute direktori.)* | 3 | | |
| 3 | **Demonstrasikan cara memeriksa error Apache dan melihat siapa yang mengakses web.** *(Jawaban: `tail /var/log/apache2/NAMASEKOLAH.lan-error.log` dan `tail /var/log/apache2/NAMASEKOLAH.lan-access.log`)* | 2 | | |
| 4 | **Apa perintah untuk mengaktifkan/menonaktifkan VirtualHost di Apache?** *(Jawaban: `a2ensite namafile.conf` untuk aktifkan, `a2dissite namafile.conf` untuk nonaktifkan, diikuti `systemctl reload apache2`)* | 3 | | |

**Subtotal B3**: ___ / 10

### B4. Mail Server (10 poin)

| # | Pertanyaan | Poin | Nilai | Catatan |
|---|-----------|------|-------|---------|
| 1 | **Apa perbedaan Postfix dan Dovecot dalam sistem email?** *(Jawaban: Postfix = MTA (Mail Transfer Agent), bertugas mengirim dan menerima email antar server via SMTP port 25. Dovecot = MDA (Mail Delivery Agent), bertugas menyimpan email dan melayani client via IMAP/POP3.)* | 3 | | |
| 2 | **Jelaskan perbedaan format Maildir dan mbox. Mengapa kita menggunakan Maildir?** *(Jawaban: mbox = semua email dalam satu file, rentan korupsi jika ada concurrent access. Maildir = satu file per pesan dalam direktori, lebih aman untuk IMAP karena multiple client bisa akses bersamaan tanpa locking.)* | 3 | | |
| 3 | **Demonstrasikan cara mengirim email dari terminal dan cara membaca inbox.** *(Jawaban: `echo "pesan" | mail -s "subjek" user@domain.lan` untuk kirim; `mail` untuk buka inbox; nomor pesan untuk baca; `q` untuk keluar.)* | 2 | | |
| 4 | **Di mana Anda bisa melihat log untuk troubleshoot masalah pengiriman email?** *(Jawaban: `/var/log/mail.log` — berisi semua aktivitas Postfix dan Dovecot. Cari kata `status=sent`, `status=bounced`, atau error message.)* | 2 | | |

**Subtotal B4**: ___ / 10

---

**TOTAL PENILAIAN PEMAHAMAN (B1-B4)**: ___ / 40

---

## REKAP NILAI AKHIR

| Bagian | Nilai | Maksimal |
|--------|-------|---------|
| A1 — IP Address | | 6 |
| A2 — DHCP Server | | 10 |
| A3 — DNS Server | | 15 |
| A4 — Web Server | | 12 |
| A5 — SCP Upload | | 5 |
| A6 — Mail Server | | 10 |
| **Total Teknikal** | | **58** |
| B1 — Pemahaman DHCP | | 8 |
| B2 — Pemahaman DNS | | 12 |
| B3 — Pemahaman Web | | 10 |
| B4 — Pemahaman Mail | | 10 |
| **Total Pemahaman** | | **40** |
| **NILAI AKHIR** | | **98** |
| *Bonus — NAT (opsional)* | | *+2* |
| ***NILAI AKHIR + BONUS*** | | ***100*** |

---

## Catatan Juri

```
______________________________________________________________
______________________________________________________________
______________________________________________________________
______________________________________________________________
______________________________________________________________
```

**Tanda Tangan Juri**: ___________________________
**Tanggal**: ___________________________
