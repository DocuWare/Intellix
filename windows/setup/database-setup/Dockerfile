ARG WINVER
FROM docuwarepublic.azurecr.io/intellix/app as dbsrc

FROM mcr.microsoft.com/windows/servercore:${WINVER}

COPY prepare-tools-container.ps1 .
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN ./prepare-tools-container.ps1

COPY --from=dbsrc /db/IntellixDatabase.dacpac .

COPY . .
ENTRYPOINT /entrypoint.ps1
