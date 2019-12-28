FROM mcr.microsoft.com/dotnet/core/aspnet:3.0 AS runtime
WORKDIR /app
COPY bin/Debug/netcoreapp3.0/publish/ ./
ENTRYPOINT ["dotnet", "TeaWebApp.dll"]
