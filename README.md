# LKS SMK TKJ — Materi Lomba Administrasi Jaringan Linux

Repositori ini berisi panduan, template konfigurasi, dan lembar penilaian untuk lomba
**LKS SMK bidang Teknologi Komputer dan Jaringan (TKJ)** dengan tema Linux Server Administration berbasis **Debian 13**.

---

## Peserta Lomba

| No | Sekolah | Domain | IP Server (LAN) |
| --- | --- | --- | --- |
| 1 | SMKN 7 Mataram | smkn7mataram.lan | 10.1.1.1/24 |
| 2 | SMKN 1 Masbagik | smkn1masbagik.lan | 10.2.2.1/24 |
| 3 | SMKN 1 Dompu | smkn1dompu.lan | 10.3.3.1/24 |

---

## Mata Lomba

1. Konfigurasi IP Address & IP Forwarding
2. DHCP Server (`isc-dhcp-server`)
3. DNS Server (`bind9`)
4. Web Server (`apache2` + VirtualHost)
5. Upload file via SCP
6. Mail Server (`postfix` + `dovecot`)
7. Pengujian Email (terminal + Thunderbird)

---

## Isi Repositori

```
.
├── README.md                  — dokumen ini
├── PANDUAN.md                 — panduan setup step-by-step untuk peserta
├── PENILAIAN.md               — lembar checklist penilaian untuk juri
├── PENILAIAN.pdf              — versi PDF lembar penilaian
├── EMAIL-COMMANDS.md          — referensi perintah kirim & reply email
├── verify.sh                  — script verifikasi semua layanan
├── .gitignore
└── templates/                 — template konfigurasi (path mengikuti lokasi real di server)
    ├── etc/
    │   ├── hosts                                   — pemetaan hostname ke IP + routing lintas server
    │   ├── resolv.conf                             — DNS resolver (arahkan ke server sendiri)
    │   ├── network/
    │   │   └── interfaces                          — konfigurasi IP ens18 & ens19
    │   ├── default/
    │   │   └── isc-dhcp-server                     — interface yang dilayani DHCP
    │   ├── dhcp/
    │   │   └── dhcpd.conf                          — subnet, range, gateway, DNS
    │   ├── bind/
    │   │   ├── named.conf.local                    — deklarasi forward & reverse zone
    │   │   └── zones/
    │   │       ├── db.namasekolah.lan              — forward zone (SOA, NS, A, MX)
    │   │       └── db.IP_NETWORK                   — reverse zone (SOA, NS, PTR)
    │   ├── apache2/
    │   │   └── sites-available/
    │   │       └── namasekolah.lan.conf            — VirtualHost port 80
    │   ├── postfix/
    │   │   ├── main.cf                             — konfigurasi Postfix (MTA)
    │   │   └── transport                           — routing email lintas server
    │   └── dovecot/
    │       ├── dovecot.conf                        — aktifkan protokol imap pop3
    │       └── conf.d/
    │           ├── 10-mail.conf                    — format Maildir (mail_driver + mail_path)
    │           └── 10-auth.conf                    — izinkan plaintext auth
    └── home/
        └── namauser/
            └── public_html/
                └── index.html                      — template halaman web peserta
```

---

## Cara Menggunakan Template

Template menggunakan placeholder yang harus diganti sesuai data sekolah masing-masing:

| Placeholder | Ganti dengan | Contoh |
| --- | --- | --- |
| `NAMASEKOLAH` | Nama domain sekolah | `lombokcyber` |
| `IP_SERVER` | IP server pada interface LAN | `10.100.100.1` |
| `IP_NETWORK` | Tiga oktet pertama IP (nama file reverse zone) | `10.100.100` |
| `IP_RANGE_START` | IP awal pool DHCP | `10.100.100.100` |
| `IP_RANGE_END` | IP akhir pool DHCP | `10.100.100.200` |
| `IP_BROADCAST` | Broadcast address | `10.100.100.255` |
| `IP_REVERSE_OCTET` | Oktet ketiga IP (untuk nama reverse zone) | `100` |
| `IP_REVERSE_OCTET2` | Oktet kedua IP | `100` |
| `IP_REVERSE_OCTET3` | Oktet pertama IP | `10` |
| `IP_LAST` | Oktet terakhir IP server (PTR record) | `1` |
| `NAMAUSER` | Username peserta | `peserta` |
| `NAMA_GURU` | Username guru pendamping | `gurukomputer` |
| `DOMAIN_LAIN` | Domain server peserta lain (transport) | `hadiwijaya.lan` |
| `IP_SERVER_LAIN` | IP WAN server peserta lain (transport) | `192.168.198.249` |

### Contoh penggantian dengan `sed`:
```bash
# Ganti semua placeholder sekaligus (sesuaikan nilai dengan data sekolah Anda)
sed -i 's/NAMASEKOLAH/lombokcyber/g; s/IP_SERVER/10.100.100.1/g' /etc/dhcp/dhcpd.conf
```

---

## Soal Lomba

### Ketentuan Umum

- Sistem operasi: **Debian 13 (Trixie)**
- Setiap peserta mengonfigurasi satu VM server dengan **dua interface jaringan**:
  - `ens18` — terhubung ke internet, mendapat IP via DHCP
  - `ens19` — terhubung ke client/desktop, IP statis sesuai tabel di bawah
- Seluruh konfigurasi dilakukan sebagai **root**
- Waktu pengerjaan: **180 menit**
- Penilaian: verifikasi teknikal oleh juri + tanya jawab lisan

---

### Peserta 1 — SMKN 7 Mataram

#### Spesifikasi Jaringan

| Parameter | Nilai |
| --- | --- |
| Domain | `smkn7mataram.lan` |
| Hostname server | `mail.smkn7mataram.lan` |
| IP server LAN (ens19) | `10.1.1.1/24` |
| Gateway client | `10.1.1.1` |
| DHCP range | `10.1.1.100` — `10.1.1.200` |
| DNS server | `10.1.1.1` |
| Reverse zone | `1.1.10.in-addr.arpa` (file: `db.10.1.1`) |

#### Akun yang Harus Dibuat

| Username | Peran | Email |
| --- | --- | --- |
| `peserta` | Peserta (web + email) | `peserta@smkn7mataram.lan` |
| `guru` | Guru pendamping | `guru@smkn7mataram.lan` |

#### Tugas yang Harus Dikerjakan

1. **Konfigurasi IP Address** — set IP statis `10.1.1.1/24` pada `ens19`, aktifkan IP forwarding
2. **DHCP Server** — layani jaringan `10.1.1.0/24`, range `10.1.1.100–200`, DNS `10.1.1.1`
3. **DNS Server** — forward zone `smkn7mataram.lan` (A, MX, NS, www), reverse zone `1.1.10.in-addr.arpa`
4. **Web Server** — VirtualHost `smkn7mataram.lan` dan `www.smkn7mataram.lan`, DocumentRoot `/home/peserta/public_html`
5. **Upload HTML** — upload `index.html` via SCP dari client ke server, pindahkan ke DocumentRoot
6. **Mail Server** — Postfix + Dovecot, format Maildir, buat akun `peserta` dan `guru`
7. **Uji Email** — kirim dan reply email antar `peserta` ↔ `guru` via terminal, demo via Thunderbird

---

### Peserta 2 — SMKN 1 Masbagik

#### Spesifikasi Jaringan

| Parameter | Nilai |
| --- | --- |
| Domain | `smkn1masbagik.lan` |
| Hostname server | `mail.smkn1masbagik.lan` |
| IP server LAN (ens19) | `10.2.2.1/24` |
| Gateway client | `10.2.2.1` |
| DHCP range | `10.2.2.100` — `10.2.2.200` |
| DNS server | `10.2.2.1` |
| Reverse zone | `2.2.10.in-addr.arpa` (file: `db.10.2.2`) |

#### Akun yang Harus Dibuat

| Username | Peran | Email |
| --- | --- | --- |
| `peserta` | Peserta (web + email) | `peserta@smkn1masbagik.lan` |
| `guru` | Guru pendamping | `guru@smkn1masbagik.lan` |

#### Tugas yang Harus Dikerjakan

1. **Konfigurasi IP Address** — set IP statis `10.2.2.1/24` pada `ens19`, aktifkan IP forwarding
2. **DHCP Server** — layani jaringan `10.2.2.0/24`, range `10.2.2.100–200`, DNS `10.2.2.1`
3. **DNS Server** — forward zone `smkn1masbagik.lan` (A, MX, NS, www), reverse zone `2.2.10.in-addr.arpa`
4. **Web Server** — VirtualHost `smkn1masbagik.lan` dan `www.smkn1masbagik.lan`, DocumentRoot `/home/peserta/public_html`
5. **Upload HTML** — upload `index.html` via SCP dari client ke server, pindahkan ke DocumentRoot
6. **Mail Server** — Postfix + Dovecot, format Maildir, buat akun `peserta` dan `guru`
7. **Uji Email** — kirim dan reply email antar `peserta` ↔ `guru` via terminal, demo via Thunderbird

---

### Peserta 3 — SMKN 1 Dompu

#### Spesifikasi Jaringan

| Parameter | Nilai |
| --- | --- |
| Domain | `smkn1dompu.lan` |
| Hostname server | `mail.smkn1dompu.lan` |
| IP server LAN (ens19) | `10.3.3.1/24` |
| Gateway client | `10.3.3.1` |
| DHCP range | `10.3.3.100` — `10.3.3.200` |
| DNS server | `10.3.3.1` |
| Reverse zone | `3.3.10.in-addr.arpa` (file: `db.10.3.3`) |

#### Akun yang Harus Dibuat

| Username | Peran | Email |
| --- | --- | --- |
| `peserta` | Peserta (web + email) | `peserta@smkn1dompu.lan` |
| `guru` | Guru pendamping | `guru@smkn1dompu.lan` |

#### Tugas yang Harus Dikerjakan

1. **Konfigurasi IP Address** — set IP statis `10.3.3.1/24` pada `ens19`, aktifkan IP forwarding
2. **DHCP Server** — layani jaringan `10.3.3.0/24`, range `10.3.3.100–200`, DNS `10.3.3.1`
3. **DNS Server** — forward zone `smkn1dompu.lan` (A, MX, NS, www), reverse zone `3.3.10.in-addr.arpa`
4. **Web Server** — VirtualHost `smkn1dompu.lan` dan `www.smkn1dompu.lan`, DocumentRoot `/home/peserta/public_html`
5. **Upload HTML** — upload `index.html` via SCP dari client ke server, pindahkan ke DocumentRoot
6. **Mail Server** — Postfix + Dovecot, format Maildir, buat akun `peserta` dan `guru`
7. **Uji Email** — kirim dan reply email antar `peserta` ↔ `guru` via terminal, demo via Thunderbird

---

## Topologi Jaringan

```
Internet (10.10.10.0/24 — GW: 10.10.10.1)
         |
      Switch
         |
  Windows Host
         |
      VMware
      /      \
 Debian 13   Debian 13
  Server      Desktop
 (bridge)    (internal)
```

- **ens18** — interface ke internet (DHCP dari ISP/switch)
- **ens19** — interface ke client/desktop (IP statis, gateway jaringan internal)

---

## Tentang Penulis / Juri

| Field | Info |
| --- | --- |
| **Nama** | Hadiwijaya |
| **Email** | `hadi@rinjani.net.id` |
| **Email** | `hadi@lombokcyber.or.id` |
| **Peran** | Juri & Penyusun Materi LKS SMK TKJ |

Untuk pertanyaan teknis seputar materi ini, hubungi juri melalui email di atas
atau sampaikan langsung kepada pengawas ruangan selama pelaksanaan lomba.
