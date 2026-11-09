-- ============================================================================
-- LOGIFLOW SYSTEMS - ENTERPRISE RELATIONAL DATABASE SCHEMA (PostgreSQL / SQL)
-- Ausgelegt für 500 - 1.000 Mitarbeiter im Mehrschichtbetrieb (ISO 9001 / MES)
-- ============================================================================

-- 1. BENUTZER & ROLLENBASIERTE RECHTEVERWALTUNG (RBAC)
CREATE TABLE IF NOT EXISTS benutzer (
    id SERIAL PRIMARY KEY,
    personalnummer VARCHAR(30) UNIQUE NOT NULL,
    rfid_chip_id VARCHAR(50) UNIQUE,
    vorname VARCHAR(60) NOT NULL,
    nachname VARCHAR(60) NOT NULL,
    email VARCHAR(120),
    rolle VARCHAR(30) NOT NULL CHECK (rolle IN ('WERKER', 'VORARBEITER', 'QS_PRUEFER', 'LEITSTAND', 'ADMIN')),
    abteilung VARCHAR(50) NOT NULL,
    schicht_modell VARCHAR(20) DEFAULT '3-SCHICHT',
    ist_aktiv BOOLEAN DEFAULT TRUE,
    erstellt_am TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. ARTIKELSTAMM & MATERIALIEN
CREATE TABLE IF NOT EXISTS artikel (
    id SERIAL PRIMARY KEY,
    artikelnummer VARCHAR(50) UNIQUE NOT NULL,
    bezeichnung VARCHAR(150) NOT NULL,
    warengruppe VARCHAR(50) NOT NULL,
    einheit VARCHAR(10) DEFAULT 'STK',
    soll_taktzeit_sekunden INTEGER DEFAULT 0,
    barcode VARCHAR(60) UNIQUE NOT NULL,
    mindestbestand INTEGER DEFAULT 0,
    ist_aktiv BOOLEAN DEFAULT TRUE,
    erstellt_am TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. PRODUKTIONSAUFTRÄGE & LEITSTAND (4-SEKTOREN)
CREATE TABLE IF NOT EXISTS fertigungsauftraege (
    id SERIAL PRIMARY KEY,
    auftragsnummer VARCHAR(50) UNIQUE NOT NULL,
    artikel_id INTEGER REFERENCES artikel(id) ON DELETE RESTRICT,
    losgroesse INTEGER NOT NULL CHECK (losgroesse > 0),
    menge_fertiggestellt INTEGER DEFAULT 0,
    menge_ausschuss INTEGER DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'EINGESTEUERT' 
        CHECK (status IN ('EINGESTEUERT', 'IN_BEARBEITUNG', 'UNTERBROCHEN', 'QUALITAETSSPERRE', 'FERTIGGESTELLT')),
    aktueller_sektor INTEGER NOT NULL DEFAULT 1 
        CHECK (aktueller_sektor BETWEEN 1 AND 4), -- 1: Zuschnitt/Basis, 2: Bearbeitung, 3: Montage, 4: Endabnahme
    prioritaet INTEGER DEFAULT 3 CHECK (prioritaet BETWEEN 1 AND 5), -- 1: Eilauftrag, 5: Niedrig
    geplanter_start TIMESTAMP WITH TIME ZONE,
    tatsaechlicher_start TIMESTAMP WITH TIME ZONE,
    beendet_am TIMESTAMP WITH TIME ZONE,
    erstellt_am TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. BEHÄLTERPUFFER & LAGERPLATZVERWALTUNG (KISTEN-TRACKING)
CREATE TABLE IF NOT EXISTS behaelter_puffer (
    id SERIAL PRIMARY KEY,
    behaelter_code VARCHAR(50) UNIQUE NOT NULL, -- Barcode auf der Kiste/Palette
    typ VARCHAR(30) NOT NULL, -- Gitterbox, KLT-4314, Europalette
    lagerort_sektor VARCHAR(30) NOT NULL, -- PUFFER_SEKTOR_1, ZWISCHENLAGER_NORD etc.
    auftrag_id INTEGER REFERENCES fertigungsauftraege(id) ON DELETE SET NULL,
    artikel_id INTEGER REFERENCES artikel(id) ON DELETE RESTRICT,
    aktuelle_menge INTEGER NOT NULL DEFAULT 0,
    eingelagert_am TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    aktualisiert_am TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. QS-SPERRLAGER & FEHLERMANAGEMENT (REVISIONSSICHER)
CREATE TABLE IF NOT EXISTS qs_sperrlager (
    id SERIAL PRIMARY KEY,
    sperr_vorgangsnummer VARCHAR(50) UNIQUE NOT NULL,
    auftrag_id INTEGER REFERENCES fertigungsauftraege(id) ON DELETE RESTRICT,
    behaelter_id INTEGER REFERENCES behaelter_puffer(id) ON DELETE SET NULL,
    artikel_id INTEGER REFERENCES artikel(id) ON DELETE RESTRICT,
    sperrmenge INTEGER NOT NULL CHECK (sperrmenge > 0),
    fehlerkatalog_code VARCHAR(40) NOT NULL, -- z.B. MAßABWEICHUNG, OBERFLAECHENKRATZER
    fehlerbeschreibung TEXT NOT NULL,
    gesperrt_durch_benutzer_id INTEGER REFERENCES benutzer(id) ON DELETE RESTRICT,
    gesperrt_am TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'GESPERRT' 
        CHECK (status IN ('GESPERRT', 'IN_PRUEFUNG', 'FREIGEGEBEN', 'AUSSCHUSS_VERSCHROTTET', 'NACHARBEIT')),
    entscheidung_am TIMESTAMP WITH TIME ZONE,
    entscheidung_durch_benutzer_id INTEGER REFERENCES benutzer(id) ON DELETE SET NULL,
    bemerkung_entscheidung TEXT
);

-- 6. REVISIONSSICHERER AUDIT-TRAIL (ISO 9001 KONFORM)
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    zeitstempel TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    benutzer_id INTEGER REFERENCES benutzer(id) ON DELETE SET NULL,
    terminal_ip VARCHAR(50),
    aktion VARCHAR(60) NOT NULL, -- z.B. SCAN_BUCHUNG, SEKTOR_WECHSEL, QS_SPERRE
    betroffene_tabelle VARCHAR(50) NOT NULL,
    datensatz_id INTEGER NOT NULL,
    alte_werte JSONB,
    neue_werte JSONB
);

-- INDIZES FÜR HOCHLEISTUNGS-BUCHUNGEN (MILLISEKUNDEN-RESPONSE)
CREATE INDEX IF NOT EXISTS idx_artikel_barcode ON artikel(barcode);
CREATE INDEX IF NOT EXISTS idx_behaelter_code ON behaelter_puffer(behaelter_code);
CREATE INDEX IF NOT EXISTS idx_auftrag_status_sektor ON fertigungsauftraege(status, aktueller_sektor);
CREATE INDEX IF NOT EXISTS idx_audit_zeitstempel ON audit_log(zeitstempel DESC);
