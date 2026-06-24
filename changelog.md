## 2026-06-24

- Expanded the Shopify-style schema with vendors, collections, subscription tables, store credit tables, customer events, product reviews, shipments, and shipment events.
- Made seed data more robust by adding vendor relationships, merchandising collections, recurring subscriptions, shipment tracking histories, store credit balances, web behavior events, and product reviews across merchants.

## 2026-06-22

- Added a Shopify-style SQLite sample database initializer in `data/init_db.py`.
- Added `data/schema.sql` with a multi-tenant commerce schema covering merchants, staff, customers, products, variants, inventory, orders, payments, fulfillments, returns, carts, campaigns, and support tickets.
- Added `data/seed_data.sql` with realistic seed data across multiple merchants and operational scenarios for future text-to-SQL dataset generation.
