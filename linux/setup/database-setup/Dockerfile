FROM docuwarepublic.azurecr.io/intellix/app:2-alpine as dbsrc

FROM docuwarepublic.azurecr.io/intellix/intellix-db-setup-base:debian
COPY --from=dbsrc /db/IntellixDatabase.dacpac .

COPY . .
ENTRYPOINT pwsh entrypoint.ps1
