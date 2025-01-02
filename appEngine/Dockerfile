FROM mcr.microsoft.com/dotnet/nightly/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://*:8080
EXPOSE 443

FROM mcr.microsoft.com/dotnet/nightly/sdk:8.0 AS build
WORKDIR /src
COPY . .

RUN apt-get update
RUN apt-get install -y nodejs npm

WORKDIR /src/UI-MVC/ClientApp
RUN npm install
RUN npm run build

WORKDIR /src/UI-MVC
RUN dotnet build

FROM build AS publish
WORKDIR /src/UI-MVC
RUN dotnet publish "UI-MVC.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Phygital.UI.MVC.dll"]

# FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

# EXPOSE 80
# EXPOSE 443
# EXPOSE 5000

# COPY . .
# WORKDIR /UI-MVC 
# RUN dotnet publish -c Release 
# ENTRYPOINT ["dotnet", "run", "UI-MVC.csproj"]

# # WORKDIR /src
# # COPY BL/*.csproj ./BL/
# # COPY DAL/*.csproj ./DAL/
# # COPY Domain/*.csproj ./Domain/
# # COPY UI-CA/*.csproj ./UI-CA/
# # COPY UI-MVC/*.csproj ./UI-MVC/ 

# # RUN dotnet restore "UI-MVC/UI-MVC.csproj"
# # COPY . .
# # WORKDIR "/src/UI-MVC"
# # RUN dotnet build "UI-MVC.csproj" -c Release -o /app

# # FROM build as publish
# # RUN dotnet publish "UI-MVC.csproj" -c Release -o /app

# # FROM base AS final 
# # WORKDIR /app
# # COPY --from=publish /app .
# # ENTRYPOINT ["dotnet", "PM.UI.Web.MVC.dll"]

# FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
# WORKDIR /app
# EXPOSE 80
# EXPOSE 443

# # Copy csproj and restore as distinct layers
# COPY *.sln .
# COPY BL/*.csproj ./BL/
# COPY DAL/*.csproj ./DAL/
# COPY Domain/*.csproj ./Domain/
# COPY UI-CA/*.csproj ./UI-CA/
# COPY UI-MVC/*.csproj ./UI-MVC/ 

# RUN dotnet restore

# # Copy everything else and build
# COPY BL/. ./BL/
# COPY DAL/. ./DAL/
# COPY Domain/. ./Domain/
# COPY UI-CA/. ./UI-CA/
# COPY UI-MVC/ ./UI-MVC/

# WORKDIR /app/UI-MVC
# RUN dotnet publish -c Release -o out

# # Build runtime image
# FROM mcr.microsoft.com/dotnet/nightly/aspnet:7.0 AS runtime
# WORKDIR /app
# COPY --from=build /app/UI-MVC/out ./
# EXPOSE 5000
# ENTRYPOINT ["dotnet", "PM.UI.Web.MVC.dll"]



