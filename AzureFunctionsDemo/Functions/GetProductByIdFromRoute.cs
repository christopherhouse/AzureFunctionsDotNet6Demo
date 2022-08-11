namespace AzureFunctionsDotNet6Demo.Functions;
public static class GetProductByIdFromRoute
{
    [FunctionName("GetProductByIdFromRoute")]
    public static IActionResult Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "products/{category}/{id}")] HttpRequest req,
        [CosmosDB(databaseName:"%cosmosDatabaseName%",
            collectionName: "%cosmosContainerName%",
            ConnectionStringSetting = "cosmosConnectionString",
            Id = "{id}",
            PartitionKey = "{category}")] Product product,
        ILogger log)
    {
        return new OkObjectResult(product);
    }
}
