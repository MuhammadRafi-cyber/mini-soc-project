# ⚙️ Definisi Search Macro: `get_severity`

Berkas ini mendokumentasikan konfigurasi **Search Macro** bernama `get_severity` pada SIEM Splunk Enterprise. Macro ini berfungsi sebagai mesin pemroses (*processing engine*) modular yang dapat dipanggil secara instan di berbagai panel dashboard maupun aturan alert untuk mengklasifikasikan tingkat bahaya (*Severity*) dan menghitung nilai risiko (*Risk Score*) secara dinamis.

---

## 📌 1. Ringkasan Properti Macro

| Properti | Nilai Konfigurasi | Catatan Implementasi |
| --- | --- | --- |
| **Destination App** | `search` (Search & Reporting) | Agar dapat diakses di lingkungan pencarian utama. |
| **Macro Name** | `get_severity` | Ditulis tanpa tanda kurung dan bersifat *case-sensitive*. |
| **Arguments** | *Kosongkan (None)* | Tidak membutuhkan parameter input tambahan. |
| **Sharing / Permissions** | `All apps (Global)` | `Everyone: Read` | Wajib diatur agar panel dashboard xml dapat mengeksekusi rumus ini. |

---

## 💻 2. Rumus Kode SPL (Definition)

Salin blok kode SPL di bawah ini secara utuh dan masukkan ke dalam kolom **Definition** pada saat pembuatan macro di Splunk:

```spl
eval severity=case(
    alert_type=="PORT-SCAN-DETECTED", "Low",
    alert_type=="PORT-SCAN-BLOCKED", "Low",
    alert_type=="FW-DEFAULT-DROP", "Low",
    alert_type=="ICMP-FLOOD-DETECTED", "Medium",
    alert_type=="FW-VIOLATION-TELNET", "Medium",
    alert_type=="FW-VIOLATION-FTP", "Medium",
    alert_type=="FW-VIOLATION-WWW", "Medium",
    alert_type=="FW-VIOLATION-API", "Medium",
    alert_type=="FW-VIOLATION-WINBOX", "Medium",
    alert_type=="SSH-BRUTEFORCE-DETECTED", "Medium",
    alert_type=="SSH-BRUTEFORCE-BLOCKED", "High",
    1==1, "Low"
) 
| eval risk_score=case(
    alert_type=="FW-DEFAULT-DROP", 1,
    alert_type=="PORT-SCAN-DETECTED", 2,
    alert_type=="PORT-SCAN-BLOCKED", 3,
    alert_type=="ICMP-FLOOD-DETECTED", 5,
    alert_type=="FW-VIOLATION-TELNET", 5,
    alert_type=="FW-VIOLATION-FTP", 5,
    alert_type=="FW-VIOLATION-WWW", 5,
    alert_type=="FW-VIOLATION-API", 5,
    alert_type=="FW-VIOLATION-WINBOX", 5,
    alert_type=="SSH-BRUTEFORCE-DETECTED", 6,
    alert_type=="SSH-BRUTEFORCE-BLOCKED", 8,
    1==1, 1
)

```

---

## 🛠️ 3. Langkah Konfigurasi di Splunk GUI

Untuk menerapkan macro ini pada server Splunk Enterprise Anda, ikuti prosedur standar berikut:

1. Buka **Splunk Web**, masuk dengan akun Administrator.
2. Pada bilah menu kanan atas, klik **Settings** $\rightarrow$ **Advanced search**.
3. Pilih menu **Search macros**, lalu klik tombol hijau **New Search Macro** di pojok kanan atas.
4. Isi formulir pembuatan dengan spesifikasi sebagai berikut:
* **Destination app:** `search`
* **Name:** `get_severity`
* **Definition:** *Paste* seluruh blok kode SPL yang ada pada **Bagian 2** di atas.
* **Arguments:** Biarkan kosong total (jangan diisi karakter apa pun).


5. Klik **Save**.
6. **Mengatur Hak Akses (Krusial):** Kembali ke daftar macro, cari `get_severity` $\rightarrow$ Klik **Permissions** pada kolom *Actions*.
* Ubah *Object should appear in* menjadi **All apps (system)**.
* Pastikan kotak centang **Read** untuk peran *Everyone* telah aktif.
* Klik **Save**.



---

## 🔎 4. Panduan & Contoh Penggunaan dalam Pencarian (SPL)

Di dalam Splunk, sebuah search macro wajib dipanggil menggunakan karakter **backtick (`)**, bukan tanda kutip tunggal. Karakter backtick biasanya terletak di sebelah kiri angka 1 pada papan ketik (*keyboard*).

### Contoh A: Pemanggilan Dasar untuk Rekap Data Matrix

```spl
index=mikrotik alert_type=*
| `get_severity`
| table _time, src_ip, alert_type, severity, risk_score

```

### Contoh B: Pengujian Integritas Komponen (Sanity Check Tanpa Log Asli)

Jika Anda ingin memastikan apakah macro ini sudah tersimpan dan dapat memproses data logika dengan benar tanpa bergantung pada aliran log MikroTik, jalankan skrip simulasi statis ini pada search bar:

```spl
| makeresults
| eval alert_type="SSH-BRUTEFORCE-BLOCKED"
| `get_severity`
| table alert_type, severity, risk_score

```

> 💡 **Hasil yang Diharapkan:** Splunk akan memunculkan satu baris tabel tiruan yang secara otomatis terisi dengan nilai `severity = High` dan `risk_score = 8`. Jika baris ini muncul, maka arsitektur analisis berbasis risiko Anda telah aktif 100%.
