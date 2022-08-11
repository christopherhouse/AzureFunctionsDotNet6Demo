namespace AzureFunctionsDotNet6Demo.Functions;
public static class GetProductsByDescription
{
    [FunctionName("GetProductsByDescription")]
    public static IActionResult Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "search/{description}")] HttpRequest req,
        [CosmosDB(databaseName:"%cosmosDatabaseName%",
            collectionName: "%cosmosContainerName%",
            ConnectionStringSetting = "cosmosConnectionString",
            SqlQuery = "SELECT * FROM c WHERE CONTAINS(c.description, {description}, true)")] IEnumerable<Product> products,
        ILogger log)
    {
        return new OkObjectResult(products);
    }
}
