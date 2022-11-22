namespace AzureFunctionsDotNet6Demo.Functions;
public class OrdersChangeFeedProcessor
{
    private readonly IInventoryUpdateService _inventoryUpdateService;

    public OrdersChangeFeedProcessor(IInventoryUpdateService inventoryUpdateService)
    {
        _inventoryUpdateService = inventoryUpdateService ?? throw new ArgumentNullException(nameof(inventoryUpdateService));
    }

    [FunctionName("OrdersChangeFeedProcessor")]
    public async Task Run([CosmosDBTrigger(
        databaseName: "%cosmosDatabaseName%",
        collectionName: "%ordersContainerName%",
        ConnectionStringSetting = "cosmosConnectionString",
        LeaseCollectionName = "leases",
        CreateLeaseCollectionIfNotExists = true,
        LeaseCollectionPrefix = "orderCreate")]IReadOnlyList<Document> input, 
        [CosmosDB(ConnectionStringSetting = "cosmosConnectionString")]IDocumentClient documentClient,
        [ServiceBus("%orderReceivedQueue%", Connection = "serviceBusSendConnectionString")] IAsyncCollector<string> messages,
        ILogger log)
    {
        if (input != null && input.Count > 0)
        {
            foreach (var doc in input)
            {
                var order = Order.FromDocument(doc);

                foreach (var lineItem in order.LineItems)
                {
                    await _inventoryUpdateService.UpdateAvailableInventoryAsync(documentClient, lineItem);
                }

                await messages.AddAsync(JsonConvert.SerializeObject(order));
            }
        }
    }
}
