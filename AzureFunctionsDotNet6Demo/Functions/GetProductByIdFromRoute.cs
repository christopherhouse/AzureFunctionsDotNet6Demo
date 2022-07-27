using AzureFunctionsDotNet6Demo.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;

namespace AzureFunctionsDotNet6Demo.Functions
{
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
}
