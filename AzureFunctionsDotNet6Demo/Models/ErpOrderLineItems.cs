namespace AzureFunctionsDotNet6Demo.Models;

public class ErpOrderLineItems
{
    public int LineNumber { get; set; }

    public string ProductNumber { get; set; }

    public int Required { get; set; }

    public string ProductGroup { get; set; }
}