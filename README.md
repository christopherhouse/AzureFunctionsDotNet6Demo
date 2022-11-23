# Azure Functions + Cosmos DB Integration Demo

[![Open in vscode.dev](https://img.shields.io/badge/Open%20in-vscode.dev-blue)][1]

[1]: https://vscode.dev/github/lluppesms/durable.function.azd/

![azd Compatible](/Docs/images/AZD_Compatible.png)

[![deploy.infra](https://github.com/lluppesms/functions.demo/actions/workflows/deploy-infra.yml/badge.svg)](https://github.com/lluppesms/functions.demo/actions/workflows/deploy-infra.yml)

[![deploy.app](https://github.com/lluppesms/functions.demo/actions/workflows/deploy-function.yml/badge.svg)](https://github.com/lluppesms/functions.demo/actions/workflows/deploy-function.yml)

## About

This project provides a number of Azure Functions, to illustrate the capabilities found in the Cosmos DB bindings for Azure Functions.  Documentation around these capabilities and supported scenarios can be [found here](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-cosmosdb-v2).

---

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

---

## Azure Devops Pipelines

A CICD pipeline has been created that combines the CI and CD into one pipeline and deploys one (or more) environment(s) and the application quickly and easily. Edit the "environments:" variable in the pipeline to specify which environments that should be deployed.

- [infra-and-function-pipeline.yml](.infrastructure/deploy/infra-and-function-pipeline.yml)

As an alternative, two separate CI and CD pipelines have been created. Edit the "environments:" variable in the pipeline to specify which environments that should be deployed.

- [function-only-pipeline.yml](.infrastructure/deploy/function-only-pipeline.yml)
- [infra-only-pipeline.yml](.infrastructure/deploy/infra-only-pipeline.yml)

> Instructions on how to set up an Azure DevOps pipeline can be found in the [Create Pipelines](.infrastructure/docs/Create-Pipeline.md) document.

---

## Development Notes

> **Note:**
> For local development of Azure Functions, it is preferable to use local storage.  However, there is a bug with Azurite 3.17, so currently if you have problems, the best way to fix this is to install an older version of Azureite via NPM:
>
> ``` bash
> npm uninstall -g azurite
> npm install -g azurite@3.16.0
> ```

To run Azureite, open a command shell in Administrator Mode:
> ``` bash
> > cd C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator
> > azurite.exe
> ```
