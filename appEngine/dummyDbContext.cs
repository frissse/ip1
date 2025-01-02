using Phygital.BL.Domain.flow;
using Phygital.BL.Domain.platform;
using Phygital.BL.Domain.Platform.Theme;
using Phygital.BL.Domain.State;
using System.Diagnostics;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Phygital.BL.Domain.Flow;

namespace Phygital.DAL.EF;

public class PhygitalDbContext : DbContext
{
    public DbSet<Flow> Flows { get; set; }
    public DbSet<SubTopic> SubTopics { get; set; }
    public DbSet<Answer> Answers { get; set; }
    public DbSet<Question> Questions { get; set; }
    public DbSet<InformationElement> InformationElements { get; set; }
    public DbSet<Condition> Conditions { get; set; }
    public DbSet<Participation> Participations { get; set; }
    public DbSet<PlayableElement> PlayableElements { get; set; }
    public DbSet<FlowElement> FlowElements { get; set; }
    public DbSet<OnSiteInstallation> OnSiteInstallations { get; set; }

    public DbSet<FlowState> FlowStates { get; set; }
    public DbSet<NewState> NewStates { get; set; }
    public DbSet<BlockedState> BlockedStates { get; set; }
    public DbSet<RunningState> RunningStates { get; set; }
    public DbSet<EndState> EndStates { get; set; }
    
    

    public PhygitalDbContext(DbContextOptions options) : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        // var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
        // var db = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_NAME");
        // var dbUser = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_USER");
        // var dbPassword = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PASSWORD");
        // var dbHost = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_HOST");
        // var dbPort = Environment.GetEnvironmentVariable("ASPNETCORE_DEV_DATABASE_PORT");

        var connectionString = $"Host=35.187.112.255;Port=5432;Username=postgres;Password=Student_123;Database=physical-dev;";;

        if (!optionsBuilder.IsConfigured)
        {
            // if (env == "Production") {
                
            // }
            // else {
            //     optionsBuilder.UseSqlite("Data Source=phygital.db");
            // }
            optionsBuilder.UseNpgsql(connectionString);
            
        }

        optionsBuilder.LogTo(message => Debug.WriteLine(message), LogLevel.Information);
    }


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Condition>().Property<int>("AnswerId");

        modelBuilder.Entity<Answer>()
            .HasOne(a => a.Condition)
            .WithOne(b => b.Answer)
            .HasForeignKey<Condition>("AnswerId");

        modelBuilder.Entity<SubTopic>().HasMany(s => s.FlowElements);
        
        modelBuilder.Entity<Flow>()
            .HasMany(f => f.PlayableElements)
            .WithOne()
            .HasForeignKey("FlowId");

        modelBuilder.Entity<Flow>()
            .HasOne(flow => flow.StartPlayableElement).WithOne().HasForeignKey<PlayableElement>("elementId");

        modelBuilder.Entity<PlayableElement>()
            .HasOne(p => p.NextPlayableElement).WithOne().HasForeignKey<PlayableElement>("nextElementId");

        modelBuilder.Entity<FlowElement>()
            .HasOne(p => p.ParentPlayableElement);

        modelBuilder.Entity<Participation>().HasOne(p => p.Flow).WithMany().IsRequired();


        modelBuilder.Entity<Question>().HasMany(q => q.Answers).WithOne().HasForeignKey("QuestionId").IsRequired();


        modelBuilder.Entity<GivenAnswer>().HasOne(ga => ga.Answer).WithMany().IsRequired();


        modelBuilder.Entity<Participation>().HasMany(p => p.GivenAnswers).WithOne(ga => ga.Participation).IsRequired();

        modelBuilder.Entity<Participation>().HasOne(p => p.OnSiteInstallation)
            .WithMany(installation => installation.Participations).IsRequired();
        modelBuilder.Entity<Platform>().Property<int>("PlatformManagerId");
        modelBuilder.Entity<Platform>()
            .HasOne(p => p.PlatformManager)
            .WithOne(manager => manager.Platform)
            .HasForeignKey<Platform>("PlatformManagerId");
        modelBuilder.Entity<SubPlatform>().Property<int>("SubPlatformManagerId");
        modelBuilder.Entity<SubPlatform>()
            .HasOne(p => p.SubplatformManager)
            .WithOne(manager => manager.SubPlatform)
            .HasForeignKey<SubPlatform>("SubPlatformManagerId");
        modelBuilder.Entity<FlowElement>().OwnsOne(f => f.ShowTime);
    }

    public bool CreateDatabase(bool deleteExisting)
    {
        if (deleteExisting)
        {
            Database.EnsureDeleted();
        }

        return Database.EnsureCreated();

    }
}