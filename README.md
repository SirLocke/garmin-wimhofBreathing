# Garmin Atemrunden

Eine native Connect IQ Watch-App als einfacher Phasen-Timer für Atemrunden nach der Wim-Hof-Atemtechnik. Sie führt durch drei Runden mit jeweils ungefähr 30 Atemzügen, einer manuell beendeten Atemhaltephase und einem 15-sekündigen Erholungsatem. Die Atemzüge werden nicht automatisch erkannt. Die App zeichnet eine Garmin-Aktivität vom Typ **Training → Breathwork** auf unterstützten Geräten auf.

## Bedienung

- **Select** startet die Sitzung. Atme in jeder Atemphase ungefähr 30-mal, ohne dabei Knöpfe zu drücken. Drücke **Select** einmal nach dem letzten Ausatmen, um die Haltephase zu starten.
- Halte nach dem Ausatmen und drücke **Select** erst, wenn du wieder atmen möchtest. Die App setzt kein Zeitlimit.
- Der Erholungsatem läuft 15 Sekunden und geht danach automatisch in die nächste Runde.
- Die Sitzung wird als FIT-Aktivität gespeichert und kann nach dem Synchronisieren in Garmin Connect erscheinen. Auf älteren Geräten ohne Breathwork-Untertyp wird sie als allgemeines Training gespeichert.
- **Back** pausiert. **Select** setzt fort; **Back** während der Pause beendet die App.
- Nach Runde drei zeigt die App den Abschluss. **Select** startet eine neue Sitzung.

## Sicherheit

Übe sitzend oder liegend an einem sicheren, trockenen Ort. Übe die Atemtechnik nie im oder nahe am Wasser, unter der Dusche, im Eisbad oder beim Fahren: Sie kann Benommenheit oder Ohnmacht auslösen. Kälteexposition ist ein eigener Teil der Wim-Hof-Methode und findet getrennt von der Atemübung statt. Die App ist ein Timer, keine medizinische Anwendung oder Atemanleitung. Beachte die [offiziellen Hinweise zur Atemtechnik](https://www.wimhofmethod.com/breathing-exercises) und kläre gesundheitliche Bedenken vorab mit medizinischem Fachpersonal.

## Projekt

- `source/`: Connect IQ App, Eingabe und Sitzungszustand
- `manifest.xml`: Watch-App-Metadaten und Zielgeräte
- `monkey.jungle`: Monkey-C-Projektpfade

Zum Bauen werden das Garmin Connect IQ SDK und Java 11 oder neuer benötigt. Die Manifest-Auswahl enthält die aktuell im SDK 9.3.0 gelisteten runden Geräte ab API 3.2; neue Modelle lassen sich in Visual Studio Code über **Monkey C: Edit Products** ergänzen.

Erzeuge einmalig einen privaten Signierschlüssel außerhalb des Repositories:

```sh
mkdir -p ~/.Garmin/ConnectIQ/keys
openssl genrsa -out ~/.Garmin/ConnectIQ/keys/developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
  -in ~/.Garmin/ConnectIQ/keys/developer_key.pem \
  -out ~/.Garmin/ConnectIQ/keys/developer_key.der -nocrypt
chmod 600 ~/.Garmin/ConnectIQ/keys/developer_key.*
```

Beispielbuild für eine runde Uhr (hier: fenix 9 Pro 47 mm):

```sh
mkdir -p build
monkeyc -d fenix9pro47mm -f monkey.jungle \
  -o build/atemrunden.prg \
  -y ~/.Garmin/ConnectIQ/keys/developer_key.der
```

Bewahre denselben privaten Schlüssel sicher auf; er wird für Updates derselben Store-App benötigt. Schlüssel und Build-Ausgaben werden von Git ignoriert. Zum Starten im Simulator zuerst `connectiq` ausführen und danach `monkeydo build/atemrunden.prg fenix9pro47mm`.

Für einen Store-Upload erzeugt das SDK aus allen konkret gelisteten Produkten ein signiertes Paket:

```sh
monkeyc -e -f monkey.jungle \
  -o build/atemrunden.iq \
  -y ~/.Garmin/ConnectIQ/keys/developer_key.der
```

Zum Test auf einer echten Uhr zuerst wie oben ein passendes `.prg` bauen, die Uhr per USB verbinden und die Datei nach `GARMIN/APPS` kopieren. Nach dem sicheren Auswerfen lässt sich die App auf der Uhr starten; danach die Uhr mit Garmin Connect synchronisieren und die gespeicherte Aktivität prüfen.

Die Standardwerte (ungefähr 30 Atemzüge, drei Runden, 15 Sekunden Erholungsatem) folgen dem Ablauf der [offiziellen Wim-Hof-Atemtechnik](https://www.wimhofmethod.com/breathing-exercises). Die App bildet nur die Atemübung ab, nicht alle drei Säulen der Methode. Sie erkennt keine einzelnen Atemzüge; **Select** markiert nur den Übergang zur Haltephase. Das unabhängige Projekt ist nicht von Garmin oder der Wim-Hof-Organisation herausgegeben.

## Lizenz

Der Quellcode steht unter der MIT-Lizenz; Details stehen in [LICENSE](LICENSE). Garmin Connect IQ SDK und persönliche Entwicklerschlüssel gehören nicht zum Repository und müssen separat bezogen beziehungsweise erstellt werden.

Details zur Speicherung der FIT-Aktivität stehen in [PRIVACY.md](PRIVACY.md).

Dieses unabhängige Projekt wird weder von Garmin noch von der Wim-Hof-Organisation unterstützt oder herausgegeben.
