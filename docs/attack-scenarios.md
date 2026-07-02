# Panduan Simulasi Serangan & Validasi Log Forensik

Dokumen ini berisi instruksi lengkap untuk mengeksekusi skenario serangan dari **Kali Linux** (`192.168.169.2`) terhadap **MikroTik CHR** (`192.168.169.1`) serta cara memverifikasi indikator serangan tersebut di **SIEM Splunk**.

---

## ⚠️ PROSEDUR WAJIB: Reset State Sebelum Setiap Skenario

Mekanisme pertahanan MikroTik yang dikonfigurasi bersifat **persisten**. Jika IP Kali Linux sudah masuk ke dalam daftar pemblokiran (*Blacklist/Address-List*), maka seluruh serangan pada skenario berikutnya akan diblokir total di awal (*Walled-Off Effect*) dan tercatat sebagai log pemblokiran generik, bukan log skenario yang spesifik.

**Jalankan perintah ini di Terminal MikroTik sebelum memulai skenario baru:**

```routeros
# Membersihkan IP Kali Linux dari seluruh daftar pemblokiran firewall
/ip firewall address-list remove [find address=192.168.169.2]

```

---

## ⚔️ Eksplorasi Skenario Serangan

### Skenario 1: Port Scanning (Reconnaissance)

* **Tujuan:** Mengidentifikasi port-port yang terbuka pada target router menggunakan *SYN Stealth Scan*.
* **Perintah di Kali Linux:**
```bash
nmap -sS -p 1-1000 192.168.169.1

```


* **Indikator Keberhasilan Splunk:**
* **Query SPL:** `index=mikrotik alert_type="PORT-SCAN-DETECTED"`
* **Analisis Forensik:** Sistem *Port Scan Detection* (PSD) pada MikroTik mendeteksi pembukaan koneksi TCP yang masif dalam rentang waktu singkat, memicu penambahan IP penyerang ke *address-list* penyusup.



---

### Skenario 2: Service & OS Enumeration (Advanced Reconnaissance)

* **Tujuan:** Mendeteksi versi layanan (*banner grabbing*) dan sistem operasi yang berjalan pada target.
* **Perintah di Kali Linux:**
```bash
nmap -sV --script=banner -p 21,22,23,80 192.168.169.1

```


* **Indikator Keberhasilan Splunk:**
* **Query SPL:** `index=mikrotik alert_type="PORT-SCAN-BLOCKED"`
* **Analisis Forensik:** Jika dijalankan langsung setelah Skenario 1 tanpa melakukan reset *address-list*, paket enumerasi ini akan langsung dijatuhkan oleh aturan pemblokiran firewall dan menghasilkan *packet loss* pada sisi penyerang.



---

### Skenario 3: SSH Brute Force (Credential Access)

* **Tujuan:** Mencoba menembus hak akses administratif SSH menggunakan teknik tebakan kata sandi terstruktur (*dictionary attack*).
* **Perintah di Kali Linux:**
```bash
hydra -l admin -P /home/kali/passlist.txt ssh://192.168.169.1 -t 4 -V

```


*(Catatan: Jika ingin menguji deteksi kegagalan login sistem murni tanpa memicu pemblokiran cepat PSD, turunkan thread menjadi `-t 1`).*
* **Indikator Keberhasilan Splunk:**
* **Query SPL:** `index=mikrotik dst_port=22 ("failed" OR "SSH-BRUTEFORCE-BLOCKED")`
* **Analisis Forensik:** Splunk akan merekam eskalasi tingkatan proteksi dari `ssh_stage1` hingga `ssh_blacklist` yang memicu pemblokiran total koneksi pada port 22.



---

### Skenario 4: ICMP Flood / Ping Sweep (Denial of Service)

* TBerikut adalah draf konten lengkap dan profesional untuk file kedua Anda, yaitu **`mini-soc-project/docs/attack-scenarios.md`**. File ini dirancang khusus untuk repositori GitHub Anda dengan format Markdown yang bersih dan siap pakai.

---

# Panduan Simulasi Serangan (Attack Simulation Guide)

Dokumen ini berisi instruksi lengkap untuk mengeksekusi skenario serangan dari **Kali Linux** (`192.168.169.2`) ke target **MikroTik CHR** (`192.168.169.1`) guna menghasilkan data log yang bervariasi untuk kebutuhan analisis SIEM Splunk.

---

## ⚠️ PENTING: Aturan Utama Sebelum Memulai (*Walled-Off Effect*)

Karena firewall MikroTik dikonfigurasi dengan fitur keamanan agresif seperti **Port Scan Detection (PSD)** dan **Progressive SSH Blacklist**, IP Kali Linux Anda akan **otomatis diblokir total (Banned)** setelah meluncurkan serangan pertama.

Jika IP Anda terlanjur diblokir, serangan berikutnya tidak akan sampai ke port target dan log di Splunk akan menjadi tidak akurat.

### Perintah Reset Jaring Pengaman (Jalankan di Terminal MikroTik setiap kali akan berganti skenario):

```routeros
# Menghapus IP Kali Linux dari seluruh daftar pemblokiran firewall
/ip firewall address-list remove [find address=192.168.169.2]

```

---

## ⚔️ Eksplorasi Skenario Serangan

### 1. Port Scanning & Service Enumeration (Nmap)

Skenario ini mensimulasikan tahap pengintaian (*Reconnaissance*) di mana penyerang mencoba memetakan port terbuka dan mencari tahu versi sistem operasi target.

* **Alat yang Digunakan:** Nmap
* **Perintah Serangan:**
```bash
# Stealth SYN Scan pada 1000 port populer
nmap -sS -p 1-1000 192.168.169.1

# Service Version Detection & Banner Grabbing
nmap -sV --script=banner -p 21,22,23,80 192.168.169.1

```


* **Log Terpicu di Splunk:** `PORT-SCAN-DETECTED` dilanjutkan dengan `PORT-SCAN-BLOCKED`.

---

### 2. SSH Brute Force Attack (Hydra)

Skenario untuk menguji ketahanan autentikasi router terhadap serangan tebakan kata kunci (*password-guessing attack*) secara masif.

* **Alat yang Digunakan:** Hydra
* **Persiapan Wordlist:** Pastikan Anda telah membuat berkas password minimal di `/home/kali/passlist.txt`.
* **Perintah Serangan A (Agresif - Memicu Blacklist):**
```bash
hydra -l admin -P /home/kali/passlist.txt ssh://192.168.169.1 -t 4 -V

```


* **Perintah Serangan B (Lambat/Siluman - Memicu Log Kegagalan Login):**
*Gunakan jika ingin memaksa tebakan password masuk ke sistem SSH MikroTik tanpa terblokir di awal oleh rule PSD.*
```bash
hydra -l admin -P /home/kali/passlist.txt ssh://192.168.169.1 -t 1 -V

```


* **Log Terpicu di Splunk:** `SSH-BRUTEFORCE-DETECTED`, `SSH-BRUTEFORCE-BLOCKED`, dan log kategori `account,info` (login failure).

---

### 3. ICMP Flood / Network Denial of Service (hping3)

Simulasi serangan Dos (*Denial of Service*) menggunakan banjir paket ping (ICMP) untuk menghabiskan sumber daya *bandwidth* router.

* **Alat yang Digunakan:** hping3
* **Perintah Serangan:**
```bash
# Mengirimkan paket ICMP flood dengan batas waktu otomatis 15 detik
sudo timeout 15 hping3 --icmp --flood 192.168.169.1

```


* **Uji Coba Tambahan (Ping Sweep):**
```bash
# Memetakan host aktif di seluruh subnet jaringan
nmap -sn 192.168.169.0/24

```


* **Log Terpicu di Splunk:** `ICMP-FLOOD-DETECTED`.

---

### 4. Network Policy & Firewall Violations (Netcat)

Skenario pelanggaran kebijakan (*policy violation*) di mana penyerang mencoba mengakses port layanan manajemen internal yang sengaja ditutup/dinonaktifkan oleh Administrator jaringan.

* **Alat yang Digunakan:** Netcat (`nc`)
* **Perintah Serangan:**
```bash
# Mencoba koneksi ke port Telnet (23)
nc -vz 192.168.169.1 23

# Mencoba koneksi ke port FTP (21)
nc -vz 192.168.169.1 21

# Mencoba koneksi ke port HTTP/WWW (80)
nc -vz 192.168.169.1 80

# Mencoba koneksi ke port API MikroTik (8728)
nc -vz 192.168.169.1 8728

# Mencoba koneksi ke port Winbox (8291)
nc -vz 192.168.169.1 8291

```


* **Log Terpicu di Splunk:** `FW-VIOLATION-TELNET`, `FW-VIOLATION-FTP`, `FW-VIOLATION-WWW`, `FW-VIOLATION-API`, dan `FW-VIOLATION-WINBOX`.

---

### 5. SYN Flood DoS Attack (hping3)

Serangan DoS pada layer transport yang membanjiri port SSH target dengan paket `SYN` tanpa menyelesaikan jabat tangan tiga arah (*3-way handshake*).

* **Alat yang Digunakan:** hping3
* **Perintah Serangan:**
```bash
# Membanjiri port 22 dengan bendera SYN selama 20 detik
sudo timeout 20 hping3 -S -p 22 --flood 192.168.169.1

```


* **Log Terpicu di Splunk:** Volume tinggi pada `SSH-BRUTEFORCE-BLOCKED` atau dialirkan menuju `FW-DEFAULT-DROP`.

---

### 6. Skenario Khusus: *Possible Account Compromise*

Skenario tingkat lanjut untuk menguji kecerdasan korelasi alert SIEM Splunk dalam mendeteksi situasi di mana penyerang pada akhirnya **berhasil menebak password** setelah melakukan banyak percobaan gagal.

* **Alat yang Digunakan:** Terminal / SSH client bawaan Kali Linux
* **Langkah Eksekusi:**
1. Jalankan perintah login SSH ke router: `ssh admin@192.168.169.1`
2. Sengaja masukkan **password salah sebanyak 3 kali berturut-turut** hingga koneksi terputus.
3. Jalankan kembali perintah login: `ssh admin@192.168.169.1`
4. Masukkan **password asli router yang benar** hingga Anda berhasil masuk ke prompt internal MikroTik.


* **Log Terpicu di Splunk:** Kombinasi log berurutan `login failure` $\rightarrow$ `login failure` $\rightarrow$ `logged in`. Kondisi ini akan memicu status **`ALERT-CRITICAL`** pada SIEM.

---

## 📈 Metodologi Pencatatan Waktu (Penting untuk Laporan UAS)

Setiap kali Anda mengeksekusi salah satu perintah serangan di atas, sangat disarankan untuk mencatat waktu eksekusi pada tabel berikut demi akurasi pengisian Bab **Detail Insiden per Skenario** pada laporan akhir:

| No | Nama Skenario Serangan | Waktu Mulai (HH:MM:SS) | Waktu Selesai (HH:MM:SS) | Status di Splunk (Terbaca/Tidak) |
| --- | --- | --- | --- | --- |
| 1 | Port Scanning (Nmap) |  |  |  |
| 2 | SSH Brute Force (Hydra) |  |  |  |
| 3 | ICMP Flood (hping3) |  |  |  |
| 4 | Firewall Policy Violation |  |  |  |
| 5 | SYN Flood Attack |  |  |  |
| 6 | Account Compromise Test |  |  |  |
