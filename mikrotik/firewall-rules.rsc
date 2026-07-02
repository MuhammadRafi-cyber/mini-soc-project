#===================================================================
# CONFIGURASI FIREWALL RULES FOR MINI SOC LAB (PRODUCTION URUTAN FINAL)
#===================================================================

/ip firewall filter
add chain=input connection-state=established,related action=accept comment="0. Allow established/related"
add chain=input connection-state=invalid action=drop comment="1. Drop invalid"

# ICMP Proteksi & Deteksi (Dipindah ke atas agar tidak terintercept PSD)
add chain=input protocol=icmp limit=1,1:packet action=accept comment="2. Allow limited icmp (Super Sensitive for Lab)"
add chain=input protocol=icmp action=drop log=yes log-prefix="ICMP-FLOOD-DETECTED" comment="3. Drop excess ICMP"

# Port Scan Detection (PSD)
add chain=input protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list address-list=port_scanners address-list-timeout=1d log=yes log-prefix="PORT-SCAN-DETECTED" comment="4. Detect port scan"
add chain=input src-address-list=port_scanners action=drop log=yes log-prefix="PORT-SCAN-BLOCKED" comment="5. Block detected scanners"

# SSH Brute Force Detection Chain Jump
add chain=input protocol=tcp dst-port=22 connection-state=new action=jump jump-target=ssh-brute comment="6. Jump to ssh brute force detection"

# SSH Brute Force Progressive Blacklist Chain
add chain=ssh-brute protocol=tcp src-address-list=ssh_blacklist action=drop log=yes log-prefix="SSH-BRUTEFORCE-BLOCKED"
add chain=ssh-brute protocol=tcp src-address-list=ssh_stage3 action=add-src-to-address-list address-list=ssh_blacklist address-list-timeout=15m log=yes log-prefix="SSH-BRUTEFORCE-DETECTED"
add chain=ssh-brute protocol=tcp src-address-list=ssh_stage2 action=add-src-to-address-list address-list=ssh_stage3 address-list-timeout=5m
add chain=ssh-brute protocol=tcp src-address-list=ssh_stage1 action=add-src-to-address-list address-list=ssh_stage2 address-list-timeout=5m
add chain=ssh-brute protocol=tcp action=add-src-to-address-list address-list=ssh_stage1 address-list-timeout=5m

# Policy Violations (Disabled/Unauthorized Services)
add chain=input protocol=tcp dst-port=23 action=drop log=yes log-prefix="FW-VIOLATION-TELNET" comment="12. Telnet not allowed"
add chain=input protocol=tcp dst-port=21 action=drop log=yes log-prefix="FW-VIOLATION-FTP" comment="13. FTP not allowed"
add chain=input protocol=tcp dst-port=80 action=drop log=yes log-prefix="FW-VIOLATION-WWW" comment="14. WWW not allowed"
add chain=input protocol=tcp dst-port=8728 action=drop log=yes log-prefix="FW-VIOLATION-API" comment="15. API not allowed"
add chain=input protocol=tcp dst-port=8291 action=drop log=yes log-prefix="FW-VIOLATION-WINBOX" comment="16. Winbox external not allowed"

# Default Policy Policy (Catch-All)
add chain=input action=drop log=yes log-prefix="FW-DEFAULT-DROP" comment="17. Default Drop - Log everything else"
