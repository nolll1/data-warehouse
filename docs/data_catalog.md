# Data Dictionary for Gold Layer

## Overview

The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of dimension tables and fact tables for specific business metrics.

---

## 1. GOLD.DIM_CUSTOMERS

- **Purpose:** Stores customer details enriched with demographic and geographic data.
- **Columns:**

| Column Name      | Data Type       | Description |
|------------------|----------------|------------|
| CUSTOMER_KEY     | INT            | Surrogate key uniquely identifying each customer record in the dimension table. |
| CUSTOMER_ID      | INT            | Unique numerical identifier assigned to each customer. |
| CUSTOMER_NUMBER  | NVARCHAR(50)   | Alphanumeric identifier representing the customer, used for tracking and referencing. |
| FIRST_NAME       | NVARCHAR(50)   | The customer's first name, as recorded in the system. |
| LAST_NAME        | NVARCHAR(50)   | The customer's last name or family name. |
| COUNTRY          | NVARCHAR(50)   | The country of residence for the customer (e.g., 'Australia'). |
| MARITAL_STATUS   | NVARCHAR(50)   | The marital status of the customer (e.g., 'Married', 'Single'). |
| GENDER           | NVARCHAR(50)   | The gender of the customer (e.g., 'Male', 'Female', 'n/a'). |
| BIRTHDATE        | DATE           | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06). |
| CREATE_DATE      | DATE           | The date and time when the customer record was created in the system. |

---

## 2. GOLD.DIM_PRODUCTS

- **Purpose:** Provides information about the products and their attributes.
- **Columns:**

| Column Name           | Data Type       | Description |
|------------------------|----------------|------------|
| PRODUCT_KEY           | INT            | Surrogate key uniquely identifying each product record in the product dimension table. |
| PRODUCT_ID            | INT            | A unique identifier assigned to the product for internal tracking and referencing. |
| PRODUCT_NUMBER        | NVARCHAR(50)   | A structured alphanumeric code representing the product, often used for categorization or inventory. |
| PRODUCT_NAME          | NVARCHAR(50)   | Descriptive name of the product, including key details such as type, color, and size. |
| CATEGORY_ID           | NVARCHAR(50)   | A unique identifier for the product's category, linking to its high-level classification. |
| CATEGORY              | NVARCHAR(50)   | The broader classification of the product (e.g., Bikes, Components) to group related items. |
| SUBCATEGORY           | NVARCHAR(50)   | A more detailed classification of the product within the category. |
| MAINTENANCE_REQUIRED  | NVARCHAR(50)   | Indicates whether the product requires maintenance (e.g., 'Yes', 'No'). |
| COST                  | INT            | The cost or base price of the product, measured in monetary units. |
| PRODUCT_LINE          | NVARCHAR(50)   | The specific product line or series to which the product belongs (e.g., Road, Mountain). |
| START_DATE            | DATE           | The date when the product became available for sale or use. |

---

## 3. GOLD.FACT_SALES

- **Purpose:** Stores transactional sales data for analytical purposes.
- **Columns:**

| Column Name     | Data Type     | Description |
|----------------|--------------|------------|
| ORDER_NUMBER   | NVARCHAR(50) | A unique alphanumeric identifier for each sales order (e.g., 'SO54496'). |
| CUSTOMER_KEY   | INT          | Surrogate key linking the order to the customer dimension table. |
| PRODUCT_KEY    | INT          | Surrogate key linking the order to the product dimension table. |
| ORDER_DATE     | DATE         | The date when the order was placed. |
| SHIPPING_DATE  | DATE         | The date when the order was shipped to the customer. |
| DUE_DATE       | DATE         | The date when the order payment was due. |
| SALES_AMOUNT   | INT          | The total monetary value of the sale for the line item, in whole currency units (e.g., 25). |
| QUANTITY       | INT          | The number of units of the product ordered for the line item (e.g., 1). |
| PRICE          | INT          | The price per unit of the product for the line item, in whole currency units (e.g., 25). |
