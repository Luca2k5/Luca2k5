# OTOBO-Ticketauswertung

Konzept für eine OTOBO-11-Auswertung nach Zeitraum und Eingangskanal.

## E-Mail-Quellen eindeutig unterscheiden

Die beiden Freiburger E-Mail-Wege werden als **getrennte Ticketquellen** geführt:

| Technischer Wert (`TicketOrigin`) | Anzeige in der Auswertung | Zuordnung |
|---|---|---|
| `Email_ITTicketsystem_Direct` | E-Mail: IT-Ticketsystem (direkt) | Nachricht an `it-ticketsystem@theater.freiburg.de`, die direkt aus dessen Inbox abgeholt wird |
| `Email_IT_ManualFolder` | E-Mail: IT (manuell verschoben) | Nachricht an `it@theater.freiburg.de`, die in Outlook manuell in den Ticketordner verschoben und von dort abgeholt wird |
| `Email_Other` | E-Mail: sonstiger Import | Alle weiteren per PostMaster/IMAP importierten Nachrichten |

Damit können beide Wege einzeln an- und abgewählt werden. Zusätzlich gibt es in der Oberfläche die Sammeloption **Alle E-Mail-Quellen**.

## Verlässliche Erkennung

Die Zuordnung soll anhand des **abgefragten Postfachs beziehungsweise Ordners** erfolgen, nicht nur anhand des sichtbaren `To`-Headers. Weiterleitungen, Verteiler, `Cc` und `Bcc` können den Empfänger-Header verändern oder mehrdeutig machen.

Empfohlene Reihenfolge:

1. Der Abruf der direkten Inbox setzt `TicketOrigin=Email_ITTicketsystem_Direct`.
2. Der Abruf des manuell befüllten Outlook-Ticketordners setzt `TicketOrigin=Email_IT_ManualFolder`.
3. Nur als Rückfallebene werden die normalisierten Empfänger-Header geprüft:
   - `it-ticketsystem@theater.freiburg.de` → `Email_ITTicketsystem_Direct`
   - `it@theater.freiburg.de` → `Email_IT_ManualFolder`
4. Ist keine eindeutige Zuordnung möglich, wird `Email_Other` verwendet. Ein Ticket wird nie doppelt gezählt.

Die beiden Abrufwege brauchen daher getrennt erkennbare Mail-Account-/Fetch-Konfigurationen. Wenn beide Ordner mit demselben OTOBO-Mailkonto abgerufen werden, muss der jeweilige Abruf vor der Übergabe an PostMaster einen eindeutigen Header ergänzen, zum Beispiel:

```text
X-OTOBO-Source: ITTicketsystem-Direct
```

beziehungsweise:

```text
X-OTOBO-Source: IT-ManualFolder
```

Ein PostMaster-Filter ordnet diesen Marker anschließend dem Dynamic Field `TicketOrigin` zu. Der Marker ist zuverlässiger als die Absenderadresse und darf von extern eingehenden Nachrichten nicht ungeprüft übernommen werden.

## Filter der Auswertung

Die geplante Seite **Auswertung** enthält folgende Quellenfilter:

- Kundenportal
- E-Mail: IT-Ticketsystem (direkt)
- E-Mail: IT (manuell verschoben)
- E-Mail: sonstiger Import
- durch Agent erstellt
- NinjaOne API
- Securepoint API
- sonstige/unbekannte Quelle

Zur Verfügung stehen die Zeiträume **7 Tage**, **14 Tage**, **30 Tage**, **12 Monate** und **benutzerdefiniert**. Kurze Zeiträume werden pro Tag, lange Zeiträume standardmäßig pro Monat gruppiert. Erstellt- und Geschlossen-Zahlen werden jeweils anhand ihres eigenen Zeitstempels dem ausgewählten Zeitraum zugeordnet.

## Plausibilitätsregeln

- Jedes Ticket besitzt genau einen dauerhaften `TicketOrigin`-Wert.
- Die Summe der sichtbaren Quellen entspricht der Gesamtzahl der gefilterten Tickets.
- „Geschlossen“ wird über die Schließzeit im Zeitraum ermittelt, nicht über den aktuellen Status.
- Beim manuellen Verschieben in Outlook zählt der Zeitpunkt der Ticketerstellung in OTOBO, nicht der ursprüngliche Empfangszeitpunkt im Postfach.
- Historische Tickets ohne sichere Herkunft bleiben `Unknown`, statt anhand unsicherer Merkmale falsch zugeordnet zu werden.
