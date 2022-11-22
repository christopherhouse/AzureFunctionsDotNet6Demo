namespace AzureFunctionsDotNet6Demo.Models;
public class ErpOrderHeader
{
    public string OrderIdentifier { get; set; }
    public DateTime OrderDateTime { get; set; }
    public string CustomerRecordNumber { get; set; }
}

public class ErpOrder
{
    public ErpOrder()
    {
        Lines = new List<ErpOrderLineItems>();
    }

    public ErpOrderHeader Header { get; set; }

    public IList<ErpOrderLineItems> Lines { get; }

    public static ErpOrder FromOrder(Order order)
    {
        var erpOrder = new ErpOrder
        {
            Header = new ErpOrderHeader
            {
                OrderDateTime = DateTime.UtcNow,
                OrderIdentifier = order.Id,
                CustomerRecordNumber = order.CustomerNumber
            }
        };

        for (var i = 0; i < order.LineItems.Count; i++)
        {
            erpOrder.Lines.Add(new ErpOrderLineItems
            {
                LineNumber = i+1,
                ProductGroup = order.LineItems[i].Category,
                ProductNumber = order.LineItems[i].ProductId,
                Required = order.LineItems[i].Quantity
            });
        }

        return erpOrder;
    }
}
