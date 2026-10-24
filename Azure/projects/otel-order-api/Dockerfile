FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["src/Api/OtelOrderApi.Api.csproj", "src/Api/"]
COPY ["src/Application/OtelOrderApi.Application.csproj", "src/Application/"]
COPY ["src/Domain/OtelOrderApi.Domain.csproj", "src/Domain/"]
COPY ["src/Infrastructure/OtelOrderApi.Infrastructure.csproj", "src/Infrastructure/"]
RUN dotnet restore "src/Api/OtelOrderApi.Api.csproj"

COPY . .
RUN dotnet publish "src/Api/OtelOrderApi.Api.csproj" \
    --configuration Release \
    --output /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "OtelOrderApi.Api.dll"]
