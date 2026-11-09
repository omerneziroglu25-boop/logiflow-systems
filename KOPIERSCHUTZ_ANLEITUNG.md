# 🔒 LogiFlow Systems | Kopierschutz- und Lizenzierungsanleitung

Diese Anleitung erklärt, wie Sie LogiFlow Systems vor unbefugtem Kopieren und Weiterverkauf durch Kunden schützen.

---

## 🛡️ Wie funktioniert der Schutz? (Node-Locked License)

1. **Hardware-Fingerabdruck (HW-ID):** 
   Jeder Server (Dell, HP, Linux, Windows) besitzt eine unveränderliche Hardware-Kombination aus MAC-Adresse und CPU-Architektur.
2. **Kryptografische Signatur:**
   Mit Ihrem geheimen Master-Schlüssel generieren Sie für den Firmennamen des Kunden und seine spezifische Hardware-ID einen verschlüsselten Schlüssel (z.B. `LF-8A2F-9C14-3B7D`).
3. **Kopier-Sperre:**
   Kopiert der Kunde die Software-Dateien auf einen anderen Computer oder Server, stimmt der Hardware-Fingerabdruck nicht mehr mit dem Lizenzschlüssel überein. LogiFlow bricht den Start sofort mit einer Fehlermeldung ab.

---

## 🚀 Schritt-für-Schritt: Einen Neukunden lizensieren

### Schritt 1: Hardware-ID beim Kunden abfragen
Wenn der Kunde LogiFlow auf seinem Werks-Server installiert, ruft er (oder Sie während der Einrichtung) folgenden Befehl im Terminal auf:
```bash
node lizenz_manager.js
```
Der Bildschirm gibt die eindeutige ID des Kunden aus, z.B.:
`Hardware-Fingerabdruck: [ 8F2A90C1B4E8D712 ]`

### Schritt 2: Lizenzschlüssel bei Ihnen generieren
Sie tragen den Kundennamen und die Hardware-ID in Ihr Lizenz-Tool ein:
```javascript
const lizenz = generateLicenseKey("Kunde Metallbau GmbH", "8F2A90C1B4E8D712", 500, "UNBEGRENZT");
console.log(lizenz.lizenzschluessel); 
// Ausgabe: LF-4D9A-8C21-7B14
```

### Schritt 3: Auslieferung
Sie übergeben dem Kunden seinen Schlüssel. Die Software speichert diesen in der Konfigurationsdatei `.env`:
```env
LOGIFLOW_LICENSE_CUSTOMER="Kunde Metallbau GmbH"
LOGIFLOW_LICENSE_KEY="LF-4D9A-8C21-7B14"
```
Die Software läuft nun auf Lebenszeit auf diesem Server – kann aber auf keinem anderen Rechner gestartet werden.
