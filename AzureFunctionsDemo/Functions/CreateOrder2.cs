namespace AzureFunctionsDotNet6Demo.Functions;
public static class CreateOrder2
{
    [FunctionName("CreateOrder2")]
    public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, methods: "post", Route = null)]
        HttpRequest req,
        [CosmosDB(databaseName: "%cosmosDatabaseName%",
            collectionName: "%ordersContainerName%",
            ConnectionStringSetting = "cosmosConnectionString")] IAsyncCollector<Order> orderToSave,
        ILogger log)
    {
        var order = JsonConvert.DeserializeObject<Order>(await req.ReadAsStringAsync());
        await orderToSave.AddAsync(order);

        return new NoContentResult();
    }
}