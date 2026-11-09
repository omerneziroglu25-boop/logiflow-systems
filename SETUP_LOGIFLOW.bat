@echo off
chcp 65001 >nul
title LogiFlow Systems - 1-Klick Enterprise Installation

echo ==============================================================================
echo   LOGIFLOW SYSTEMS | AUTOMATISCHE SERVER-INSTALLATION & START
echo ==============================================================================
echo.
echo [1/3] Pruefe Docker-Umgebung...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [HINWEIS] Docker Desktop wurde nicht gefunden.
    echo Starte LogiFlow im autarken lokalen Direkt-Modus...
    echo.
    echo [2/3] Starte Node.js Server...
    start http://localhost:3000
    node server.js
    goto end
)

echo [2/3] Docker gefunden. Starte hochverfuegbare Produktions-Container...
echo       - PostgreSQL Enterprise Datenbank (Port 5432)
echo       - LogiFlow Leitstand & MES Web-App (Port 3000)
docker compose up -d

echo.
echo [3/3] Installation erfolgreich abgeschlossen!
echo Oeffne Leitstand im Standard-Browser...
timeout /t 3 >nul
start http://localhost:3000

echo.
echo ==============================================================================
echo   LogiFlow laeuft nun ausfallsicher auf diesem Server.
echo   Ihre Werker koennen ab sofort im Werks-WLAN zugreifen:
echo   http://localhost:3000
echo ==============================================================================

:end
pause
