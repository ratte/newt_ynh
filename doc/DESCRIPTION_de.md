Newt ist der Site-Connector von [Pangolin](https://pangolin.net), einem selbst gehosteten getunnelten Reverse Proxy mit Identitäts- und Zugriffskontrolle.

Newt baut einen ausgehenden WireGuard-Tunnel (im Userspace) von deinem YunoHost-Server zu deinem Pangolin-Server auf. Pangolin kann deine YunoHost-Apps dann unter seinen öffentlichen Domains veröffentlichen, ohne dass auf der YunoHost-Seite ein Port geöffnet oder weitergeleitet werden muss (funktioniert auch hinter CGNAT).

### Funktionen

- Nur ausgehende Verbindung: keine Portweiterleitung, keine öffentliche IP nötig
- Läuft ohne Root-Rechte mit systemd-Sandboxing, ohne Docker
- Zugangsdaten und Log-Level bei der Installation einstellbar
- Updates laufen über YunoHost (Newts eingebauter Self-Updater ist absichtlich blockiert)
