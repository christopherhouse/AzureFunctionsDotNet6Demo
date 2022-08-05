namespace AzureFunctionsDotNet6Demo.Services;
public interface IInventoryUpdateService
{
    Task UpdateAvailableInventoryAsync(IDocumentClient documentClient, OrderLineItem lineItem);
}