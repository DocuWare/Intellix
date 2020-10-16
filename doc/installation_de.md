# Installationsanleitung Intelligent Indexing V2

## Einleitung

Dieses Dokument beschreibt die Installation von DocuWare Intelligent Indexing
einschlißlich notwendigen Komponenten. Anleitungen zur Konfiguration vonIntelligent Indexing und
zur Arbeit mit Intelligent Indexing sind
als gesonderte Dokumente im [DocuWare Knowledge Center](https://help.docuware.com) zu finden.

### Systemvoraussetzungen

Folgende Voraussetzungen müssen für die Installation erfüllt sein:

- Windows Server 2019 (Standard oder Datacenter Edition)
- 2 Prozessorkerne
- 4 GB RAM
- Optional: Installierter SQL Server 2019

Es wird empfohlen, Intelligent Indexing auf einem eigenen Server zu installieren,
um bestmögliche Performance zu erreichen.
Um den Platzbedarf der Installation gering zu halten,
sollte Intelligent Indexing auf Windows Server Core (Installation ohne grafische Benutzeroberfläche)
installiert werden.
Wenn Sie Intelligent Indexing zusammen mit anderen Diensten auf einem Computer installieren,
Sie sollten sicherstellen, dass keine andere Anwendung Port 8080 verwendet.

Die Installation erfordert Administratorrechte und eine Internetverbindung.
Alle Befehle in den folgenden Anweisungen müssen in PowerShell eingegeben werden.
Sie können PowerShell 5 oder PowerShell 7 verwenden.

> :bulb: Wenn Sie die Skripte in der PowerShell ISE ausführen möchten,
> stellen wechseln Sie in der ISE zum Verzeichnis __scripts__
> innerhalb des extrahierten Archivs.

### Überblick über die benötigten Dateien

Das Archiv mit den Installationsdateien kann von
[unserem GitHub-Repository](https://github.com/DocuWare/Intellix/archive/master.zip) heruntergeladen werden.
Nach dem Download extrahieren Sie das Archiv.

Sie können die Datei auch mit folgendem Powershell-Skript herunterladen und extrahieren.
Wechseln Sie zuvor mit der Powershell in das Zielverzeichnis für den Download:

```powershell
$tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
Invoke-WebRequest https://github.com/DocuWare/Intellix/archive/master.zip -OutFile $tmp
Expand-Archive $tmp -DestinationPath master
$tmp | Remove-Item
```

Zur Installation und Betrieb von Intelligent Indexing wird der Inhalt des Verzeichnisses `scripts` benötigt. Kopieren Sie dieses Verzeichnis an eine Stelle, die Sie dauerhaft verwenden wollen. Dieses Verzeichnis wird im Folgenden als _Installationsverzeichnis_ bezeichnet.

> :bulb: Wenn Sie das Archiv mit einem Browser herunterladen, sollten Sie die heruntergeladene
> Datai vor der Extraction entsperren. Andernfalls werden Sie während der Installation wiederholt
> gefragt, ob Sie den Installationsskripten vertrauen. können Rückrufe auftreten, wenn das Setup ausgeführt wird. 
> Um die Archivdatei zu entsperren, klicken Sie mit der rechten Maustaste auf das Archiv
> und deaktivieren Sie die Blockierung im Fenster mit den Dateieigenschaften.
>
> Wenn das Archiv schon ausgepackt wurde, können Sie in das Extraktionsverzeichnis wechseln
> und die Sperren mit PowerShell aufheben:
>  ```powershell
>  Get-ChildItem -Recurse | Unblock-File
>  ```

Im [Anhang](#überblick-über-die-intelligent-indexing-setup-dateien) finden Sie eine Übersicht über die einzelnen Dateien. Zusätzlich benötigen Sie Ihre DocuWare Lizenzdatei, welche Sie im [DocuWare Partner Portal](http://go.docuware.com/partnerportal-login) herunterladen können.

### Docker Containerisierung

Intelligent Indexing läuft virtualisiert in zwei Docker Containern. Diese laufen unabhängig von anderen Anwendungen, die auf Ihrem Host-Rechner installiert sind, und werden vorkonfiguriert ausgeliefert. Der Installationsaufwand für Intelligent Indexing V2 ist dadurch sehr niedrig.

Die Docker Container sind:

- __intellix-app__: Intelligent Indexing
- __intellix-solr__: Die SolR Volltextsuchmaschine
- __intellix-sql__: SQL Express, falls Sie keinen eigenen SQL Server benutzen

### Überblick über die Anleitung

Die Installation gliedert sich in folgende Schritte:

- [Skripte ausführen erlauben](#skripte-ausführen-erlauben)
- [Installation der Docker Umgebung](#installation-der-docker-umgebung)
- [Installation des Datenbankservers](#installation-des-datenbankservers)
- [Setup](#setup)
- [Installation des Webservers IIS](#installation-des-webservers-iis)
- [Verwaltung von Intelligent Indexing](#verwaltung-von-intelligent-indexing)
- [Intelligent Indexing lizenzieren](#intelligent-indexing-lizenzieren)
- [Verbindung zu DocuWare](#verbindung-zu-docuWare)
- [Troubleshooting](#troubleshooting)

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

Nach Ausführen des Kommandos können __in der aktuellen Powershell-Sitzung__
alle Kommandos ausgeführt werden.
Dieses Kommando müssen Sie in jedem Powershell-Fenster erneut ausführen.

Falls Sie die Sperre komplett aufheben wollen, können Sie für den Scope auch `CurrentUser` oder `LocalMachine` verwenden.

## Installation der Docker Umgebung

Intelligent Indexing läuft in Docker Containern. Dazu muss zuerst eine Docker Umgebung installiert werden. Wechseln Sie in einer Powershell als Administrator in das Installationsverzeichnis und führen folgenden Befehl aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-Docker.ps1
```

Starten Sie anschließend den Host-Rechner neu:

```powershell
Restart-Computer
```

Nach dem Neustart können Sie testen, ob die Docker-Umgebung und docker-compose korrekt installiert sind:

```powershell
docker run --rm --name helloworld hello-world:nanoserver
```

Nach dem Herunterladen und Starten des Docker-Images sollte die folgende Ausgabe angezeigt werden:

```text
Hello from Docker!

This message shows that your installation appears to be working correctly.
```

Nach

```cmd
docker-compose --version
```

sollten Sie folgende Zeile sehen:

```text
docker-compose version...
```

## Installation of the Database Server

Für die Installation der Datenbank haben Sie folgende Möglichkeiten:

### Option 1: Verwenden Sie SQL Server Express als Container-Image

Dies wird für die meisten Installationen empfohlen.
In diesem Szenario ist die Installation von Intelligent Indexing sehr einfach,
da keine weitere Konfiguration des Datenbankservers erforderlich ist.
Sie müssen sich nicht um die Einrichtung und Konfiguration der Datenbank kümmern -
diese wird vollständig vom Setup-Skript verwaltet.

SQL Express begrenzt jedoch die Größe der gespeicherten Daten.
Wenn Sie ein sehr hohes Datenvolumen erwarten (d.h. mehrere tausend Dokumente pro Tag),
sollten Sie sich für die andere Option entscheiden.
Wenn die Größenbeschränkung später zu einem Problem wird,
können Sie jederzeit Ihren eigenen Datenbankserver migrieren.

### Option 2: Verwenden Sie Ihren eigenen Datenbankserver

Sie sollten diese Option wählen, wenn Sie ein hohes Dokumentenvolumen erwarten
oder die vollständige Kontrolle über die Intelligent Indexing-Datenbank
haben möchten. Intelligent Indexing benötigt SQL Server 2019.
Bei älteren Versionen von SQL Server schlägt die Einrichtung fehl.
Wenn Sie einen SQL Server 2019 für Ihr DocuWare-System verwenden,
können Sie ihn auch für die Intelligent Indexing verwenden.

Wenn Sie Ihren eigenen SQL Server einrichten möchten, können Sie
[SQL Server 2019 Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) verwenden.
Laden Sie es herunter und folgen Sie den Anweisungen zum Einrichten.

Es ist wichtig, dass Ihr SQL Server folgendermaßen konfiguriert ist:

- TCP-Verbindungen an Port 1433.
- Die SQL Server-Authentifizierung muss aktiviert sein.
  Die Container unterstützen keine integrierte Authentifizierung.
- Für das Setup-Skript sollte ein SQL Server-Konto verfügbar sein.
  Dieses Konto muss über die Berechtigung zum Erstellen einer neuen Datenbank verfügen.
- In der Firewall müssen die Ports so konfiguriert sein, dass Docker-Container
  eine Verbindung zur Datenbank herstellen können.

Beachten Sie, dass für die Intelligent Indexing _self-contained databases_ erforderlich sind. Daher wird das folgende SQL vom Setup-Skript ausgeführt:

```sql
sp_configure 'contained database authentication', 1
GO
RECONFIGURE
GO
```

Wenn dies nicht gewünscht ist, sollten Sie eine separate SQL Server-Instanz für die Intelligent Indexing
installieren.

## Setup

Das Setup konfiguriert die Datenbank und die Containerinfrastruktur.
Wenn das Setup ausgeführt wird, werden einige Container-Images
heruntergeladen und der Container, der das Datenbank-Setup enthält,
wird erstellt und ausgeführt.

Das Setup erstellt eine Verzeichnisstruktur unter `C:\ProgramData\IntellixV2`,
wo die Dateien für Intelligent Indexing abgelegt werden.
Bitte berücksichtigen Sie dieses Verzeichnis in Ihren Backups.
Verwenden Sie Junctions, um dieses Verzeichnis an einen externen Speicher anzuhängen.

Das Setup wird durch Ausführen von  `Setup-Intellix.ps1` im Verzeichnus `setup` gestartet.
Sie können die folgenden Parameter angeben:

- `IntellixDbUser` und `IntellixDbPassword`: Dies sind die Zugangsdaten, die
  Intelligent Indexing verwendet, um auf die Datenbank zuzugreifen.
  Sie sollten starke Passwörter verwenden, welche der
  [SQL Server password policy](https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver15) entspricht.
  Diese Werte brauchen nur bei der Ersteinrichtung angegeben werden.
  
  Dieses SQL-Konto mit den angegebenen Anmeldeinformationen wird in der Intellixv2-Datenbank erstellt.
  Auf Ihrem SQL Server werden keine Anmeldungen erstellt.
  
  :bulb: Diese Werte sollten nur bei der Ersteinrichtung angegeben werden.
  Wenn Sie das Setup ein zweites Mal ausführen, werden die Werte nicht mehr benötigt.

- `IntellixAdminUser` and `IntellixAdminPassword`: Dies sind die Anmeldeinformationen,
  mit denen DocuWare auf die Intelligent Indexing zugreift. Das Kennwort sollte sicher sein,
  darf jedoch keine der folgenden 5 Sonderzeichen enthalten: `& < > " '`.
  
  :bulb: Diese Werte sollten nur bei der Ersteinrichtung angegeben werden.
  Wenn Sie das Setup ein zweites Mal ausführen, werden die Werte nicht mehr benötigt.

- `LicenseFile`: Der Pfad zur Lizenzdatei. Wenn die Lizenzdatei im Setup nicht angegeben ist,
  kann sie nach dem Setup in der Benutzeroberfläche von Intelligent Indexing hochgeladen werden.

  :bulb: Um den Dienst direkt nach der Installation zu verwenden,
  wird empfohlen, die Lizenzdatei beim Ausführen des Setups anzugeben.  
  Wenn Sie keine Lizenzdatei haben, besuchen Sie die
  [DocuWare Partner Portal](http://go.docuware.com/partnerportal-login).

- `SqlServerInstance`, `SqlServerInstanceUser` and `SqlServerInstancePassword`:
  Diese Werte geben die Instanz und die Anmeldeinformationen für den Zugriff auf Ihren eigenen SQL Server an
  
  :warning: Wenn Sie den containerisierten SQL Server verwenden, dürfen Sie diese Parameter nicht angeben.

Sie können die Datenbanken einer alte Version von Intelligent Indexing und Intelligent Indexing Version 2
auf demselben Datenbankserver ablegen.
Die alte Version verwendet die
`intellix`-Datenbank, die aktuelle Version verwendet die `intellixv2`-Datenbank.

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
- Die nächsten Einträge legen verschiedene Verzeichnisse auf dem Host-Rechner fest. Unter `E_FileStoragePath` werden Dokumentinformationen gespeichert. Unter `E_SolRDataPath` werden die Daten der SolR Volltextsuchmaschine gespeichert. Der Inhalt beider Verzeichnisse wächst pro Dokument und kann mehrere GB betragen. Sie können diese Verzeichnisse auch später noch ändern, während Intelligent Indexing gestoppt ist. Dazu müssen Sie auch den Inhalt der Verzeichnisse an die neue Stelle kopieren. Alle diese Verzeichnise sind unabhängig vom Installationsverzeichnis, in dem die Intelligent Indexing Setup-Dateien abgelegt sind.

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

Nach dem Starten von Intelligent Indexing können Sie in einem Browser auf dem Host-Rechner nach <http://localhost/intellix-v2/Html> navigieren, um die Administrationsoberfläche aufzurufen. Bei der Verwendung des Internet Explorers kann es hierbei zu Problemen kommen. Verwenden Sie in diesem Fall einen anderen Browser.

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
