# Installationsanleitung Intelligent Indexing V2

# Einleitung

Dieses Dokument beschreibt die Installation von DocuWare Intelligent Indexing sowie aller zusätzlich notwendigen Komponenten. Anleitungen zur Konfiguration von Intelligent Indexing und zur Arbeit mit Intelligent Indexing existieren als gesonderte Dokumente unter help.docuware.com.

## Systemvoraussetzungen

Folgende Voraussetzungen müssen für die Installation erfüllt sein:

- Neu aufgesetztes Windows Server 2019 (Build 1809)
- 8 Prozessorkerne
- 16 GB RAM
- Zugriff auf SQL Server 2019

Intelligent Indexing ist nutzbar in Kombination mit DocuWare ab Version 6.1. Falls Sie für Ihr DocuWare System einen SQL Server 2019 verwenden, können Sie diesen auch für Intelligent Indexing verwenden. Ansonsten müssen Sie einen eigenen SQL Server aufsetzen.

Für die im Folgenden beschriebene Installation sind Administratorrechte sowie eine Internetverbindung nötig.

## Überblick über die benötigten Dateien

Für die Installation von Intelligent Indexing benötigen Sie die Intelligent Indexing Setup-Dateien, die Sie als ZIP-Datei zusammen mit dieser Anleitung erhalten haben. Im Anhang finden Sie eine Übersicht über die einzelnen Dateien.

Zusätzlich benötigen Sie Ihre DocuWare Lizenzdatei, welche Sie im DocuWare Partner Portal herunterladen können.

Die Intelligent Indexing Setup-Dateien werden auch nach der Installation für den Betrieb von Intelligent Indexing benötigt. Entpacken Sie die ZIP-Datei daher in ein Verzeichnis, das Sie dauerhaft verwenden wollen. Sie können das komplette Verzeichnis aber auch später an eine andere Stelle verschieben.

## Docker Containerisierung

Intelligent Indexing läuft virtualisiert in zwei Docker Containern. Diese laufen unabhängig von anderen Anwendungen, die auf Ihrem Host-Rechner installiert sind, und werden vorkonfiguriert ausgeliefert. Der Installationsaufwand für Intelligent Indexing wird dadurch deutlich reduziert.

Die Docker Container sind:

- intellix: Der Code von Intelligent Indexing
- intellix\_solr: Die SolR Volltextsuchmaschine

Zusätzlich wird eine SQL Server Datenbank benötigt, die außerhalb der Docker Container läuft.

## Überblick über die Anleitung

Die Installation gliedert sich in folgende Schritte:

- Installation der Docker Umgebung (Kapitel 2)
- Installation des Datenbankservers (Kapitel 3)
- Konfiguration von Intelligent Indexing (Kapitel 4)
- Installation des Webservers IIS (Kapitel 5)
- Verwaltung von Intelligent Indexing (Kapitel 6)
- Intelligent Indexing lizenzieren (Kapitel 7)
- Verbindung mit DocuWare (Kapitel 8)

## Skripte ausführen

Die Powershell Skripte in den Intelligent Indexing Setup-Dateien wurden von DocuWare signiert. Allerdings verbietet Windows Server 2019 in der Voreinstellung das Ausführen von Powershell Skripten prinzipiell. Um die aktuelle Einstellung zu sehen, führen Sie als Administrator in der Powershell folgenden Befehl aus:

``` powershell
Get-ExecutionPolicy
```

Wird dabei `Restricted` angezeigt, müssen Sie über folgenden Befehl das Ausführen von signierten Skripten erlauben:

``` powershell
Set-ExecutionPolicy AllSigned
```

Das Ausführen von unsignierten Skripten wird dadurch weiterhin verhindert. Wurde ein anderer Wert als Restricted angezeigt, müssen Sie nichts ändern.

Wenn Sie das erste Mal eines der Powershell Skripte aus den Intelligent Indexing Setup-Dateien ausführen, werden Sie evtl. gefragt, ob Sie Skripten von DocuWare vertrauen wollen:

Möchten Sie Software dieses nicht vertrauenswürdigen Herausgebers ausführen?

Beantworten Sie die Frage mit dem Buchstaben A (Immer ausführen). Dadurch wird das Zertifikat von DocuWare dem Zertifikatsspeicher des Nutzers als vertrauenswürdiger Herausgeber hinzugefügt und diese Frage wird in Zukunft nicht mehr gestellt.

## Installation der Docker Umgebung

Intelligent Indexing läuft in Docker Containern. Dazu muss zuerst eine Docker Umgebung installiert werden. Wechseln Sie in einer Powershell als Administrator in das Installationsverzeichnis und führen folgenden Befehl aus:

```powershell
.\Install-Docker.ps1
```

Starten Sie anschließend den Host-Rechner neu.

Führen Sie anschließend in der Powershell als Administrator in einem beliebigen Verzeichnis folgenden Befehl aus, um die Docker Installation zu testen:

```powershell
.\Check-Docker.ps1
```

Es wird dazu ein Docker Container mit ca. 100 MB heruntergeladen und gestartet. Falls Docker korrekt installiert wurde, ist dann unter anderem folgende Ausgabe zu sehen:

```
Hello from Docker!

This message shows that your installation appears to be working correctly.
```

Prüfen Sie auch, ob Sie in der letzten Zeile der Ausgabe die Zeile

```
docker-compose version...
```

sehen können. Dadurch ist sichergestellt, dass auch Docker-Compose richtig installiert wurde, das für das Zusammenspiel der Docker Container benötigt wird.

## Installation des Datenbankservers

Intelligent Indexing benötigt eine SQL Server 2019 Datenbank. Falls Sie für Ihr DocuWare System einen SQL Server 2019 verwenden, können Sie diesen auch für Intelligent Indexing verwenden. Ansonsten müssen Sie einen eigenen SQL Server aufsetzen.

Falls Sie einen eigenen Datenbankserver aufsetzen, können Sie den kostenlosen SQL Server 2019 Express verwenden. Dieser ist allerdings auf 10 GB Speicher beschränkt, was in etwa für 1.000.000 einfache Dokumente Platz bietet. Sie können ihn unter folgendem Link herunterladen: [https://www.microsoft.com/de-de/sql-server/sql-server-downloads](https://www.microsoft.com/de-de/sql-server/sql-server-downloads). Zu Beginn der Installation können Sie die Variante Basic wählen. Installieren Sie am Ende auch das SQL Server Management Studio (SSMS). Danach ist ein Neustart des Rechners nötig.

Falls Sie einen neu aufgesetzten SQL Server verwenden, können Sie die Datenbank über ein Powershell Skript konfigurieren, das sie lokal auf dem Rechner des Datenbankservers ausführen. Gegebenenfalls müssen Sie dazu die Intelligent Indexing Setup-Dateien auf den Rechner mit dem Datenbankserver kopieren. Führen Sie dort als Administrator in einer Powershell folgendes Skript im Verzeichnis der Setup-Dateien aus:

``` powershell
.\Init-Database.ps1
```

Dabei müssen Sie folgende Parameter angeben:

- __dbIntellixUser__ und __dbIntellixUserPassword__: Das sind die Zugangsdaten für die Datenbank, mit denen Intelligent Indexing auf die Datenbank zugreifen wird. Diese Werte müssen Sie in Kapitel 4 in die Konfigurationsdatei eintragen. Der SQL Server setzt ein starkes Passwort voraus. Details dazu finden Sie unter [https://docs.microsoft.com/de-de/sql/relational-databases/security/password-policy?view=sql-server-ver15](https://docs.microsoft.com/de-de/sql/relational-databases/security/password-policy?view=sql-server-ver15)
- __intellixAdminUser__ und __intellixAdminUserPassword__: Das sind die Zugangsdaten, mit denen DocuWare auf Intelligent Indexing zugreifen wird. Diese Werte müssen Sie in Kapitel 8 in die Intelligent Indexing Verbindungsdatei eintragen. Das Passwort sollte sicher sein, aber keines der folgenden 5 Sonderzeichen enthalten, da diese in der Verbindungsdatei zu Problemen führen können: & < > " '

Zusätzlich können Sie über den optionalen Parameter serverInstance die Server Instanz ändern. Voreingestellt ist der Wert SQLEXPRESS.

Das Skript wird den Datenbankserver neustarten. Falls Sie das nicht möchten oder die Einrichtung an Ihre Situation anpassen müssen, finden Sie im Anhang eine Übersicht, welche Schritte ausgeführt werden und wie diese manuell im SQL Server Management Studio durchgeführt werden können.


## Konfiguration von Intelligent Indexing

Im Installationsverzeichnis finden Sie eine Datei „configuration.env&quot; zur Konfiguration von Intelligent Indexing.

Hier ist eine Übersicht über die Einstellungsmöglichkeiten:

- `ConnectionStrings:IntellixDatabaseEntities`: Der Connection String für die Datenbankverbindung. Ändern Sie hier die Werte für Server, user id und password entsprechend Ihres Datenbankservers ab. user id und password entsprechen den Parametern dbIntellixUser und dbIntellixUserPassword, die sie im Kapitel 3 dem Skript zur Konfiguration der Datenbank übergeben haben. Server ist der Name des Datenbankservers. Falls der Datenbankserver auf dem Host-Rechner installiert ist, müssen Sie als Namen für den Rechner wie voreingestellt $$internalgw$$ verwenden. Falls Sie keinen SQL Server Express oder nicht den Port 1433 verwenden, müssen Sie die Einträge entsprechend ändern.
- Die nächsten Einträge legen verschiedene Verzeichnisse fest. Unter `E_FileStoragePath` werden Dateien gespeichert, die Intelligent Intexing benötigt. Unter `E_SolRDataPath` werden die Daten der SolR Volltextsuchmaschine gespeichert. Und unter `E_DataProtectionKeysPath` werden Daten zum Verschlüsseln von Cookies abgelegt. Sie können diese Verzeichnisse auch später noch ändern, während Intelligent Indexing gestoppt ist. Dazu müssen Sie auch den Inhalt der Verzeichnisse an die neue Stelle kopieren. Alle diese Verzeichnise sind unabhängig vom Verzeichnis, in dem die Intelligent Indexing Setup-Dateien abgelegt sind.

Änderungen an diesen Werten greifen erst nach einem Neustart von Intelligent Indexing.

## Installation des Webservers IIS

Zur Installation führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

.\Install-IIS.ps1

Das Skript installiert den Webserver IIS mit den Komponenten UrlRewrite und ARR. Es konfiguriert den Webserver so, dass Inteligent Indexing unter dem Hostnamen, den Sie in der Konfigurationsdatei eingetragen haben, ohne Angabe eines Ports (Defaultport 80) unter http erreichbar ist.

Falls Sie eine Verbindung über https verwenden wollen, müssen Sie in der Oberfläche des IIS unter Sites -\&gt; Default Web Site rechts auf Bindings... klicken und dort unter dem https Binding ein gültiges Zertifikat hinterlegen und das Zertifikat in den entsprechenden Zertifikatsspeichern ablegen. In der Verbindungsdatei (siehe Kapitel 8) können Sie dann https statt http eintragen.


## Verwaltung von Intelligent Indexing

### Installation von Intelligent Indexing

Zur Installation führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
.\Update-Intellix.ps1
```

Dadurch werden die aktuellen Docker Images von Intelligent Indexing heruntergeladen. Diese werden von der Docker Umgebung automatisch verwaltet. Die Größe der Docker Images beträgt mehrere GB. Dieser Vorgang wird auch bei guter Internetverbindung mehrere Minuten dauern.

### Starten von Intelligent Indexing

Zum Starten von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
.\Start-Intellix.ps1
```

Beim erstmaligen Starten von Intelligent Indexing werden die Verzeichnisse angelegt, die Sie in der Konfigurationsdatei angegeben haben. Bei jedem Start werden die Versionsnummern der Docker Images für Intelligent Indexing und für die SolR Volltextsuche ausgegeben.

### Testen der Komponenten von Intelligent Indexing und Passwort ändern

Über folgendes Skript können Sie überprüfen, welche Docker Container gerade auf dem Host-Rechner laufen:

```powershell
.\Check-Intellix.ps1
```

Sie sollten für die Docker Container intellixwebcore und intellixonpremisesolr je eine Zeile als Ausgabe erhalten. In der Spalte „Status&quot; können Sie sehen, ob die Docker Container laufen („Up...&quot;) oder beendet wurden („Exited...&quot;).

Nach dem Starten von Intelligent Indexing können Sie in einem Browser auf dem Host-Rechner unter folgender URL die Administrationsoberfläche aufrufen:

```
http://localhost:8080/Html
```

Sie können sich mit dem Benutzernamen und dem Passwort einloggen, die Sie in Kapitel 3 dem Skript zur Initialisierung der Datenbank über die Parameter intellixAdminUser und intellixAdminUserPassword übergeben haben.

Testen Sie hier auch, ob Sie den Host-Rechner von dem Rechner aus, auf dem DocuWare installiert ist, über einen Browser erreichen können. Ersetzen Sie dazu in der Adresse localhost/Html (ohne 8080) den Wert localhost durch den Host-Rechner Namen.

Unter folgender URL können Sie die SolR Volltextsuchmaschine von Ihrem Host-Rechner aus erreichen:

```
http://localhost:8983
```

### Logging

Zum Loggen von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
.\Show-IntellixLogs.ps1
```

Der Loglevel wird durch die Konfigurationsdatei festgelegt.

Zum Loggen der SolR Volltextsuchmaschine führen Sie das folgende Skript aus:

```powershell
.\Show-SolrLogs.ps1
```

In beiden Skripten werden Logausgaben live angezeigt. Die Ausgaben könnten durch Drücken von Strg+C abgebrochen werden.

### Stoppen von Intelligent Indexing

Zum Stoppen von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
.\Stop-Intellix.ps1
```

### Update von Intelligent Indexing

Verwenden Sie folgendes Skript, um zu prüfen, ob Updates / Hotfixes für Intelligent Indexing vorhanden sind und diese gegebenenfalls herunterzuladen:

```powershell
.\Update-Intellix.ps1
```

Nicht mehr benötigte Docker Images werden automatisch gelöscht. Die Downloadgröße wird in den meisten Fällen mehrere 100 MB betragen. Sie können dieses Skript ausführen, während Intelligent Indexing läuft. Die Änderungen werden erst aktiv, wenn sie nach Beendigung dieses Skripts Stop-Intellix.ps1 und Start-Intellix.ps1 ausführen. Auch ein Neustart des Host-Rechners führt ein heruntergeladenes Update nicht durch.

### Neustart des Host-Rechners

Die Docker Umgebung verwaltet die laufenden Intelligent Indexing Container. Diese sind so konfiguriert, dass Intelligent Indexing bei einem Neustart des Host-Rechners heruntergefahren und automatisch wieder gestartet wird. Falls Intelligent Indexing vor dem Neustart nicht lief, wird es auch danach nicht gestartet.

### Intelligent Indexing lizenzieren

Im DocuWare Partner Portal können Sie die DocuWare Lizenzdatei herunterladen. In der Intelligent Indexing Administrationsoberfläche können Sie diese unter dem Punkt Licensing hochladen und damit Ihre Intelligent Indexing Installation lizenzieren.

## Verbindung zu DocuWare

Im Installationsverzeichnis befindet sich die Intelligent Indexing Verbindungsdatei intelligent-indexing-connection.xml, mit deren Hilfe DocuWare die Verbindung zu Intelligent Indexing aufbauen kann.

Öffnen Sie diese Datei in einem Texteditor. Tragen Sie in Zeile 3 die Adresse ein, unter der der Host-Rechner von dem Rechner mit der DocuWare Installation aus erreichbar war, aber ohne Html am Ende. Der Name des Host-Rechners bzw. dessen statische IP-Adresse muss also statt localhost eintragen werden. Falls Sie z.B. Intelligent Indexing von Ihrem DocuWare Rechner unter http://intellix/Html erreichen konnten, tragen Sie hier http://intellix/ ein. Falls Sie den Webserver für eine Verbindung über https konfiguriert haben (Kapitel 5), können Sie hier https statt http eintragen.

Tragen Sie in Zeile 4 und 5 den Nutzer und das Passwort ein, die Sie in Kapitel 3 dem Skript zur Initialisierung der Datenbank über die Parameter intellixAdminUser und intellixAdminUserPassword übergeben haben. Die restlichen Werte müssen nicht angepasst werden. Speichern Sie die Datei wieder ab.

Sie können nun die Intelligent Indexing Verbindungsdatei in Ihre DocuWare Installation hochladen, um die Verbindung mit Intelligent Indexing herzustellen. Loggen Sie sich dazu in die DocuWare Administration ein und navigieren Sie zu DocuWare System -\&gt; Data Connections -\&gt; Intelligent Indexing Service connections. Falls hier schon eine Verbindung eingetragen ist, können Sie diese öffnen und unter Organizations Ihre Organisation entfernen und auf Apply klicken. Dadurch ist die Verbindung Ihres DocuWare Systems zu Ihrem alten Intelligent Indexing System deaktiviert, könnte aber durch erneutes Hinzufügen der Organisation wieder aktiviert werden. Klicken Sie anschließend mit der rechten Maustaste auf Intelligent Indexing Service connections auf der linken Seite und wählen Install Intelligent Indexing Service file aus. In dem sich öffnenden Dialog wählen Sie die von Ihnen editierte intelligent-indexing-connection.xml Datei aus. Klicken Sie anschließend auf Apply und schließen Sie die DocuWare Administration.

## Anhang

### Überblick über die Intelligent Indexing Setup-Dateien

Die folgenden Dateien müssen Sie im Laufe der Installation anpassen:

- Konfigurationsdatei configuration.env
- Intelligent Indexing Verbindungsdatei intelligent-indexing-connection.xml zum Herstellen der Verbindung zwischen DocuWare und Intelligent Indexing

Die restlichen Intelligent Indexing Setup-Dateien dürfen nicht verändert werden:

- Powershell Skripte
  - Install-Docker.ps1, Check-Docker.ps1, Install-IIS.ps1, Init-Database.ps1: Skripte zur Installation von Docker und des Webservers IIS und zur Initialisierung des Datenbankservers
  - Update-Intellix.ps1, Start-Intellix.ps1, Stop-Intellix.ps1 Skripte, um Intelligent Indexing zu updaten, starten und stoppen
  - Check-Intellix.ps1 Skript zum Überprüfen, ob die Intelligent Indexing Docker Container ausgeführt werden
  - Show-IntellixLogs.ps1 und Show-SolRLogs.ps1: Skripte, um Logausgaben von Intelligent Indexing und der SolR Volltextsuche anzuzeigen
  - Read-IntellixConfiguration.ps1 Dieses Skript wird von den anderen Skripten verwendet, um die Konfigurationsdatei zu lesen
- Datenbankskript init\_database.sql, um die Datenbank zu initialisieren
- Die docker-compose.yml Datei, die die Docker Umgebung benötigt, um das Zusammenspiel der Docker Container zu steuern
- Die docker\_registry\_password.txt Datei, die von den Skripten benötigt wird, um die Docker Images herunterladen zu können


### Manuelle Einrichtung des Datenbankservers

Folgende Schritte sind nötig, um die Intelligent Indexing Datenbank einzurichten. Diese werden auch von dem Skript Init-Database.ps1 ausgeführt.

- Führen Sie das Skript init\_database.sql im SQL Server Management Studio im SQLCMD Mode aus. Dadurch wird die Datenbank intellixv2 eingerichtet.
- Aktivieren Sie im SQL Server Management Studio den Modus SQL Server and Windows Authentication mode.
- Erzeugen Sie einen Login / User, der auf die Datenbank intellixv2 zugreifen darf.
- Aktivieren Sie den Zugriff auf den Datenbankserver über TCP über Port 1433.
- Starten Sie den Datenbankserver neu
- Erstellen Sie eine Regel in der Firewall auf dem Rechner des Datenbankservers, um eingehende Verbindungen über TCP Port 1433 zu erlauben.

Beachten Sie, dass der Zugriff über TCP und die Regel in der Firewall auch nötig sind, falls der Datenbankserver und Intelligent Indexing auf demselben Rechner installiert sind, da Intelligend Indexing innerhalb eines Docker Containers läuft.

[1](#sdfootnote1anc) Auf älteren Versionen des SQL Server kann die folgende Installation abweichen oder scheitern.

[2](#sdfootnote2anc) Das Skript zur Konfiguration der Datenbank aus Kapitel 3 verwendet Port 1433.