namespace AzureFunctionsDotNet6Demo.Functions;
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
