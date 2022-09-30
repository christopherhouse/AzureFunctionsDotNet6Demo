[assembly: FunctionsStartup(typeof(Startup))]
namespace AzureFunctionsDotNet6Demo;

public class Startup : FunctionsStartup
{
    public override void Configure(IFunctionsHostBuilder builder)
    {
        var database = Environment.GetEnvironmentVariable("cosmosDatabaseName");
        var container = Environment.GetEnvironmentVariable("cosmosContainerName");
        builder.Services.AddLogging();
        builder.Services.AddSingleton<IInventoryUpdateService>(_ => new InventoryUpdateService(database, container));
    }
}
