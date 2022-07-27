using System;
using System.Threading.Tasks;
using AzureFunctionsDotNet6Demo.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace AzureFunctionsDotNet6Demo.Functions
{
    public class SendOrderToErp
    {
        [FunctionName("SendOrderToErp")]
        public async Task Run([ServiceBusTrigger("orders-received", Connection = "serviceBusReceiveConnectionString")]string orderJson,
           [ServiceBus("orders-to-erp", Connection = "serviceBusSendConnectionString")] IAsyncCollector<ErpOrder> erpOrders, ILogger log)
        {
            var order = Order.FromString(orderJson);
            var erpOrder = ErpOrder.FromOrder(order);
            await erpOrders.AddAsync(erpOrder);
        }
    }
}
