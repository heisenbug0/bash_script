# Microsoft Azure Deployment Scripts

Comprehensive scripts for deploying applications to various Microsoft Azure services.

## 📁 Directory Structure

```
azure/
├── virtual-machines/   # Virtual machine deployments
│   ├── nodejs/        # Node.js applications
│   ├── python/        # Python applications
│   ├── dotnet/        # .NET applications
│   └── java/          # Java applications
├── app-service/       # Platform-as-a-Service deployments
│   ├── web-apps/      # Web applications
│   ├── api-apps/      # API applications
│   └── function-apps/ # Azure Functions
├── container-instances/ # Serverless container deployments
│   ├── single/        # Single container deployments
│   └── groups/        # Container group deployments
├── kubernetes-service/ # Managed Kubernetes deployments
│   ├── clusters/      # AKS cluster setup
│   ├── workloads/     # Application deployments
│   └── monitoring/    # Monitoring setup
├── functions/         # Serverless function deployments
│   ├── nodejs/        # Node.js functions
│   ├── python/        # Python functions
│   ├── dotnet/        # .NET functions
│   └── java/          # Java functions
├── sql-database/      # Managed SQL database deployments
├── cosmos-db/         # NoSQL database deployments
├── redis-cache/       # Managed Redis deployments
├── storage/           # Azure Storage deployments
├── static-web-apps/   # Static web application deployments
└── infrastructure/    # Infrastructure as Code
    ├── arm-templates/ # ARM templates
    ├── bicep/         # Bicep templates
    └── terraform/     # Terraform templates
```

## 🎯 Service Categories

### Compute Services
- **Virtual Machines**: Infrastructure-as-a-Service
- **App Service**: Platform-as-a-Service
- **Container Instances**: Serverless containers
- **Kubernetes Service**: Managed Kubernetes
- **Functions**: Serverless functions

### Database Services
- **SQL Database**: Managed SQL Server
- **Cosmos DB**: Multi-model NoSQL database
- **Database for PostgreSQL**: Managed PostgreSQL
- **Database for MySQL**: Managed MySQL
- **Redis Cache**: Managed Redis

### Storage Services
- **Blob Storage**: Object storage
- **File Storage**: Managed file shares
- **Queue Storage**: Message queuing
- **Table Storage**: NoSQL key-value store

### Networking Services
- **Load Balancer**: Layer 4 load balancing
- **Application Gateway**: Layer 7 load balancing
- **CDN**: Content delivery network
- **Virtual Network**: Software-defined networking

## 🚀 Quick Start Examples

### Deploy .NET App to App Service
```bash
cd app-service/web-apps/dotnet/
export RESOURCE_GROUP="my-rg"
export APP_NAME="my-dotnet-app"
export LOCATION="East US"
./deploy.sh
```

### Deploy Container to Container Instances
```bash
cd container-instances/single/
export RESOURCE_GROUP="my-rg"
export CONTAINER_NAME="my-container"
export IMAGE="nginx:latest"
./deploy.sh
```

### Deploy to Azure Kubernetes Service
```bash
cd kubernetes-service/clusters/
export RESOURCE_GROUP="my-rg"
export CLUSTER_NAME="my-aks-cluster"
export NODE_COUNT="3"
./deploy.sh
```

### Deploy Function to Azure Functions
```bash
cd functions/nodejs/
export RESOURCE_GROUP="my-rg"
export FUNCTION_APP="my-function-app"
export STORAGE_ACCOUNT="mystorageaccount"
./deploy.sh
```

## 📋 Prerequisites

### Azure CLI Setup
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set subscription
az account set --subscription "Your Subscription Name"

# Create resource group
az group create --name myResourceGroup --location "East US"
```

### Required Permissions
Each service requires specific RBAC permissions. The scripts will check for required permissions and provide guidance.

### Environment Variables
```bash
# Azure Configuration
export SUBSCRIPTION_ID="your-subscription-id"
export RESOURCE_GROUP="my-resource-group"
export LOCATION="East US"

# Application Configuration
export APP_NAME="my-application"
export SERVICE_NAME="my-service"
export ENVIRONMENT="production"

# Networking
export VNET_NAME="my-vnet"
export SUBNET_NAME="my-subnet"
export NSG_NAME="my-nsg"
```

## 📝 Service-Specific Features

### App Service Deployments
- ✅ Web app deployment
- ✅ Deployment slots
- ✅ Auto scaling
- ✅ Custom domains
- ✅ SSL certificates
- ✅ Application insights

### Virtual Machine Deployments
- ✅ VM provisioning
- ✅ Custom script extensions
- ✅ Load balancer setup
- ✅ Availability sets
- ✅ Scale sets
- ✅ Monitoring setup

### Container Instance Deployments
- ✅ Container deployment
- ✅ Container groups
- ✅ Volume mounting
- ✅ Environment variables
- ✅ Resource limits
- ✅ Networking configuration

### AKS Deployments
- ✅ Cluster creation
- ✅ Node pool management
- ✅ RBAC integration
- ✅ Network policies
- ✅ Monitoring and logging
- ✅ Auto scaling

### Azure Functions Deployments
- ✅ Function app creation
- ✅ Function deployment
- ✅ Trigger configuration
- ✅ Application settings
- ✅ Monitoring setup
- ✅ Scaling configuration

### Database Deployments
- ✅ Database server creation
- ✅ Firewall configuration
- ✅ Backup setup
- ✅ High availability
- ✅ Performance monitoring
- ✅ Security configuration

## 🔧 Configuration Examples

### App Service Configuration
```bash
# App Service Plan
export SERVICE_PLAN_NAME="my-service-plan"
export SERVICE_PLAN_SKU="B1"
export SERVICE_PLAN_TIER="Basic"

# Web App Configuration
export RUNTIME_STACK="DOTNETCORE|8.0"
export ALWAYS_ON="true"
export HTTP20_ENABLED="true"
export FTPS_STATE="Disabled"

# Application Settings
export APP_SETTINGS="ASPNETCORE_ENVIRONMENT=Production DATABASE_URL=connection-string"
```

### Virtual Machine Configuration
```bash
# VM Specifications
export VM_SIZE="Standard_B2s"
export VM_IMAGE="UbuntuLTS"
export ADMIN_USERNAME="azureuser"
export AUTHENTICATION_TYPE="ssh"

# Storage Configuration
export OS_DISK_SIZE="30"
export OS_DISK_TYPE="Premium_LRS"
export DATA_DISK_SIZE="100"
export DATA_DISK_TYPE="Standard_LRS"

# Network Configuration
export PUBLIC_IP_ALLOCATION="Static"
export NSG_RULES="SSH,HTTP,HTTPS"
```

### AKS Configuration
```bash
# Cluster Configuration
export KUBERNETES_VERSION="1.28.3"
export NODE_COUNT="3"
export NODE_VM_SIZE="Standard_DS2_v2"
export NODE_OS_DISK_SIZE="30"

# Networking
export NETWORK_PLUGIN="azure"
export SERVICE_CIDR="10.0.0.0/16"
export DNS_SERVICE_IP="10.0.0.10"
export DOCKER_BRIDGE_CIDR="172.17.0.1/16"

# Add-ons
export ENABLE_MONITORING="true"
export ENABLE_HTTP_APPLICATION_ROUTING="false"
export ENABLE_AZURE_POLICY="true"
```

## 🛠️ Infrastructure as Code

### ARM Template Example
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "webAppName": {
      "type": "string",
      "metadata": {
        "description": "Name of the web app"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for all resources"
      }
    }
  },
  "variables": {
    "appServicePlanName": "[concat(parameters('webAppName'), '-plan')]"
  },
  "resources": [
    {
      "type": "Microsoft.Web/serverfarms",
      "apiVersion": "2021-02-01",
      "name": "[variables('appServicePlanName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "B1",
        "tier": "Basic"
      },
      "properties": {
        "reserved": false
      }
    },
    {
      "type": "Microsoft.Web/sites",
      "apiVersion": "2021-02-01",
      "name": "[parameters('webAppName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]"
      ],
      "properties": {
        "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]",
        "siteConfig": {
          "netFrameworkVersion": "v8.0",
          "alwaysOn": true,
          "http20Enabled": true,
          "ftpsState": "Disabled"
        }
      }
    }
  ],
  "outputs": {
    "webAppUrl": {
      "type": "string",
      "value": "[concat('https://', parameters('webAppName'), '.azurewebsites.net')]"
    }
  }
}
```

### Bicep Template Example
```bicep
param webAppName string
param location string = resourceGroup().location
param sku string = 'B1'

var appServicePlanName = '${webAppName}-plan'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
    tier: 'Basic'
  }
  properties: {
    reserved: false
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      alwaysOn: true
      http20Enabled: true
      ftpsState: 'Disabled'
    }
  }
}

output webAppUrl string = 'https://${webAppName}.azurewebsites.net'
```

### Terraform Example
```hcl
# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_service_plan" "main" {
  name                = "${var.app_name}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  os_type            = "Linux"
  sku_name           = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_service_plan.main.location
  service_plan_id    = azurerm_service_plan.main.id

  site_config {
    always_on = true
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "NODE_ENV" = "production"
  }
}
```

## 🔍 Monitoring and Logging

### Application Insights Integration
- Application performance monitoring
- Custom telemetry
- Availability tests
- Usage analytics
- Dependency tracking

### Azure Monitor
- Metrics and alerts
- Log analytics
- Workbooks and dashboards
- Action groups
- Service health

### Log Analytics
- Centralized logging
- Query language (KQL)
- Custom logs
- Log-based alerts
- Data retention

## 💰 Cost Optimization

### Best Practices
- Right-sizing resources
- Reserved instances
- Azure Hybrid Benefit
- Dev/Test pricing
- Auto-shutdown policies

### Cost Management
- Budget alerts
- Cost analysis
- Resource optimization
- Advisor recommendations
- Spending limits

## 🔒 Security Best Practices

### Identity and Access Management
- Azure Active Directory integration
- Role-based access control (RBAC)
- Managed identities
- Conditional access
- Multi-factor authentication

### Network Security
- Virtual network configuration
- Network security groups
- Application security groups
- Azure Firewall
- DDoS protection

### Data Protection
- Encryption at rest
- Encryption in transit
- Key Vault integration
- Backup and recovery
- Data classification

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Caching Scripts](../../caching/README.md)
- [Framework Scripts](../../frameworks/README.md)