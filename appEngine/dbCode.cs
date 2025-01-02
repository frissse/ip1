// dbContext.cs
var db = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_NAME")
var dbUser = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_USER")
var dbPassword = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PASSWORD")
var dbHost = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_HOST")
var dbPort = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PORT")

var connectionString = $"Host={dbHost};Port={dbPort};Username={dbUser};Password={dbPassword};Database={db};";

if (!optionsBuilder.IsConfigured)
{
   optionsBuilder.UseNpgsql(connectionString);
}

// program.cs
ar db = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_NAME")
var dbUser = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_USER")
var dbPassword = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PASSWORD")
var dbHost = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_HOST")
var dbPort = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PORT")

var connectionString = $"Host={dbHost};Port={dbPort};Username={dbUser};Password={dbPassword};Database={db};";

builder.Services.AddDbContext<PMdBContext>(options =>
    options.UseSqlite(connectionString));