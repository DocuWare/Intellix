# Installationsanleitung Intelligent Indexing On Premises Version 2

## Einleitung

Dieses Dokument beschreibt die Installation von DocuWare Intelligent Indexing
einschließlich der notwendigen Komponenten. Anleitungen zur Konfiguration von Intelligent Indexing und
zur Arbeit mit Intelligent Indexing sind
als gesonderte Dokumente im [DocuWare Knowledge Center](https://help.docuware.com) zu finden.

### Systemvoraussetzungen

Folgende Voraussetzungen müssen für die Installation erfüllt sein:

- Windows Server 2019 oder Windows Server 2022 (Standard oder Datacenter Edition)
- 2 Prozessorkerne
- 4 GB RAM
- Optional: Installierter SQL Server 2019

Um bestmögliche Performance zu erreichen, empfehlen wir,
Intelligent Indexing auf einem eigenen Server 
oder auf einer eigenen virtuellen Maschine zu installieren.
Im Falle einer virtuellen Maschine wird ausschließlich
Hyper-V unterstützt.

Um den Platzbedarf der Installation gering zu halten,
sollte Intelligent Indexing auf Windows Server Core (Installation ohne grafische Benutzeroberfläche)
installiert werden.
Wenn Sie Intelligent Indexing zusammen mit anderen Diensten auf einem Computer installieren,
sollten Sie sicherstellen, dass keine andere Anwendung Port 8080 verwendet.


Die Installation erfordert Administratorrechte und eine Internetverbindung.
Alle Befehle in den folgenden Anweisungen müssen in PowerShell eingegeben werden.
Sie können PowerShell 5 oder PowerShell 7 verwenden. PowerShell ISE wird nicht unterstützt.

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

Zur Installation und zum Betrieb von Intelligent Indexing wird der
Inhalt des Verzeichnisses `windows` benötigt. Kopieren Sie dieses
Verzeichnis an eine Stelle, die Sie dauerhaft verwenden wollen.

> :bulb: Wenn Sie das Archiv mit einem Browser herunterladen, sollten Sie die heruntergeladene
> Datei vor der Extraktion entsperren. Andernfalls werden Sie während der Installation wiederholt
> gefragt, ob Sie den Installationsskripten vertrauen. 
> Um die Archivdatei zu entsperren, klicken Sie mit der rechten Maustaste auf das Archiv
> und deaktivieren Sie die Blockierung im Fenster mit den Dateieigenschaften.
>
> Wenn das Archiv schon ausgepackt wurde, können Sie in das Extraktionsverzeichnis wechseln
> und die Sperren mit PowerShell aufheben:
>  ```powershell
>  Get-ChildItem -Recurse | Unblock-File
>  ```

[Am Ende dieses Dokumentes](#überblick-über-die-intelligent-indexing-setup-dateien)
finden Sie eine Übersicht über die einzelnen Dateien.
Zusätzlich benötigen Sie Ihre DocuWare Lizenzdatei,
welche Sie im [DocuWare Partner Portal](http://go.docuware.com/partnerportal-login) herunterladen können.

### Docker Container

Intelligent Indexing läuft in Docker Containern.
Ein Setup-Skript konfiguriert die Container.
Damit ist der Installationsaufwand für Intelligent Indexing Version 2 sehr gering.

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

Wird als Ergebnis `Unrestricted` angezeigt, müssen Sie nichts ändern.
Wird ein anderer Wert als `Unrestricted` angezeigt, müssen Sie über
folgenden Befehl das Ausführen von unsignierten Skripten erlauben:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
```

Nach Ausführen des Kommandos können __in der aktuellen Powershell-Sitzung__
alle Kommandos ausgeführt werden.
Dieses Kommando müssen Sie in jedem Powershell-Fenster erneut ausführen.

Falls Sie die Sperre komplett aufheben wollen,
können Sie für den Scope auch `CurrentUser` oder `LocalMachine` verwenden.

## Installation der Docker Umgebung

Intelligent Indexing läuft in Docker Containern.
Dazu muss zuerst die _Mirantis container runtime_ installiert werden.
Wechseln Sie in einer Powershell als Administrator in das
Installationsverzeichnis und führen folgenden Befehl aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-Docker.ps1
```

Womöglich muss nach der Ausführung des Skriptes der Host-Rechner neu gestartet werden. In diesem Fall führen Sie folgendes aus:

```powershell
Restart-Computer
```

Nach dem Neustart müssen Sie das Installations-Skript erneut ausführen, um die Installation der Docker-Umgebung abzuschließen. 

Nun können Sie testen, ob die Docker-Umgebung und docker-compose korrekt installiert sind:

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

## Installation des Datenbankservers

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

Beachten Sie, dass für die Intelligent Indexing
_self-contained databases_ erforderlich sind. Daher wird das
folgende SQL vom Setup-Skript ausgeführt:

```sql
sp_configure 'contained database authentication', 1
GO
RECONFIGURE
GO
```

Wenn dies nicht gewünscht ist, sollten Sie eine separate SQL Server-Instanz für Intelligent Indexing
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

Die Installation wird durch Ausführen von  `Setup-Intellix.ps1` im Verzeichnus `setup` gestartet.
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
  Diese Werte geben die Instanz und die Anmeldeinformationen für den Zugriff auf Ihren eigenen SQL Server an.
  
  :warning: Wenn Sie den containerisierten SQL Server verwenden, dürfen Sie diese Parameter nicht angeben.

Sie können die Datenbanken einer alte Version von Intelligent Indexing und Intelligent Indexing Version 2
auf demselben Datenbankserver ablegen. Die alte Version verwendet die
`intellix`-Datenbank, die aktuelle Version verwendet die `intellixv2`-Datenbank.

### Examples

Im Installationsverzeichnis gibt es die beiden Skripte `Run-Setup-Example.ps1` und
`Run-Setup-With-Own-SqlServer-Example.ps1`. Sie können die Skripte ändern und verwenden
um das Setup auszuführen und den Dienst zu starten, wenn das Setup abgeschlossen ist.

Um sichere Kennwörter zu erhalten, verwenden diese Skripte einen
Kennwortgenerator, um Kennwörter für die Web-Benutzeroberfläche
und den Datenbankbenutzer zu generieren. Wenn Sie keine zufälligen
Passwörter generieren möchten, ändern Sie einfach die Beispiele je nach Bedarf.

- Einfache Installation von Intelligent Indexing mit Lizenzdatei:

  ```powershell
  # Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

  $intellixAdminPassword = ./Get-RandomPassword.ps1
  $intellixDbPassword = ./Get-RandomPassword.ps1

  ./setup/Setup-Intellix.ps1 `
      -IntellixAdminUser intellix `
      -IntellixAdminPassword $intellixAdminPassword `
      -IntellixDbUser intellix `
      -IntellixDbPassword $intellixDbPassword `
      -LicenseFile 'c:\users\Administrator\Downloads\Peters Engineering_Enterprise.lic'

  Write-Output "Intelligent Indexing Web UI user: intellix"
  Write-Output "Intelligent Indexing Web UI password: $intellixAdminPassword"
  ```

- Installation von Intelligent Indexing mit eigenem SQL Server,aber ohne Lizenzdatei:

  ```powershell
  # Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

  $intellixAdminPassword = ./Get-RandomPassword.ps1
  $intellixDbPassword = ./Get-RandomPassword.ps1

  ./setup/Setup-Intellix.ps1 `
      -IntellixAdminUser intellix `
      -IntellixAdminPassword $intellixAdminPassword `
      -IntellixDbUser intellix `
      -IntellixDbPassword $intellixDbPassword `
      -SqlServerInstance my-sql-2019-box `
      -SqlServerInstanceUser "sa" `
      -SqlServerInstancePassword "Admin001"

  Write-Output "Intelligent Indexing Web UI user: intellix"
  Write-Output "Intelligent Indexing Web UI password: $intellixAdminPassword"
  ```

## Installation des Webservers IIS

Zur Installation führen Sie das folgende Skript in einer
Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Install-IIS.ps1
```

Das Skript installiert den Webserver IIS mit den Komponenten `UrlRewrite` und `ARR`.

Falls Sie eine Verbindung über `https` verwenden wollen,
müssen Sie in der Oberfläche des IIS unter `Sites` -> `Default Web Site`
rechts auf `Bindings...` klicken und dort unter dem `https` Binding
ein gültiges Zertifikat hinterlegen und das Zertifikat in den entsprechenden
Zertifikatsspeichern ablegen. In der Verbindungsdatei (siehe
 [Verbindung zu DocuWare](#verbindung-zu-docuWare)) können
 Sie dann `https` statt `http` eintragen.

## Verwaltung von Intelligent Indexing

### Konfiguration von Intelligent Indexing

Das Setup generiert Dateien, die von den Containern verwendet werden,
um eine Verbindung zur Datenbank herzustellen
und die Dateien und Indexdaten für Apache Solr zu speichern.
Die Daten werden unter `C:\ProgramData\IntellixV2` gespeichert.
Wenn Sie die Daten an einem anderen Speicherort speichern möchten,
empfehlen wir, den Ordner an einen Speicherort Ihrer Wahl zu verschieben
und Junctions oder Softlinks mit dem Befehl
[mklink](https://docs.microsoft.com/de-de/windows-server/administration/windows-commands/mklink)
oder mit `New-Item` zu erstellen:

```powershell
Stop-Intellix.ps1
Move-Item -Path C:\ProgramData\IntellixV2 -Destination d:\ganz-viel-platz\intellixv2

New-Item -ItemType Junction -Path C:\ProgramData\IntellixV2 `
  -Value d:\ganz-viel-platz\intellixv2

Start-Intellix.ps1
```

### Starten von Intelligent Indexing

Zum Starten von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Start-Intellix.ps1
```

### Testen der Komponenten von Intelligent Indexing und Passwort ändern

Über folgendes Skript können Sie überprüfen, welche Docker Container gerade auf dem Host-Rechner laufen:

```powershell
docker ps -a
```

Sie sollten jeweils eine Zeile als Ausgabe für die Docker-Container erhalten,
deren Namen mit `intellix` beginnen. In der Spalte `Status` können Sie sehen,
ob die Docker-Container ausgeführt werden (`Up ...`) oder beendet wurden
(`Exited ...`). In dieser Spalte können Sie auch sehen,
ob die Container grundsätzlich laufen. Beim Start wird hier
`(health: starting)` angezeigt. Wenn die Container erfolgreich auf Anforderungen reagieren,
wird `(healthy`) angezeigt.

Sie können mit PowerShell überprüfen, ob der Dienst ausgeführt wird. Die folgende Anfrage sollte mit dem Statuscode 200 beantwortet werden:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/intellix-v2/
```

### Logging

Führen Sie das folgende PowerShell-Skript aus, um das Live-Protokoll von Intelligent Indexing anzuzeigen:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Show-IntellixLogs.ps1
```

Die Ausgaben könnten durch Drücken von `Strg+C` abgebrochen werden.

### Stoppen von Intelligent Indexing

Zum Stoppen von Intelligent Indexing führen Sie das folgende Skript in einer Powershell als Administrator im Installationsverzeichnis aus:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Stop-Intellix.ps1
```

### Update von Intelligent Indexing

Intelligent Indexing wird ständig verbessert. Um Updates einsuspielen, reicht es aus,
aktualisierte Images abzurufen und den Dienst neu zu starten.

Verwenden Sie das folgende Skript, um nach Updates oder Hotfixes zu suchen und diese herunterzuladen:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1
```

Sie können dieses Skript ausführen, während Intelligent Indexing läuft.
Die Änderungen werden erst wirksam, wenn Sie `Stop-Intellix.ps1` und `Start-Intellix.ps1` ausführen.
Diese Dienste können sofort nach dem Update neu gestartet werden,
wenn der `WithRestart`-Parameter hinzugefügt wird:

```powershell
# Nur nötig, falls die Powershell execution policy nicht 'Unrestricted' ist
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

.\Update-Intellix.ps1 -WithRestart
```

### Neustart des Host-Rechners

Die Docker Umgebung verwaltet die laufenden Intelligent Indexing Container. Diese sind so konfiguriert, dass Intelligent Indexing bei einem Neustart des Host-Rechners heruntergefahren und automatisch wieder gestartet wird. Falls Intelligent Indexing vor dem Neustart nicht lief, wird es auch danach nicht gestartet.

## Intelligent Indexing lizenzieren

Um Intelligent Indexing verwenden zu können, müssen Sie eine Lizenzdatei
auf den Dienst anwenden.
Sie können die Lizenzdatei vom
[DocuWare Partner Portal](http://go.docuware.com/partnerportal-login) herunterladen.

Wenn Sie die Datei heruntergeladen haben, empfehlen wir,
die Datei beim [Setup](#setup) zu übergeben.
Alternativ können Sie die Datei in der Intelligent Indexing Administrationsoberfläche
unter dem Punkt `Licensing` hochladen.

## Verbindung zu DocuWare

Die Installation generiert automatisch eine Datei mit Verbindungsdaten von Intelligent Indexing. Sie finden diese Datei im INstallationsverzeichnis unter `.\setup\run\intelligent-indexing-connection.xml`.

Diese Datei enthält die Verbindungs-URL. Wenn Ihr Server unter einer anderen Adresse
als _http://Computernamen/_ erreichbar ist hat oder Sie den IIS für die
Verwendung von _https_ konfiguriert haben, sollten Sie diese URL in dieser Datei ändern.

Sie können nun die Intelligent Indexing Verbindungsdatei in Ihre
DocuWare Installation hochladen, um die Verbindung mit
Intelligent Indexing herzustellen. Loggen Sie sich dazu in die
DocuWare Administration ein und navigieren Sie zu 
`DocuWare System` -> `Datenverbindungen` -> `Verbindungen Intelligent Indexing Service`.
Falls hier schon eine Verbindung eingetragen ist,
können Sie diese öffnen und unter _Organizations_ Ihre Organisation
entfernen und auf `Übernehmen` klicken.
Dadurch ist die Verbindung Ihres DocuWare Systems zu Ihrem alten
Intelligent Indexing System deaktiviert, könnte aber durch
erneutes Hinzufügen der Organisation wieder aktiviert werden.
Klicken Sie anschließend mit der rechten Maustaste
auf `Verbindungen Intelligent Indexing Service` auf der
linken Seite und wählen `Installiere Datei von Intelligent Indexing Service` aus.
In dem sich öffnenden Dialog wählen Sie die Datei `intelligent-indexing-connection.xml` aus.
Klicken Sie anschließend auf `Übernehmen` und schließen Sie die DocuWare Administration.

> :point_up: Wenn Sie die Konfigurationsdatei in die DocuWare-Konfiguration hochladen,
> wird möglicherweise die Fehlermeldung angezeigt, dass die Intelligent Indexing
> nicht erreicht werden kann. Diese Meldung ist jedoch
> irreführend, denn die Verbindung wird hergestellt.
> Wir beheben diese falsche Meldung in einer zukünftigen Version von DocuWare.

## Troubleshooting

### Setup der Datenbank Setup schlägt fehl

Falls das Setup fehlschlägt, sollten Sie die _ausführliche Ausgabe_
von PowerShell aktivieren und das Setup dann erneut ausführen.
Dies kann aktiviert werden mit:

```powershell
$VerbosePreference = "Continue"
$InformationPreference = "Continue"
```

### Installation vom IIS und ARR schlägt fehl

Falls die IIS-Installation fehlschlägt oder eine andere Modulinstallation fehlschlägt,
sollten Sie den Computer neu starten.
Ausstehende Windows-Updates stoppen möglicherweise die Konfiguration des IIS.
In vielen Fällen löst ein Neustart der Maschine dieses Problem.

### Hinweise für Beta-Tester

- Wenn Sie Intelligent Indexing v2 bereits aus einem früheren
  Betatest installiert haben, entfernen Sie laufende oder gestoppte
  Container. Sie sollten dann die Datenbank aktualisieren oder neu erstellen,
  indem Sie das [Setup](#setup) ausführen.
  Außerdem befinden sich die Datendateien nun unter `C:\ProgramData\IntellixV2`.

- Wir haben die SQL Server-Installation vereinfacht. Wenn Sie SQL Express bereits
  installiert haben, können Sie den installierten SQL Server durch einen
  containerisierten SQL Server ersetzen. Sie können auch mit dem
  installierten SQL Server fortfahren. Details finden Sie unter
  [Installation des Datenbankservers](#installation_des_datenbankservers)

## Überblick über die Intelligent Indexing Setup-Dateien

- `Install-Docker.ps1` und `Install-IIS.ps1`: Installationsskripte für Docker und IIS

- `Update-Intellix.ps1`, `Start-Intellix.ps1`, `Stop-Intellix.ps1`:
  Skripte um Intelligent Indexing zu updaten, starten und stoppen

- `Show-IntellixLogs.ps1`: Skript, um das Protokoll von Intelligent Indexing anzuzeigen

- `setup/Setup-Intellix.ps1`: Installationsskript
