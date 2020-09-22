# Installationsanleitung Intelligent Indexing V2

__Beta Test__

> :warning: Diese Version von Intelligent Indexing ist nur für den geschlossenen Beta Test gedacht und darf nicht produktiv eingesetzt werden.

## Einleitung

Dieses Dokument beschreibt die Installation von DocuWare Intelligent Indexing sowie aller zusätzlich notwendigen Komponenten. Anleitungen zur Konfiguration von Intelligent Indexing und zur Arbeit mit Intelligent Indexing existieren als gesonderte Dokumente im [DocuWare Knowledge Center](https://help.docuware.com).

### Systemvoraussetzungen

Folgende Voraussetzungen müssen für die Installation erfüllt sein:

- Neu aufgesetztes Windows Server 2019 (Build 1809)
- 8 Prozessorkerne
- 16 GB RAM
- Zugriff auf SQL Server 2019

Es wird empfohlen, Intelligent Indexing auf einem eigenen Server zu installieren, um eine bestmögliche Performance zu erreichen. Intelligent Indexing ist nutzbar in Kombination mit DocuWare ab Version 6.1. Falls Sie für Ihr DocuWare System oder für eine bestehende Intelligent Indexing Installation einen SQL Server 2019 verwenden, können Sie diesen auch für Intelligent Indexing V2 verwenden. Ansonsten müssen Sie einen eigenen SQL Server aufsetzen.

Für die im Folgenden beschriebene Installation sind Administratorrechte sowie eine Internetverbindung nötig.

### Überblick über die benötigten Dateien

Zum Download der Installationsdateien klicken Sie unter [https://github.com/DocuWare/Intellix](https://github.com/DocuWare/Intellix) auf den grünen Button `Code` und dann auf `Download ZIP` und extrahieren Sie die Datei. Sie können die Datei auch mit folgendem Powershell-Skript herunterladen und extrahieren. Wechseln Sie zuvor mit der Powershell in das Zielverzeichnis für den Download:

```powershell
$tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
Invoke-WebRequest https://github.com/DocuWare/Intellix/archive/master.zip -OutFile $tmp
Expand-Archive $tmp -DestinationPath master
$tmp | Remove-Item
```

Zur Installation und Betrieb von Intelligent Indexing wird  der Inhalt des Verzeichnisses `scripts` benötigt. Kopieren Sie dieses Verzeichnis an eine Stelle, die Sie dauerhaft verwenden wollen. Dieses Verzeichnis wird im Folgenden als Installationsverzeichnis bezeichnet.

Sie können das komplette Verzeichnis aber auch später an eine andere Stelle verschieben.

Im [Anhang](#überblick-über-die-intelligent-indexing-setup-dateien) finden Sie eine Übersicht über die einzelnen Dateien. Zusätzlich benötigen Sie Ihre DocuWare Lizenzdatei, welche Sie im [DocuWare Partner Portal](https://login.docuware.com) herunterladen können.

### Docker Containerisierung

Intelligent Indexing läuft virtualisiert in zwei Docker Containern. Diese laufen unabhängig von anderen Anwendungen, die auf Ihrem Host-Rechner installiert sind, und werden vorkonfiguriert ausgeliefert. Der Installationsaufwand für Intelligent Indexing V2 ist dadurch sehr niedrig.

Die Docker Container sind:

- __intellix_app__: Der Code von Intelligent Indexing
- __intellix_solr__: Die SolR Volltextsuchmaschine

Zusätzlich wird eine SQL Server Datenbank benötigt, die außerhalb der Docker Container läuft.

### Überblick über die Anleitung

Die Installation gliedert sich in folgende Schritte:

- [Skripte ausführen erlauben](#skripte-ausführen-erlauben)
- [Installation der Docker Umgebung](#installation-der-docker-umgebung)
- [Installation des Datenbankservers](#installation-des-datenbankservers)
- [Installation des Webservers IIS](#installation-des-webservers-iis)
- [Verwaltung von Intelligent Indexing](#verwaltung-von-intelligent-indexing)
- [Intelligent Indexing lizenzieren](#intelligent-indexing-lizenzieren)
- [Verbindung zu DocuWare](#verbindung-zu-docuWare)

## Skripte ausführen erlauben

Windows Server unterbindet das Ausführen von Powershell-Skripten standardmäßig. Für den Installationsprozess müssen daher die Berechtigungen angepasst werden.

Um die aktuelle Einstellung zu prüfen, führen Sie als Administrator in der Powershell folgenden Befehl aus:

```powershell
Get-ExecutionPolicy
```

Wird als Ergebnis `Unrestricted` angezeigt, müssen Sie nichts ändern. Wird ein anderer Wert als `Unrestricted` angezeigt, müssen Sie über folgenden Befehl das Ausführen von unsignierten Skripten erlauben:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
```

Nach Ausführen des Kommandos können __in der aktuellen Powershell-Sitzung__ alle Kommandos ausgeführt werden. Dieses Kommando müssen Sie in jedem Powershell-Fenster erneut ausführen. 

Falls Sie die Sperre komplett aufheben wollen, können Sie für den Scope auch `CurrentUser` oder `LocalMachine` verwenden.

## Installation der Docker Umgebung

Intelligent Indexing läuft in Docker Containern. Dazu muss zuerst eine Docker Umgebung installiert werden. Wechseln Sie in einer Powershell als Administrator in das Installationsverzeichnis und führen folgenden Befehl aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-Docker.ps1
```

Die Warnung, dass die Eigenschaften `version` und `Properties` nicht vorhanden sind, können Sie ignorieren.

Starten Sie anschließend den Host-Rechner neu:

```powershell
Restart-Computer
```

Warten Sie nach dem Neustart ca. eine Minute und führen Sie anschließend in der Powershell als Administrator im Installationsverzeichnis folgenden Befehl aus, um die Docker Installation zu testen:

```powershell
docker run --rm --name helloworld hello-world:nanoserver
docker-compose --version
```

Es wird dazu ein Docker Container mit ca. 100 MB heruntergeladen und gestartet. Falls Docker korrekt installiert wurde, ist dann unter anderem folgende Ausgabe zu sehen:

```text
Hello from Docker!

This message shows that your installation appears to be working correctly.
```

Prüfen Sie auch, ob Sie in der letzten Zeile der Ausgabe die Zeile

```text
docker-compose version...
```

sehen können. Dadurch ist sichergestellt, dass auch Docker-Compose richtig installiert wurde, das für das Zusammenspiel der Docker Container benötigt wird.

## Installation des Datenbankservers

Intelligent Indexing funktioniert zusammen mit einer SQL Server 2019 Datenbank. Auf älteren Versionen des SQL Server kann die folgende Installation abweichen oder scheitern. Falls Sie für Ihr DocuWare System einen SQL Server 2019 verwenden, können Sie diesen auch für Intelligent Indexing verwenden. Ansonsten müssen Sie einen separaten SQL Server aufsetzen.

Falls Sie einen separaten Datenbankserver für Intelligent Indexing aufsetzen, können Sie den kostenlosen SQL Server 2019 Express verwenden. Dieser ist allerdings auf 10 GB Speicher beschränkt, was in etwa für 1.000.000 einfache Dokumente Platz bietet. Sie können ihn unter folgendem Link herunterladen: [https://www.microsoft.com/de-de/sql-server/sql-server-downloads](https://www.microsoft.com/de-de/sql-server/sql-server-downloads).

Der direkte Download und die Installation können mit folgenden Kommandos durchgeführt werden:

```powershell
Invoke-WebRequest https://go.microsoft.com/fwlink/?linkid=866658 -OutFile SQL2019-SSEI-Expr.exe

.\SQL2019-SSEI-Expr.exe
```

Zu Beginn der Installation können Sie die Variante Basic wählen. Falls Sie während der Installation des Datenbankservers nach einer Collation gefragt werden, empfehlen wir die Collation `SQL_Latin1_General_CP1_CI_AS`. Wählen Sie am Ende der Installation aus, auch das SQL Server Management Studio (SSMS) zu installieren. Danach ist ein Neustart des Rechners nötig.

Falls Sie einen neu aufgesetzten SQL Server verwenden, können Sie die Datenbank über ein Powershell Skript konfigurieren, das sie lokal auf dem Rechner des Datenbankservers ausführen. Gegebenenfalls müssen Sie dazu die Intelligent Indexing Setup-Dateien auf den Rechner mit dem Datenbankserver kopieren.

Führen Sie dort als Administrator in einer Powershell folgendes Skript im Installationsverzeichnis aus. Falls Sie gerade den SQL Server Express installiert haben, führen Sie folgende Kommandos __in einem neuen Powershell-Fenster__ aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Init-Database.ps1
```

Dabei müssen Sie folgende Parameter angeben:

- `dbIntellixUser` und `dbIntellixUserPassword`: Das sind die Zugangsdaten für die Datenbank, mit denen Intelligent Indexing auf die Datenbank zugreifen wird. Diese Werte müssen Sie im Abschnitt [Konfiguration von Intelligent Indexing](#konfiguration-von-intelligent-indexing) in die Konfigurationsdatei eintragen. Der SQL Server setzt ein starkes Passwort voraus. Details dazu finden Sie unter <https://docs.microsoft.com/de-de/sql/relational-databases/security/password-policy?view=sql-server-ver15>
- `serverInstance`: Dieser Wert legt den Namen der Datenbankserver Instanz, z.B. `SQLEXPRESS`, fest.
- `intellixAdminUser` und `intellixAdminUserPassword`: Das sind die Zugangsdaten, mit denen DocuWare auf Intelligent Indexing zugreifen wird. Diese Werte müssen Sie im Abschnitt [Verbindung zu DocuWare](#verbindung-zu-docuWare) in die Intelligent Indexing Verbindungsdatei eintragen. Das Passwort sollte sicher sein, aber keines der folgenden 5 Sonderzeichen enthalten, da diese in der Verbindungsdatei zu Problemen führen können: `& < > " '`

Die Parameter können dem Skript auch mitgegeben werden:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Init-Database.ps1 -serverInstance SQLEXPRESS -dbIntellixUser intellix -dbIntellixUserPassword MyVerySeKRe!tPasSw0rD -intellixAdminUser intellixAdmin -intellixAdminUserPassword an00tHerVerySeKRe!tPasSw0rD
```

Das Skript wird den Datenbankserver neustarten. Falls Sie das nicht möchten oder die Einrichtung an Ihre Situation anpassen müssen, finden Sie im [Anhang](#manuelle-einrichtung-des-datenbankservers) eine Übersicht, welche Schritte ausgeführt werden und wie diese manuell im SQL Server Management Studio durchgeführt werden können.

Falls Sie eine alte Version von Intelligent Indexing On-Premise auf demselben Datenbankserver betreiben, können Sie Intelligent Indexing V2 parallel dazu installieren. Die alte Version verwendet die Datenbank `intellix`, die aktuelle Version die Datenbank `intellixv2`.

Loggen Sie sich als Test über das SQL Server Management Studio auf dem Datenbankserver ein. Setzen Sie den `Server name` aus dem Namen des Rechners des Datenbankservers, der Server Instanz und dem Port `1433`, also z.B. `intellix\SQLEXPRESS,1433`, zusammen. Wählen Sie als `Authentication` den Wert `SQL Server Authentication`. Verwenden Sie als `Login` und `Password` die von Ihnen oben gewählten Werte für die Parameter `dbIntellixUser` und `dbIntellixUserPassword`. Auf dem Datenbankserver muss unter dem Eintrag `Databases` die Datenbank `intellixv2` vorhanden sein.

## Installation des Webservers IIS

Zur Installation führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-IIS.ps1
```

Das Skript installiert den Webserver IIS mit den Komponenten `UrlRewrite` und `ARR`.

Falls Sie eine Verbindung über `https` verwenden wollen, müssen Sie in der Oberfläche des IIS unter `Sites` -> `Default Web Site` rechts auf `Bindings...` klicken und dort unter dem `https` Binding ein gültiges Zertifikat hinterlegen und das Zertifikat in den entsprechenden Zertifikatsspeichern ablegen. In der Verbindungsdatei (siehe [Verbindung zu DocuWare](#verbindung-zu-docuWare)) können Sie dann `https` statt `http` eintragen.

## Verwaltung von Intelligent Indexing

### Konfiguration von Intelligent Indexing

Im Installationsverzeichnis finden Sie eine Datei `configuration.env` zur Konfiguration von Intelligent Indexing. Passen Sie folgende Werte an Ihre Installation an und speichern Sie die Datei anschließend wieder ab:

- `ConnectionStrings:IntellixDatabaseEntities`: Der Connection String für die Datenbankverbindung. Ändern Sie hier die Werte für `Server`, `user id` und `password` entsprechend Ihres Datenbankservers ab. `user id` und `password` entsprechen den Parametern `dbIntellixUser` und `dbIntellixUserPassword`, die sie im Abschnitt [Installation des Datenbankservers](#installation-des-datenbankservers) dem Skript zur Konfiguration der Datenbank übergeben haben. `Server` ist der Name des Datenbankservers. Falls der Datenbankserver auf dem Host-Rechner installiert ist, müssen Sie als Namen für den Rechner wie voreingestellt `$$internalgw$$` verwenden. Falls Sie keinen SQL Server Express oder nicht den Port `1433` verwenden, müssen Sie die Einträge entsprechend ändern. Das Skript zur Einrichtung der Datenbank aus dem Abschnitt [Installation des Datenbankservers](#installation-des-datenbankservers) verwendet den Port `1433`.
- Die nächsten Einträge legen verschiedene Verzeichnisse auf dem Host-Rechner fest. Unter `E_FileStoragePath` werden Dokumentinformationen gespeichert. Unter `E_SolRDataPath` werden die Daten der SolR Volltextsuchmaschine gespeichert. Der Inhalt beider Verzeichnisse wächst pro Dokument und kann mehrere GB betragen. Unter `E_DataProtectionKeysPath` werden Daten zum Verschlüsseln von Cookies abgelegt. Sie können diese Verzeichnisse auch später noch ändern, während Intelligent Indexing gestoppt ist. Dazu müssen Sie auch den Inhalt der Verzeichnisse an die neue Stelle kopieren. Alle diese Verzeichnise sind unabhängig vom Installationsverzeichnis, in dem die Intelligent Indexing Setup-Dateien abgelegt sind.

Änderungen an diesen Werten greifen erst nach einem Neustart von Intelligent Indexing.

### Installation von Intelligent Indexing

Zur Installation führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1
```

Dadurch werden die aktuellen Docker Images von Intelligent Indexing heruntergeladen. Diese werden von der Docker Umgebung automatisch verwaltet. Die Größe der Docker Images beträgt mehrere GB.

### Starten von Intelligent Indexing

Zum Starten von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Start-Intellix.ps1
```

Beim erstmaligen Starten von Intelligent Indexing werden die Verzeichnisse angelegt, die Sie in der Konfigurationsdatei angegeben haben.

### Testen der Komponenten von Intelligent Indexing und Passwort ändern

Über folgendes Skript können Sie überprüfen, welche Docker Container gerade auf dem Host-Rechner laufen:

```powershell
docker ps -a
```

Sie sollten für die Docker Container __intellix_app__ und __intellix_solr__ je eine Zeile als Ausgabe erhalten. In der Spalte `Status` können Sie sehen, ob die Docker Container laufen (`Up...`) oder beendet wurden (`Exited...`). Außerdem können Sie in dieser Spalte sehen, ob die Container prinzipiell erreichbar sind. Beim Starten wird hier (`health: starting`) angezeigt. Wenn die Container erfolgreich auf Anfragen antworten, wird (`healthy`) angezeigt.

Nach dem Starten von Intelligent Indexing können Sie in einem Browser auf dem Host-Rechner nach <http://localhost/intellix-v2/Html> navigieren, um die Administrationsoberfläche aufzurufen.

Sie können sich mit dem Benutzernamen und dem Passwort einloggen, die Sie im Abschnitt [Installation des Datenbankservers](#installation-des-datenbankservers) dem Skript zur Initialisierung der Datenbank über die Parameter `intellixAdminUser` und `intellixAdminUserPassword` übergeben haben.

Testen Sie hier auch, ob Sie den Host-Rechner von dem Rechner aus, auf dem DocuWare installiert ist, über einen Browser erreichen können. Rufen Sie von einem anderen Rechner die URL <http://_rechnername_/intellix-v2/Html/> auf und ersetzen _\_rechnername\__ durch den Namen des Host-Rechners.

Unter <http://localhost:8983> können Sie die SolR Volltextsuchmaschine von Ihrem Host-Rechner aus erreichen.

### Logging

Zum Loggen von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Show-IntellixLogs.ps1
```

Zum Loggen der SolR Volltextsuchmaschine führen Sie das folgende Skript aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Show-SolrLogs.ps1
```

In beiden Skripten werden Logausgaben live angezeigt. Die Ausgaben könnten durch Drücken von `Strg+C` abgebrochen werden.

### Stoppen von Intelligent Indexing

Zum Stoppen von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Stop-Intellix.ps1
```

### Update von Intelligent Indexing

Verwenden Sie folgendes Skript, um zu prüfen, ob Updates oder Hotfixes für Intelligent Indexing vorhanden sind und diese gegebenenfalls herunterzuladen:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1
```

Nicht mehr benötigte Docker Images werden automatisch gelöscht. Die Downloadgröße wird in den meisten Fällen mehrere 100 MB betragen. Sie können dieses Skript ausführen, während Intelligent Indexing läuft. Die Änderungen werden erst aktiv, wenn sie nach Beendigung dieses Skripts `Stop-Intellix.ps1` und `Start-Intellix.ps1` ausführen. Auch ein Neustart des Host-Rechners führt ein heruntergeladenes Update nicht durch.

### Neustart des Host-Rechners

Die Docker Umgebung verwaltet die laufenden Intelligent Indexing Container. Diese sind so konfiguriert, dass Intelligent Indexing bei einem Neustart des Host-Rechners heruntergefahren und automatisch wieder gestartet wird. Falls Intelligent Indexing vor dem Neustart nicht lief, wird es auch danach nicht gestartet.

## Intelligent Indexing lizenzieren

Im [DocuWare Partner Portal](https://login.docuware.com) können Sie die DocuWare Lizenzdatei herunterladen. In der Intelligent Indexing Administrationsoberfläche können Sie diese unter dem Punkt `Licensing` hochladen und damit Ihre Intelligent Indexing Installation lizenzieren.

## Verbindung zu DocuWare

Im Installationsverzeichnis befindet sich die Intelligent Indexing Verbindungsdatei `intelligent-indexing-connection.xml`, mit deren Hilfe DocuWare die Verbindung zu Intelligent Indexing aufbauen kann.

Öffnen Sie diese Datei in einem Texteditor. Tragen Sie in Zeile 3 die Adresse ein, unter der der Host-Rechner von dem Rechner mit der DocuWare Installation aus erreichbar war, aber ohne `Html` am Ende. Der Name des Host-Rechners bzw. dessen statische IP-Adresse muss also statt `localhost` eintragen werden. Falls Sie z.B. Intelligent Indexing von Ihrem DocuWare Rechner unter `http://intellix/intellix-v2/Html` erreichen konnten, tragen Sie hier `http://intellix/intellix-v2/` ein. Falls Sie den Webserver für eine Verbindung über `https` konfiguriert haben (siehe [Installation des Webservers IIS](#installation-des-webservers-iis)), können Sie hier `https` statt `http` eintragen.

Tragen Sie in Zeile 4 und 5 den Nutzer und das Passwort ein, die Sie im Abschnitt [Installation des Datenbankservers](#installation-des-datenbankservers) dem Skript zur Initialisierung der Datenbank über die Parameter `intellixAdminUser` und `intellixAdminUserPassword` übergeben haben. In Zeile 6 wird der Name des Modelspaces festgelegt. Tragen Sie hier `Default_` gefolgt von dem von Ihnen gewählten Nutzer ein. Falls Sie z.B. `admin` als Nutzer gewählt haben, sollten Sie hier `Default_admin` eintragen. Die restlichen Werte müssen nicht angepasst werden. Speichern Sie die Datei wieder ab.

Sie können nun die Intelligent Indexing Verbindungsdatei in Ihre DocuWare Installation hochladen, um die Verbindung mit Intelligent Indexing herzustellen. Loggen Sie sich dazu in die DocuWare Administration ein und navigieren Sie zu `DocuWare System` -> `Datenverbindungen` -> `Verbindungen Intelligent Indexing Service`. Falls hier schon eine Verbindung eingetragen ist, können Sie diese öffnen und unter Organizations Ihre Organisation entfernen und auf `Übernehmen` klicken. Dadurch ist die Verbindung Ihres DocuWare Systems zu Ihrem alten Intelligent Indexing System deaktiviert, könnte aber durch erneutes Hinzufügen der Organisation wieder aktiviert werden. Klicken Sie anschließend mit der rechten Maustaste auf `Verbindungen Intelligent Indexing Service` auf der linken Seite und wählen `Installiere Datei von Intelligent Indexing Service` aus. In dem sich öffnenden Dialog wählen Sie die von Ihnen editierte `intelligent-indexing-connection.xml` Datei aus. Klicken Sie anschließend auf `Übernehmen` und schließen Sie die DocuWare Administration.

## Anhang

### Überblick über die Intelligent Indexing Setup-Dateien

Die folgenden Dateien müssen Sie im Laufe der Installation anpassen:

- Konfigurationsdatei `configuration.env`
- Intelligent Indexing Verbindungsdatei `intelligent-indexing-connection.xml` zum Herstellen der Verbindung zwischen DocuWare und Intelligent Indexing

Die restlichen Intelligent Indexing Setup-Dateien dürfen nicht verändert werden:

- Powershell Skripte
  - `Install-Docker.ps1`, `Install-IIS.ps1`, `Init-Database.ps1`: Skripte zur Installation von Docker und des Webservers IIS und zur Initialisierung des Datenbankservers
  - `Update-Intellix.ps1`, `Start-Intellix.ps1`, `Stop-Intellix.ps1`: Skripte, um Intelligent Indexing zu updaten, starten und stoppen
  - `Show-IntellixLogs.ps1` und `Show-SolRLogs.ps1`: Skripte, um Logausgaben von Intelligent Indexing und der SolR Volltextsuche anzuzeigen
  - `Read-IntellixConfiguration.ps1`: Dieses Skript wird von den anderen Skripten verwendet, um die Konfigurationsdatei zu lesen
- Datenbankskript `init_database.sql`, um die Datenbank zu initialisieren
- Die `docker-compose.yml` Datei, die die Docker Umgebung benötigt, um das Zusammenspiel der Docker Container zu steuern

### Manuelle Einrichtung des Datenbankservers

Folgende Schritte sind nötig, um die Intelligent Indexing Datenbank einzurichten. Diese werden auch von dem Skript `Init-Database.ps1` ausgeführt.

- Führen Sie das Skript `init_database.sql` im SQL Server Management Studio im `SQLCMD Mode` aus. Dadurch wird die Datenbank `intellixv2` eingerichtet.
- Aktivieren Sie im SQL Server Management Studio den Modus `SQL Server and Windows Authentication mode`.
- Erzeugen Sie einen Login / User, der auf die Datenbank `intellixv2` zugreifen darf.
- Aktivieren Sie den Zugriff auf den Datenbankserver über TCP über Port `1433`.
- Starten Sie den Datenbankserver neu
- Erstellen Sie eine Regel in der Firewall auf dem Rechner des Datenbankservers, um eingehende Verbindungen über TCP Port `1433` zu erlauben.

Beachten Sie, dass der Zugriff über TCP und die Regel in der Firewall auch nötig sind, falls der Datenbankserver und Intelligent Indexing auf demselben Rechner installiert sind, da Intelligent Indexing innerhalb eines Docker Containers läuft.
