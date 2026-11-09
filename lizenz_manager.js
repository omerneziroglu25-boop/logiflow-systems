/**
 * ==============================================================================
 * LOGIFLOW SYSTEMS - ENTERPRISE LIZENZ- & KOPIERSCHUTZ-MANAGER
 * Kryptografische Hardware-Bindung (Node-Locked License) & Anti-Tamper
 * ==============================================================================
 */

const crypto = require('crypto');
const os = require('os');

// Master-Geheimschlüssel (NUR BEI IHNEN / NICHT DEM KUNDEN GEBEN!)
const MASTER_SECRET = "LogiFlow_Secure_Enterprise_MasterKey_2026_GoeksalNeziroglu";

/**
 * 1. Hardware-Fingerabdruck des Zielservers ermitteln
 * Liest MAC-Adresse und CPU-Architektur des Kundenservers aus.
 */
function getHardwareFingerprint() {
    const networkInterfaces = os.networkInterfaces();
    let mac = '';
    
    for (const name of Object.keys(networkInterfaces)) {
        for (const net of networkInterfaces[name]) {
            if (net.mac && net.mac !== '00:00:00:00:00:00' && !net.internal) {
                mac = net.mac;
                break;
            }
        }
        if (mac) break;
    }
    
    const rawData = `${os.hostname()}_${os.platform()}_${os.arch()}_${mac || 'DEFAULT_HW_ID'}`;
    return crypto.createHash('sha256').update(rawData).digest('hex').substring(0, 16).toUpperCase();
}

/**
 * 2. Lizenzschlüssel für einen Neukunden generieren
 * @param {string} firmenName - Name des Käufers (z.B. "Muster GmbH")
 * @param {string} hardwareId - Die vom Server des Kunden gemeldete Hardware-ID
 * @param {number} maxMitarbeiter - Maximale Anzahl (z.B. 500 oder 1000)
 * @param {string} gueltigBis - Ablaufdatum 'YYYY-MM-DD' oder 'UNBEGRENZT'
 */
function generateLicenseKey(firmenName, hardwareId, maxMitarbeiter = 1000, gueltigBis = 'UNBEGRENZT') {
    const payload = `${firmenName.trim().toUpperCase()}|${hardwareId}|${maxMitarbeiter}|${gueltigBis}`;
    const hmac = crypto.createHmac('sha256', MASTER_SECRET).update(payload).digest('hex').substring(0, 12).toUpperCase();
    
    // Format: LF-XXXX-XXXX-XXXX
    const formatted = `LF-${hmac.substring(0, 4)}-${hmac.substring(4, 8)}-${hmac.substring(8, 12)}`;
    return {
        kunde: firmenName,
        hardwareId: hardwareId,
        maxMitarbeiter: maxMitarbeiter,
        gueltigBis: gueltigBis,
        lizenzschluessel: formatted,
        signatur: hmac
    };
}

/**
 * 3. Lizenzschlüssel auf dem Server des Kunden validieren
 */
function verifyLicense(firmenName, lizenzschluessel, maxMitarbeiter = 1000, gueltigBis = 'UNBEGRENZT') {
    const currentHwId = getHardwareFingerprint();
    const expected = generateLicenseKey(firmenName, currentHwId, maxMitarbeiter, gueltigBis);
    
    if (expected.lizenzschluessel === lizenzschluessel) {
        return {
            isValid: true,
            status: "GUELTIG",
            nachricht: `Lizenz verifiziert für ${firmenName} auf diesem Server.`
        };
    } else {
        return {
            isValid: false,
            status: "UNGUELTIG",
            nachricht: "FEHLER: Ungültiger Lizenzschlüssel oder unbefugtes Kopieren auf Fremdhardware!"
        };
    }
}

// Wenn direkt ausgeführt (CLI-Modus)
if (require.main === module) {
    console.log("=================================================");
    console.log("🔐 LOGIFLOW LIZENZ- & HARDWARE-GENERATOR");
    console.log("=================================================");
    
    const myHwId = getHardwareFingerprint();
    console.log(`\n1. Eigener Hardware-Fingerabdruck: [ ${myHwId} ]`);
    
    // Beispiel-Generierung
    const demoLizenz = generateLicenseKey("Muster Fertigungstechnik GmbH", myHwId, 500, "2027-12-31");
    console.log("\n2. Beispiel-Lizenz für Neukunden:");
    console.log(`   Kunde:            ${demoLizenz.kunde}`);
    console.log(`   Hardware-Bindung: ${demoLizenz.hardwareId}`);
    console.log(`   Lizenzschlüssel:  ${demoLizenz.lizenzschluessel}`);
    
    // Validierungstest
    const check = verifyLicense("Muster Fertigungstechnik GmbH", demoLizenz.lizenzschluessel, 500, "2027-12-31");
    console.log(`\n3. Selbsttest-Prüfung: ${check.isValid ? '✅ ERFOLGREICH' : '❌ FEHLGESCHLAGEN'}`);
    console.log("=================================================\n");
}

module.exports = {
    getHardwareFingerprint,
    generateLicenseKey,
    verifyLicense
};
