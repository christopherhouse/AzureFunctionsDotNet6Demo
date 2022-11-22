namespace AzureFunctionsDotNet6Demo.Models;
public class Product
{
    [JsonProperty("id")]
    public string Id { get; set; }

    [JsonProperty("description")]
    public string Description { get; set; }

    [JsonProperty("category")]
    public string Category { get; set; }

    [JsonProperty("unitPrice")]
    public decimal UnitPrice { get; set; }

    [JsonProperty("availableInventory")]
    public int AvailableInventory { get; set; }
}
