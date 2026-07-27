using Hustle.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Hustle.Api.Data;

public sealed class FintechDbContext(DbContextOptions<FintechDbContext> options) : DbContext(options)
{
    public DbSet<Asset> Assets => Set<Asset>();
    public DbSet<MarketSignal> MarketSignals => Set<MarketSignal>();
    public DbSet<AlertRule> AlertRules => Set<AlertRule>();
    public DbSet<AlertDelivery> AlertDeliveries => Set<AlertDelivery>();
    public DbSet<NotificationOutbox> NotificationOutbox => Set<NotificationOutbox>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Asset>().ToTable("assets").HasIndex(x => new { x.Exchange, x.Symbol }).IsUnique();
        modelBuilder.Entity<MarketSignal>().ToTable("market_signals")
            .HasIndex(x => new { x.SourceService, x.SourceEventId }).IsUnique();
        modelBuilder.Entity<AlertRule>().ToTable("alert_rules");
        modelBuilder.Entity<AlertDelivery>().ToTable("alert_deliveries").HasIndex(x => x.DedupeKey).IsUnique();
        modelBuilder.Entity<NotificationOutbox>().ToTable("notification_outbox");

        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        foreach (var property in entity.GetProperties())
            property.SetColumnName(ToSnakeCase(property.Name));

        modelBuilder.Entity<MarketSignal>().Property(x => x.Reasons).HasColumnType("jsonb");
        modelBuilder.Entity<MarketSignal>().Property(x => x.Indicators).HasColumnType("jsonb");
        modelBuilder.Entity<MarketSignal>().Property(x => x.RawPayload).HasColumnType("jsonb");
        modelBuilder.Entity<NotificationOutbox>().Property(x => x.Payload).HasColumnType("jsonb");
    }

    private static string ToSnakeCase(string value) =>
        string.Concat(value.Select((character, index) =>
            index > 0 && char.IsUpper(character) ? "_" + char.ToLowerInvariant(character) : char.ToLowerInvariant(character).ToString()));
}
