# Garmin Atemrunden

Eine native Connect IQ Watch-App als einfacher Phasen-Timer für Wim-Hof-Atemrunden. Sie führt durch drei Runden mit jeweils ungefähr 30 Atemzügen, einer manuell beendeten Atemhaltephase und einem 15-sekündigen Erholungsatem. Die Atemzüge werden nicht automatisch erkannt.

## Bedienung

- **Select** startet die Sitzung. Atme in jeder Atemphase ungefähr 30-mal, ohne dabei Knöpfe zu drücken. Drücke **Select** einmal nach dem letzten Ausatmen, um die Haltephase zu starten.
- Halte nach dem Ausatmen und drücke **Select** erst, wenn du wieder atmen möchtest. Die App setzt kein Zeitlimit.
- Der Erholungsatem läuft 15 Sekunden und geht danach automatisch in die nächste Runde.
- **Back** pausiert. **Select** setzt fort; **Back** während der Pause beendet die App.
- Nach Runde drei zeigt die App den Abschluss. **Select** startet eine neue Sitzung.

## Sicherheit

Übe sitzend oder liegend an einem sicheren Ort. Übe nie im oder nahe am Wasser, unter der Dusche oder beim Fahren. Die Atemübung kann Benommenheit auslösen. Die App ist ein Zähler und Timer, keine medizinische Anwendung oder Atemanleitung. Beachte die [offiziellen Hinweise zur Atemtechnik](https://www.wimhofmethod.com/breathing-exercises) und kläre gesundheitliche Bedenken vorab mit medizinischem Fachpersonal.

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

Die Standardwerte (ungefähr 30 Atemzüge, drei Runden, 15 Sekunden Erholungsatem) folgen dem Ablauf der [offiziellen Wim-Hof-Atemtechnik](https://www.wimhofmethod.com/breathing-exercises). Die App erkennt keine einzelnen Atemzüge; **Select** markiert nur den Übergang zur Haltephase.

## Lizenz

Der Quellcode steht unter der MIT-Lizenz; Details stehen in [LICENSE](LICENSE). Garmin Connect IQ SDK und persönliche Entwicklerschlüssel gehören nicht zum Repository und müssen separat bezogen beziehungsweise erstellt werden.

Dieses unabhängige Projekt wird weder von Garmin noch von der Wim-Hof-Organisation unterstützt oder herausgegeben.
