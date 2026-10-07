# lb-garageapp

**Deutsch** | [English](#english)

Garagen-App für das **LB Phone**, gebaut für **JG Advanced Garages** (ESX Legacy oder Qbox). Die App ist keine Standard-App:
Spieler laden sie im Appstore des Handys herunter.

Die App zeigt alle eigenen Fahrzeuge, ihren Zustand (in der Garage, ausgeparkt, im Abschlepphof), den Standort und
den Zustand (Tank, Motor, Karosserie). Fahrzeuge lassen sich als Favoriten markieren, und ein Knopf setzt einen
Wegpunkt zur Garage oder zum Abschlepphof. Ausparken geht bewusst nicht über die App.

## Voraussetzungen

- ESX Legacy (`es_extended`) oder Qbox (`qbx_core`), das Framework wird automatisch erkannt
- `oxmysql`
- `ox_lib`
- `lb-phone`
- `jg-advancedgarages` (Datenbank-Spalten der Fahrzeugtabelle und die Garagen-Config)

## Installation

1. Den Ordner `lb-garageapp` nach `resources/` kopieren, zum Beispiel nach `resources/[scripts]/[lb]/lb-garageapp`.
2. In der `server.cfg` eintragen. Die App muss **nach** `lb-phone` und `jg-advancedgarages` starten:

   ```cfg
   ensure lb-phone
   ensure jg-advancedgarages
   ensure lb-garageapp
   ```

   Steht `ensure [scripts]` in der `server.cfg`, reicht es, den Ordner an die richtige Stelle zu legen.
3. Server starten oder in der Konsole `refresh` und danach `ensure lb-garageapp` eingeben.
4. Beim ersten Start legt die App die Tabelle `lb_garageapp_favorites` selbst an. Ein SQL-Import ist nicht nötig.
5. Im Spiel: Handy öffnen, **App Store**, **Garage** herunterladen.

## Einstellungen (`config.lua`)

| Einstellung | Bedeutung |
|---|---|
| `Config.Locale` | Sprache der App: `auto` (folgt der Telefonsprache, sonst Deutsch), `de` oder `en` |
| `Config.AppName` | Name der App, zum Beispiel `Garage` oder `Fuhrpark` |
| `Config.Description` / `Config.DescriptionEn` | Beschreibung im Appstore (deutsch / englisch) |
| `Config.Identifier` | Interne Kennung der App, nach der Installation nicht mehr ändern |
| `Config.GarageResource` | Ressource mit den Garagen (Standard: `jg-advancedgarages`) |
| `Config.Framework` | `auto` (erkennt zuerst Qbox, dann ESX), `esx` oder `qbx` |
| `Config.VehiclesTable` | Tabelle mit den Spielerfahrzeugen. `nil` nutzt den Standard des Frameworks (ESX: `owned_vehicles`, Qbox: `player_vehicles`) |

## Sprachen

Die Übersetzungen liegen in `ui/locales/de.js` und `ui/locales/en.js`. Für eine weitere Sprache:

1. `ui/locales/en.js` kopieren, umbenennen (zum Beispiel `fr.js`) und die Texte übersetzen.
   Dabei `window.LOCALES.en` in `window.LOCALES.fr` ändern und `tag` auf ein Gebietsschema setzen (zum Beispiel `fr-FR`).
2. In `ui/index.html` unter den anderen Sprachdateien eine Zeile ergänzen:
   `<script src="locales/fr.js"></script>`
3. `Config.Locale` auf `fr` stellen oder auf `auto` lassen.

## Woher die Daten kommen

- Fahrzeuge, Zustand, Kraftstoff, Motor und Karosserie kommen aus der Tabelle `owned_vehicles` (ESX, Besitzer-Spalte
  `owner`) bzw. `player_vehicles` (Qbox, Besitzer-Spalte `citizenid`). Unter Qbox stammen die Fahrzeugnamen aus der
  gemeinsamen Fahrzeugliste von `qbx_core`.
- Favoriten werden pro Identifier (ESX) bzw. `citizenid` (Qbox) gespeichert und gehen bei einem Wechsel des Frameworks
  nicht automatisch mit.
- Garagen- und Abschlepphof-Standorte liest die App aus `config/config.lua` von `jg-advancedgarages`. Private Garagen
  kommen aus der Tabelle `player_priv_garages`. Für Garagen ohne bekannten Standort bleibt der Wegpunkt-Knopf grau.
- Favoriten stehen in der eigenen Tabelle `lb_garageapp_favorites`. Nur der Besitzer kann sein Fahrzeug markieren.
- Die Liste aktualisiert sich automatisch, solange die App geöffnet ist.

## Fehlersuche

- **App erscheint nicht im Appstore:** Startet `lb-garageapp` nach `lb-phone`? In der Konsole nach
  `Could not add the app` suchen.
- **Liste ist leer:** Sind die Spalten `in_garage`, `garage_id`, `impound` in der Fahrzeugtabelle vorhanden
  (Teil der Installation von `jg-advancedgarages`)? Beim Start prüft die App die Tabelle und meldet fehlende Spalten
  in der Konsole (`is missing columns`). Die Zeile `Using framework: ...` zeigt, welches Framework erkannt wurde.
- **Abschlepphof zeigt keinen Grund oder keine Kosten:** Diese Angaben stehen nur in `impound_data`, wenn JG sie
  gespeichert hat.

---

## English

Garage app for **LB Phone**, made for **JG Advanced Garages** (ESX Legacy or Qbox). It is not a default app:
players download it from the phone's app store.

The app lists your vehicles, their state (in garage, out of garage, impounded), their location and their condition
(fuel, engine, body). You can mark favorites, and a button sets a waypoint to the garage or the impound lot.
Taking vehicles out of the garage is intentionally not part of the app.

### Requirements

- ESX Legacy (`es_extended`) or Qbox (`qbx_core`), the framework is detected automatically
- `oxmysql`
- `ox_lib`
- `lb-phone`
- `jg-advancedgarages` (database columns of the vehicles table and the garage config)

### Installation

1. Copy the `lb-garageapp` folder to `resources/`, for example `resources/[scripts]/[lb]/lb-garageapp`.
2. Add it to your `server.cfg`. The app must start **after** `lb-phone` and `jg-advancedgarages`:

   ```cfg
   ensure lb-phone
   ensure jg-advancedgarages
   ensure lb-garageapp
   ```

   If your `server.cfg` contains `ensure [scripts]`, placing the folder in the right category is enough.
3. Start the server, or run `refresh` and then `ensure lb-garageapp` in the console.
4. On the first start the app creates the table `lb_garageapp_favorites` itself. No SQL import is needed.
5. In game: open the phone, go to the **App Store** and download **Garage**.

### Configuration (`config.lua`)

| Setting | Meaning |
|---|---|
| `Config.Locale` | App language: `auto` (follows the phone language, falls back to German), `de` or `en` |
| `Config.AppName` | App name, for example `Garage` or `Fuhrpark` |
| `Config.Description` / `Config.DescriptionEn` | App store description (German / English) |
| `Config.Identifier` | Internal app id, do not change it after installing |
| `Config.GarageResource` | Resource that provides the garages (default: `jg-advancedgarages`) |
| `Config.Framework` | `auto` (detects Qbox first, then ESX), `esx` or `qbx` |
| `Config.VehiclesTable` | Table with the player vehicles. `nil` uses the framework default (ESX: `owned_vehicles`, Qbox: `player_vehicles`) |

### Languages

The translations live in `ui/locales/de.js` and `ui/locales/en.js`. To add another language:

1. Copy `ui/locales/en.js`, rename it (for example `fr.js`) and translate the texts.
   Change `window.LOCALES.en` to `window.LOCALES.fr` and set `tag` to a locale (for example `fr-FR`).
2. Add a line below the other language files in `ui/index.html`:
   `<script src="locales/fr.js"></script>`
3. Set `Config.Locale` to `fr`, or leave it on `auto`.

### Where the data comes from

- Vehicles, state, fuel, engine and body come from the `owned_vehicles` table (ESX, owner column `owner`) or
  `player_vehicles` (Qbox, owner column `citizenid`). On Qbox the vehicle names come from the shared vehicle list of
  `qbx_core`.
- Favorites are keyed by the identifier (ESX) or `citizenid` (Qbox) and do not carry over when a server switches
  framework.
- Garage and impound locations are read from `config/config.lua` of `jg-advancedgarages`. Private garages come from
  the `player_priv_garages` table. For garages without a known location the waypoint button stays grey.
- Favorites are stored in the app's own table `lb_garageapp_favorites`. Only the owner can mark a vehicle.
- The list refreshes automatically while the app is open.

### Troubleshooting

- **The app does not show up in the app store:** does `lb-garageapp` start after `lb-phone`? Look for
  `Could not add the app` in the console.
- **The list is empty:** do the columns `in_garage`, `garage_id` and `impound` exist in the vehicles table
  (part of the `jg-advancedgarages` installation)? On start the app checks the table and prints missing columns to the
  console (`is missing columns`). The line `Using framework: ...` shows which framework was detected.
- **The impound shows no reason or cost:** that information is only available in `impound_data` when JG stored it.
