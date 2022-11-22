namespace AzureFunctionsDotNet6Demo.Functions;
public static class GetProducts
{
    [FunctionName("GetProducts")]
    public static async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
        [CosmosDB(ConnectionStringSetting = "cosmosConnectionString")] IDocumentClient documentClient,
        ILogger log)
    {
        var database = Environment.GetEnvironmentVariable("cosmosDatabaseName");
        var container = Environment.GetEnvironmentVariable("cosmosContainerName");
        var containerUri = UriFactory.CreateDocumentCollectionUri(database, container);

        string continuationToken = null;
        var documents = new List<Product>();

        do
        {
            var feed = await documentClient.ReadDocumentFeedAsync(containerUri,
                new FeedOptions {MaxItemCount = 25, RequestContinuation = continuationToken});
            continuationToken = feed.ResponseContinuation;

            foreach (var doc in feed)
            {
                var docString = doc.ToString();
                var product = JsonConvert.DeserializeObject<Product>(docString);
                documents.Add(product);
            }
            
        } while (continuationToken != null);


        return new OkObjectResult(documents);
    }
}
