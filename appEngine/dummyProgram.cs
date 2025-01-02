using Microsoft.EntityFrameworkCore;
using Phygital.BL;
using Phygital.DAL;
using Phygital.DAL.EF;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.


builder.Services.AddControllersWithViews();

builder.Services.AddRazorPages();

var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
var db = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_NAME");
var dbUser = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_USER");
var dbPassword = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PASSWORD");
var dbHost = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_HOST");
var dbPort = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PORT");

var connectionString = $"Host={dbHost};Port={dbPort};Username={dbUser};Password={dbPassword};Database={db};";

builder.Services.AddDbContext<PhygitalDbContext>();

builder.Services.AddScoped<IFlowRepository, FlowRepository>();
builder.Services.AddScoped<IFlowManager, FlowManager>();
builder.Services.AddScoped<UnitOfWork>();
builder.Services.AddScoped<IParticipationManager,ParticipationManager>();
builder.Services.AddScoped<IParticipationRepository,ParticipationRepository>();
builder.Services.AddScoped<IPlatformManager,PlatformManager>();
builder.Services.AddScoped<IPlatformRepository,PlatformRepository>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<PhygitalDbContext>();

    if (context.CreateDatabase(dropDatabase: true))
    {
        DataSeeder.Seed(context);
    }
}


// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapRazorPages();

app.Run();