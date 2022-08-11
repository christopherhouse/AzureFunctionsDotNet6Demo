namespace AzureFunctionsDotNet6Demo.Services;
public class InventoryUpdateService : IInventoryUpdateService
{
    private readonly string _databaseName;
    private readonly string _containerName;
    private readonly Uri _containerUri;

    public InventoryUpdateService(string databaseName, string containerName)
    {
        if (string.IsNullOrEmpty(databaseName))
        {
            throw new ArgumentException(nameof(databaseName));
        }

        _databaseName = databaseName;

        if (string.IsNullOrEmpty(containerName))
        {
            throw new ArgumentException(nameof(containerName));
        }

        _containerName = containerName;

        _containerUri = UriFactory.CreateDocumentCollectionUri(_databaseName, _containerName);
    }

    public async Task UpdateAvailableInventoryAsync(IDocumentClient documentClient, OrderLineItem lineItem)
    {
        var documentUri = UriFactory.CreateDocumentUri(_databaseName, _containerName, lineItem.ProductId);

        var productResponse = await documentClient.ReadDocumentAsync<Product>(documentUri, new RequestOptions{ PartitionKey = new PartitionKey(lineItem.Category)});

        productResponse.Document.AvailableInventory -= lineItem.Quantity;

        await documentClient.UpsertDocumentAsync(_containerUri, productResponse.Document);
    }
}
