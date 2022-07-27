using System.Threading.Tasks;
using AzureFunctionsDotNet6Demo.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace AzureFunctionsDotNet6Demo.Functions
{
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
}