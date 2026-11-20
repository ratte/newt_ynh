Newt ist der Site-Connector von [Pangolin](https://pangolin.net), einem selbst gehosteten getunnelten Reverse Proxy mit Identitäts- und Zugriffskontrolle.

Newt baut einen ausgehenden WireGuard-Tunnel (im Userspace) von deinem YunoHost-Server zu deinem Pangolin-Server auf. Pangolin kann deine YunoHost-Apps dann unter seinen öffentlichen Domains veröffentlichen, ohne dass auf der YunoHost-Seite ein Port geöffnet oder weitergeleitet werden muss (funktioniert auch hinter CGNAT).

### Funktionen

- Nur ausgehende Verbindung: keine Portweiterleitung, keine öffentliche IP nötig
- Läuft ohne Root-Rechte mit systemd-Sandboxing, ohne Docker
- Veröffentlicht die YunoHost-Domains, die du auswählst: Newt legt die Pangolin-Ressourcen an
- Echte Client-IPs in NGINX, fail2ban sperrt Angreifer in NGINX
- Ignoriert die YunoHost-Diagnose-Prüfungen, die hinter Pangolin zwangsläufig fehlschlagen
- Alles im Konfigurations-Panel der Webadmin einstellbar
- Updates laufen über YunoHost (Newts eingebauter Self-Updater ist absichtlich blockiert)
