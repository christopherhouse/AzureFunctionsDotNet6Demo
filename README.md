# Azure Functions + Cosmos DB Integration Demo

## About
This project provides a number of Azure Functions, to illustrate the capabilities found in the Cosmos DB bindings for Azure Functions.  Documentation around these capabilities and supported scenarios can be [found here](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-cosmosdb-v2).

## Architecture
The following diagram illustrates the components and data flow that make up this solution.  Conceptually, the solution represents a very naive implementation of a retailer, with orders and products.

The infrastructure template provisions a single Cosmos DB account and database.  Within the database, there are two containers, one for orders and one for products.  Two of the Functions write orders to the Orders container.  A Function listens to the Change Feed on the Orders container and uses data received from that to update available inventory numbers in the Products container.  Additionally, several Functions query the Products container.

![Architecture Diagram](/out/docs/architecture/Cosmos%20Functions%20Demo.png)
### Functions

| Function Name             | Description                              |
|---------------------------|------------------------------------------|
| [CreateOrder](CosmosFunctionsDemo/Functions/CreateOrder.cs)               | Demonstrates how to save the content of an HTTP post to a Cosmos DB container, using a synchronous approach |
| [CreateOrder2](CosmosFunctionsDemo/Functions/CreateOrder2.cs)              | Demonstrates how to save the content of an HTTP post to a Cosmos DB container, using a asynchronous approach |
| [GetProductByIdFromRoute](CosmosFunctionsDemo/Functions/GetProductByIdFromRoute.cs)   | Demonstrates getting a specific Cosmos DB document, based in parameters (partition key and id) provided in the HTTP route data |
| [GetProducts](CosmosFunctionsDemo/Functions/GetProducts.cs)               | Demonstrates how to use an IDocumentClient instance, provided by the ComsosDB Functions binding |
| [GetProductsByDescription](CosmosFunctionsDemo/Functions/GetProductsByDescription.cs)  | Demonstrates how to compose a SQL query, using parameters provided by the HTTP route data |
| [OrdersChangeFeedProcessor](CosmosFunctionsDemo/Functions/OrdersChangeFeedProcessor.cs) | Demonstrates how to trigger a Function, using the Cosmos DB trigger and Change Feed |


## Deploying
The pipeline folder contains an [Azure DevOps pipeline](DeployToAzure/Bicep/Deploy-Infrastructure.yml) deploy the required infrastructure and [Azure DevOps pipeline](DeployToAzure/Bicep/Deploy-FunctionApp.yml) that will build the Function code and deploy the Function app.

