namespace AzureFunctionsDotNet6Demo.Models;
public class Order
{
    [JsonProperty("id")]
    public string Id { get; set; }

    [JsonProperty("customerNumber")]
    public string CustomerNumber { get; set; }

    [JsonProperty("lineItems")]
    public IList<OrderLineItem> LineItems { get; set; }

    public static Order FromDocument(Document doc)
    {
        var orderString = JsonConvert.SerializeObject(doc);
        var order = JsonConvert.DeserializeObject<Order>(orderString);
        return order;
    }

    public static Order FromString(string orderJson)
    {
        return JsonConvert.DeserializeObject<Order>(orderJson);
    }
}
