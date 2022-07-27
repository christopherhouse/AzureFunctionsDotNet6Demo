using System.Threading.Tasks;
using AzureFunctionsDotNet6Demo.Models;
using Microsoft.Azure.Documents;

namespace AzureFunctionsDotNet6Demo.Services
{
    public interface IInventoryUpdateService
    {
        Task UpdateAvailableInventoryAsync(IDocumentClient documentClient, OrderLineItem lineItem);
    }
}