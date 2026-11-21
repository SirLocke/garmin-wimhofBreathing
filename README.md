# Garmin Atemrunden

Eine native Connect IQ Watch-App als einfacher Zähler und Timer für Wim-Hof-Atemrunden. Sie führt durch drei Runden mit jeweils 30 manuell gezählten Atemzügen, einer manuell beendeten Atemhaltephase und einem 15-sekündigen Erholungsatem.

## Bedienung

- **Select** startet die Sitzung und zählt während der Atemphase jeweils einen vollständigen Atemzug.
- Nach dem 30. Atemzug beginnt die Atemhaltephase. Halte nach dem Ausatmen und drücke **Select** erst, wenn du wieder atmen möchtest. Die App setzt kein Zeitlimit.
- Der Erholungsatem läuft 15 Sekunden und geht danach automatisch in die nächste Runde.
- **Back** pausiert. **Select** setzt fort; **Back** während der Pause beendet die App.
- Nach Runde drei zeigt die App den Abschluss. **Select** startet eine neue Sitzung.

## Sicherheit

Übe sitzend oder liegend an einem sicheren Ort. Übe nie im oder nahe am Wasser, unter der Dusche oder beim Fahren. Die Atemübung kann Benommenheit auslösen. Die App ist ein Zähler und Timer, keine medizinische Anwendung oder Atemanleitung. Beachte die [offiziellen Hinweise zur Atemtechnik](https://www.wimhofmethod.com/breathing-exercises) und kläre gesundheitliche Bedenken vorab mit medizinischem Fachpersonal.

## Projekt

- `source/`: Connect IQ App, Eingabe und Sitzungszustand
- `manifest.xml`: Watch-App-Metadaten und Zielgeräte
- `monkey.jungle`: Monkey-C-Projektpfade

Zum Bauen wird das Garmin Connect IQ SDK mit der Monkey-C-Erweiterung für Visual Studio Code benötigt. Öffne dieses Verzeichnis als Projekt, wähle bei Bedarf unter **Monkey C: Edit Products** kompatible Zielgeräte aus und starte anschließend den Build oder Simulator über die Monkey-C-Erweiterung. Die aktuelle Manifest-Auswahl richtet sich an runde Garmin-Uhren.

Die Standardwerte (30 Atemzüge, drei Runden, 15 Sekunden Erholungsatem) folgen dem Ablauf der [offiziellen Wim-Hof-Atemtechnik](https://www.wimhofmethod.com/breathing-exercises). Die Atemzüge selbst werden nicht getaktet: Die App zählt einen Atemzug pro Druck auf **Select**.

## Lizenz

Der Quellcode steht unter der MIT-Lizenz; Details stehen in [LICENSE](LICENSE). Garmin Connect IQ SDK und persönliche Entwicklerschlüssel gehören nicht zum Repository und müssen separat bezogen beziehungsweise erstellt werden.

Dieses unabhängige Projekt wird weder von Garmin noch von der Wim-Hof-Organisation unterstützt oder herausgegeben.
