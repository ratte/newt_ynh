### Konfigurations-Panel

Alles wird im Konfigurations-Panel der App eingestellt (*Applikationen > Newt > Konfiguration* in der Webadmin, oder `yunohost app config set __APP__`). Beim Speichern wird `__INSTALL_DIR__/newt.env` neu erzeugt und der Dienst neu gestartet.

- **Verbindung zu Pangolin:** Endpoint, Newt-ID und Secret. Das Secret-Feld leer lassen, um das aktuelle Secret zu behalten.
- **Veröffentlichte Domains:** die YunoHost-Domains, die Pangolin ausliefern soll (siehe unten).
- **Echte Client-IPs:** siehe unten.
- **Log-Level**

Pangolin Cloud (`*.pangolin.net`) wird automatisch erkannt. Bei einem selbst gehosteten Pangolin sorgt `NO_CLOUD=true` dafür, dass Newt nie auf Pangolin Cloud ausweicht.

### YunoHost-Domains über Pangolin veröffentlichen

Wähle die Domains unter **Veröffentlichte Domains** aus. Newt legt dann in Pangolin pro Domain eine HTTP-Ressource an (über ein Pangolin-*Blueprint*), die durch den Tunnel auf YunoHosts NGINX zeigt (`https://127.0.0.1:443`, mit der Domain als Host-Header und TLS Server Name). Alle Apps dieser Domain, auch später installierte, sind dann über Pangolin erreichbar.

Voraussetzungen und Hinweise:

- Die Domain (oder ihre übergeordnete Domain) muss in deiner Pangolin-Organisation unter *Domains* existieren, und ihr DNS muss auf Pangolin zeigen.
- Eine in Pangolin von Hand angelegte Ressource für dieselbe Domain blockiert die automatische (`Resource already exists` im Log): zuerst in Pangolin löschen.
- Eine abgewählte Domain wird in Pangolin **nicht** gelöscht. Dort von Hand löschen.
- Standardmäßig ist Pangolins eigener Login für diese Ressourcen aus: YunoHosts Login (SSO) schützt die Apps, wie ohne Pangolin. Mit **Zusätzlich Pangolin-Login verlangen** braucht es beide.
- Das Ergebnis steht in `/var/log/__APP__/__APP__.log` (`Blueprint application failed: …` zeigt Pangolins Fehlermeldung).

Pangolin terminiert TLS mit eigenem Zertifikat. Sobald der DNS-Eintrag der Domain auf Pangolin zeigt, kann YunoHost sein Let's-Encrypt-Zertifikat nicht mehr erneuern. Das ist in Ordnung, das interne Zertifikat wird nur im Tunnel benutzt.

Um anderes zu veröffentlichen (einen anderen Port, einen Raw-TCP-Dienst), lege in Pangolin von Hand eine Ressource an, die dieser Site zugeordnet ist.

### YunoHost-Diagnose

Die Diagnose prüft DNS-Einträge, HTTP-Erreichbarkeit und offene Ports gegen die eigene öffentliche IP des Servers. Hinter Pangolin schlägt das zwangsläufig fehl. Mit **Diagnose-Prüfungen ignorieren, die hinter Pangolin fehlschlagen** (standardmäßig an) ignoriert Newt für jede veröffentlichte Domain die Basis-DNS-Einträge (A/AAAA) und die HTTP-Erreichbarkeit, außerdem die Ports 80/443, sobald alle öffentlichen YunoHost-Domains veröffentlicht sind. Mail-DNS-Einträge werden weiter geprüft. Die Ausnahmen werden entfernt, wenn du eine Domain abwählst, die Option ausschaltest oder die App entfernst.

### Echte Client-IPs (fail2ban)

Ohne zusätzliche Konfiguration sieht YunoHost jede Anfrage aus dem Tunnel als `127.0.0.1`: Die Logs sind nutzlos, und fail2ban kann niemanden sperren. Mit **Echte Client-IPs verwenden und Angreifer in nginx sperren** (standardmäßig an):

- `/etc/nginx/conf.d/newt-realip.conf` lässt NGINX die Client-IP aus dem von Pangolin gesetzten `X-Forwarded-For`-Header nehmen, nur für Anfragen von localhost. Es zählt nur der letzte, von Pangolin angehängte Eintrag, Clients können ihn also nicht fälschen.
- Firewall-Sperren helfen hinter dem Tunnel nicht, weil der ganze Verkehr von localhost kommt. Die Web-Jails von fail2ban (`yunohost`, `yunohost-portal`, `nginx-http-auth`, `recidive`) sperren die IP deshalb zusätzlich in NGINX (`/etc/nginx/newt-banned-ips.conf`, Antwort 403).

Diese Dateien teilen sich alle Newt-Instanzen. Sie werden entfernt, sobald keine Instanz die Option mehr nutzt. Sperren anzeigen mit `fail2ban-client status yunohost`.

### Mail und andere Raw-TCP-Dienste

Postfix **nicht** über eine Raw-TCP-Ressource mit Ziel `localhost:25` freigeben: Postfix vertraut `127.0.0.0/8`, dein Server könnte so zum offenen Relay werden. Wenn es sein muss, auf die LAN-IP des Servers zielen.

### Logs

`/var/log/__APP__/__APP__.log`

### Einschränkungen

- Der SSH-Auth-Daemon (Pangolin-SSH-Ressourcen) ist deaktiviert, weil er Root-Rechte braucht.
- Newts eingebauter Self-Updater kann sein Binary nicht überschreiben und loggt alle 6 Stunden einen Fehler. Das ist so gewollt, Updates kommen über YunoHost.
