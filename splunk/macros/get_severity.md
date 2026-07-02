# Splunk Search Macro: `get_severity`

### Definition:
```spl
eval severity=case(alert_type=="PORT-SCAN-DETECTED", "Low", alert_type=="PORT-SCAN-BLOCKED", "Low", alert_type=="FW-DEFAULT-DROP", "Low", alert_type=="ICMP-FLOOD-DETECTED", "Medium", alert_type=="FW-VIOLATION-TELNET", "Medium", alert_type=="FW-VIOLATION-FTP", "Medium", alert_type=="FW-VIOLATION-WWW", "Medium", alert_type=="FW-VIOLATION-API", "Medium", alert_type=="FW-VIOLATION-WINBOX", "Medium", alert_type=="SSH-BRUTEFORCE-DETECTED", "Medium", alert_type=="SSH-BRUTEFORCE-BLOCKED", "High", 1==1, "Low") | eval risk_score=case(severity=="Low", 2, severity=="Medium", 5, severity=="High", 8, severity=="Critical", 10, 1==1, 1)
