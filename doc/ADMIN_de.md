### YunoHost-Apps über Pangolin veröffentlichen

Lege in Pangolin pro YunoHost-Domain/-Subdomain eine HTTP-Ressource an, die dieser Site zugeordnet ist, mit dem Ziel:

- Methode: `https`, Host: `127.0.0.1`, Port: `443`
- Host-Header / TLS Server Name (SNI) auf die echte Domain setzen, damit YunoHosts NGINX den richtigen vhost wählt
- **Nicht** auf Port 80 zielen: YunoHost leitet HTTP auf HTTPS um, das ergibt eine Schleife

Pangolin terminiert TLS mit eigenem Zertifikat. Sobald der DNS-Eintrag der Domain auf Pangolin zeigt, kann YunoHost sein Let's-Encrypt-Zertifikat nicht mehr erneuern. Das ist in Ordnung, das interne Zertifikat wird nur im Tunnel benutzt. Pangolin/Traefik darf es allerdings nicht ablehnen.

Die YunoHost-Diagnose wird bei DNS-Einträgen und Ports meckern: Diese Punkte kannst du als ignoriert markieren.

### Echte Client-IPs (fail2ban)

Ohne zusätzliche Konfiguration sieht YunoHost jede Anfrage als `127.0.0.1`. Lege `/etc/nginx/conf.d/pangolin-realip.conf` an:

```nginx
set_real_ip_from 127.0.0.1;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

und führe `nginx -t && systemctl reload nginx` aus.

### Mail und andere Raw-TCP-Dienste

Postfix **nicht** über eine Raw-TCP-Ressource mit Ziel `localhost:25` freigeben: Postfix vertraut `127.0.0.0/8`, dein Server könnte so zum offenen Relay werden. Wenn es sein muss, auf die LAN-IP des Servers zielen.

### Zugangsdaten oder Log-Level ändern

Über das Konfigurations-Panel der App in der Webadmin (*Applikationen > Newt > Konfiguration*). Das Secret-Feld leer lassen, um das aktuelle Secret zu behalten. Beim Speichern wird `__INSTALL_DIR__/newt.env` neu erzeugt und der Dienst neu gestartet.

Auf der Kommandozeile:

```bash
yunohost app config set __APP__ main.connection.newt_secret -v 'NEUES_SECRET'
yunohost app config set __APP__ main.logging.log_level -v DEBUG
```

Alternativ die Settings direkt ändern und ein Upgrade erzwingen:

```bash
yunohost app setting __APP__ newt_secret -v 'NEUES_SECRET'
yunohost app setting __APP__ newt_id -v 'NEUE_ID'
yunohost app setting __APP__ pangolin_endpoint -v 'https://pangolin.example.org'
yunohost app setting __APP__ log_level -v DEBUG
yunohost app upgrade __APP__ --force
```

Das Upgrade erzeugt `__INSTALL_DIR__/newt.env` neu aus den Settings und startet den Dienst neu.

### Logs

`/var/log/__APP__/__APP__.log`

### Einschränkungen

- Der SSH-Auth-Daemon (Pangolin-SSH-Ressourcen) ist deaktiviert, weil er Root-Rechte braucht.
- Newts eingebauter Self-Updater kann sein Binary nicht überschreiben und loggt alle 6 Stunden einen Fehler. Das ist so gewollt, Updates kommen über YunoHost.
