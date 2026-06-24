PRAGMA foreign_keys = ON;

DELETE FROM support_tickets;
DELETE FROM product_reviews;
DELETE FROM customer_events;
DELETE FROM cart_items;
DELETE FROM carts;
DELETE FROM marketing_campaigns;
DELETE FROM store_credit_transactions;
DELETE FROM store_credit_accounts;
DELETE FROM refunds;
DELETE FROM return_items;
DELETE FROM returns;
DELETE FROM fulfillment_items;
DELETE FROM shipment_events;
DELETE FROM shipments;
DELETE FROM fulfillments;
DELETE FROM payments;
DELETE FROM order_items;
DELETE FROM subscription_items;
DELETE FROM subscriptions;
DELETE FROM orders;
DELETE FROM discount_codes;
DELETE FROM inventory_levels;
DELETE FROM inventory_locations;
DELETE FROM product_variants;
DELETE FROM product_collections;
DELETE FROM collections;
DELETE FROM products;
DELETE FROM product_categories;
DELETE FROM vendors;
DELETE FROM customer_addresses;
DELETE FROM customers;
DELETE FROM staff_users;
DELETE FROM merchants;

INSERT INTO merchants (merchant_id, merchant_name, industry, plan_name, country_code, currency_code, created_at, is_active) VALUES
    (1, 'Northstar Outfitters', 'Outdoor apparel and gear', 'plus', 'US', 'USD', '2022-01-12 09:00:00', 1),
    (2, 'Bloom & Hearth', 'Home goods and decor', 'growth', 'US', 'USD', '2022-07-04 11:30:00', 1),
    (3, 'VoltCycle Components', 'Cycling parts and accessories', 'enterprise', 'US', 'USD', '2021-09-19 14:20:00', 1);

INSERT INTO staff_users (staff_user_id, merchant_id, full_name, email, role_name, hired_at, is_active) VALUES
    (1, 1, 'Maya Chen', 'maya@northstar.example', 'owner', '2022-01-12', 1),
    (2, 1, 'Leo Martinez', 'leo@northstar.example', 'fulfillment', '2023-03-18', 1),
    (3, 1, 'Avery Patel', 'avery@northstar.example', 'support', '2023-08-09', 1),
    (4, 2, 'Nora Brooks', 'nora@bloomhearth.example', 'owner', '2022-07-04', 1),
    (5, 2, 'Elena Wright', 'elena@bloomhearth.example', 'marketing', '2023-01-21', 1),
    (6, 3, 'Samir Rao', 'samir@voltcycle.example', 'owner', '2021-09-19', 1),
    (7, 3, 'Jules Morgan', 'jules@voltcycle.example', 'analyst', '2023-04-02', 1);

INSERT INTO customers (customer_id, merchant_id, first_name, last_name, email, phone, accepts_marketing, customer_tier, created_at, last_seen_at) VALUES
    (1, 1, 'Grace', 'Kim', 'grace.kim@example.com', '415-555-0111', 1, 'vip', '2023-05-01 10:04:00', '2024-05-30 08:14:00'),
    (2, 1, 'Owen', 'Miller', 'owen.miller@example.com', '303-555-0188', 0, 'silver', '2023-07-22 16:21:00', '2024-05-19 19:44:00'),
    (3, 1, 'Priya', 'Shah', 'priya.shah@example.com', '212-555-0199', 1, 'gold', '2024-01-15 12:05:00', '2024-05-27 21:00:00'),
    (4, 2, 'Caleb', 'Stone', 'caleb.stone@example.com', '503-555-0144', 1, 'standard', '2023-11-03 09:18:00', '2024-05-22 13:47:00'),
    (5, 2, 'Rina', 'Lopez', 'rina.lopez@example.com', '602-555-0177', 0, 'gold', '2023-09-29 15:32:00', '2024-05-25 10:09:00'),
    (6, 3, 'Dante', 'Rivera', 'dante.rivera@example.com', '720-555-0191', 1, 'vip', '2022-12-11 13:43:00', '2024-05-29 18:25:00'),
    (7, 3, 'Mei', 'Tanaka', 'mei.tanaka@example.com', '206-555-0133', 1, 'silver', '2023-10-14 08:57:00', '2024-05-18 11:11:00'),
    (8, 3, 'Jordan', 'Reed', 'jordan.reed@example.com', '512-555-0182', 0, 'standard', '2024-03-02 17:09:00', '2024-05-21 12:12:00');

INSERT INTO customer_addresses (address_id, customer_id, address_type, line1, line2, city, region, postal_code, country_code, is_default) VALUES
    (1, 1, 'shipping', '1818 Pine Street', NULL, 'San Francisco', 'CA', '94109', 'US', 1),
    (2, 1, 'billing', '1818 Pine Street', NULL, 'San Francisco', 'CA', '94109', 'US', 1),
    (3, 2, 'shipping', '22 Aspen Way', 'Apt 4B', 'Denver', 'CO', '80203', 'US', 1),
    (4, 3, 'shipping', '75 Mercer Street', NULL, 'New York', 'NY', '10012', 'US', 1),
    (5, 4, 'shipping', '440 Alder Avenue', NULL, 'Portland', 'OR', '97205', 'US', 1),
    (6, 5, 'shipping', '901 Desert View Road', NULL, 'Phoenix', 'AZ', '85004', 'US', 1),
    (7, 6, 'shipping', '114 Summit Lane', NULL, 'Boulder', 'CO', '80302', 'US', 1),
    (8, 7, 'shipping', '612 Lakeview Drive', NULL, 'Seattle', 'WA', '98101', 'US', 1),
    (9, 8, 'shipping', '508 Congress Avenue', 'Suite 210', 'Austin', 'TX', '78701', 'US', 1);

INSERT INTO product_categories (category_id, merchant_id, category_name, parent_category_id) VALUES
    (1, 1, 'Apparel', NULL),
    (2, 1, 'Backpacks', NULL),
    (3, 1, 'Outerwear', 1),
    (4, 2, 'Lighting', NULL),
    (5, 2, 'Kitchen', NULL),
    (6, 2, 'Textiles', NULL),
    (7, 3, 'Drivetrain', NULL),
    (8, 3, 'Wheels', NULL),
    (9, 3, 'Maintenance', NULL);

INSERT INTO vendors (vendor_id, merchant_id, vendor_name, contact_email, country_code, average_lead_time_days, is_active) VALUES
    (1, 1, 'Northstar Gear Co', 'ops@northstargear.example', 'US', 14, 1),
    (2, 1, 'Summit Knitworks', 'sales@summitknit.example', 'CA', 21, 1),
    (3, 2, 'Bloom Studio', 'partners@bloomstudio.example', 'US', 10, 1),
    (4, 2, 'Clay & Co', 'wholesale@clayco.example', 'PT', 28, 1),
    (5, 3, 'VoltCycle Labs', 'supply@voltcyclelabs.example', 'TW', 35, 1),
    (6, 3, 'Workshop Nine', 'orders@workshopnine.example', 'US', 12, 1);

INSERT INTO products (product_id, merchant_id, category_id, vendor_id, title, vendor_name, product_type, status, published_at, created_at, updated_at) VALUES
    (1, 1, 3, 1, 'Alpine Shell Jacket', 'Northstar Gear Co', 'jacket', 'active', '2023-09-01 07:00:00', '2023-08-15 10:00:00', '2024-05-10 09:30:00'),
    (2, 1, 2, 1, 'Trailhead 35L Pack', 'Northstar Gear Co', 'backpack', 'active', '2023-03-10 07:00:00', '2023-02-20 14:12:00', '2024-04-22 11:00:00'),
    (3, 1, 1, 2, 'Merino Base Layer', 'Summit Knitworks', 'shirt', 'active', '2023-11-05 07:00:00', '2023-10-12 09:45:00', '2024-05-18 16:10:00'),
    (4, 2, 4, 3, 'Aurora Table Lamp', 'Bloom Studio', 'lamp', 'active', '2023-08-14 08:00:00', '2023-07-28 15:00:00', '2024-05-20 10:30:00'),
    (5, 2, 5, 4, 'Stoneware Dinner Set', 'Clay & Co', 'dinnerware', 'active', '2023-10-09 08:00:00', '2023-09-01 09:20:00', '2024-05-08 12:15:00'),
    (6, 2, 6, 3, 'Linen Throw Blanket', 'Bloom Studio', 'textile', 'draft', NULL, '2024-05-01 10:00:00', '2024-05-24 09:00:00'),
    (7, 3, 7, 5, 'Apex 12-Speed Cassette', 'VoltCycle Labs', 'cassette', 'active', '2023-02-18 06:30:00', '2023-01-28 14:00:00', '2024-05-01 11:40:00'),
    (8, 3, 8, 5, 'Carbon Aero Wheelset', 'VoltCycle Labs', 'wheelset', 'active', '2023-06-21 06:30:00', '2023-05-30 08:22:00', '2024-05-16 10:20:00'),
    (9, 3, 9, 6, 'Pro Chain Care Kit', 'Workshop Nine', 'maintenance_kit', 'active', '2024-01-08 06:30:00', '2023-12-12 13:10:00', '2024-05-17 14:55:00');

INSERT INTO collections (collection_id, merchant_id, collection_name, collection_type, handle, published_at, is_active) VALUES
    (1, 1, 'Rain Ready Essentials', 'manual', 'rain-ready-essentials', '2024-04-01 07:00:00', 1),
    (2, 1, 'Best Sellers', 'automated', 'best-sellers', '2023-01-01 07:00:00', 1),
    (3, 2, 'Spring Home Refresh', 'manual', 'spring-home-refresh', '2024-03-15 08:00:00', 1),
    (4, 2, 'New Arrivals', 'automated', 'new-arrivals', '2024-05-01 08:00:00', 1),
    (5, 3, 'Race Week Upgrades', 'manual', 'race-week-upgrades', '2024-05-20 06:30:00', 1),
    (6, 3, 'Service Essentials', 'manual', 'service-essentials', '2024-01-08 06:30:00', 1);

INSERT INTO product_collections (product_id, collection_id, sort_order) VALUES
    (1, 1, 1),
    (2, 1, 2),
    (1, 2, 1),
    (3, 2, 2),
    (4, 3, 1),
    (5, 3, 2),
    (6, 4, 1),
    (8, 5, 1),
    (7, 5, 2),
    (9, 6, 1);

INSERT INTO product_variants (variant_id, product_id, sku, option_1_name, option_1_value, option_2_name, option_2_value, price_cents, compare_at_price_cents, cost_cents, weight_grams, is_taxable, is_active) VALUES
    (1, 1, 'NS-JACKET-BLK-M', 'Color', 'Black', 'Size', 'M', 28900, 32900, 14100, 680, 1, 1),
    (2, 1, 'NS-JACKET-BLK-L', 'Color', 'Black', 'Size', 'L', 28900, 32900, 14100, 710, 1, 1),
    (3, 2, 'NS-PACK-35-GRN', 'Color', 'Forest', NULL, NULL, 17900, NULL, 8200, 1180, 1, 1),
    (4, 3, 'NS-MERINO-NAV-M', 'Color', 'Navy', 'Size', 'M', 8900, NULL, 3600, 250, 1, 1),
    (5, 4, 'BH-LAMP-BRASS', 'Finish', 'Brass', NULL, NULL, 12400, 14900, 5400, 2100, 1, 1),
    (6, 5, 'BH-DINNER-STONE', 'Color', 'Stone', NULL, NULL, 15600, NULL, 7100, 5200, 1, 1),
    (7, 6, 'BH-THROW-SAGE', 'Color', 'Sage', NULL, NULL, 9800, NULL, 4200, 900, 1, 1),
    (8, 7, 'VC-CASS-10-36', 'Range', '10-36T', NULL, NULL, 21900, NULL, 9900, 280, 1, 1),
    (9, 8, 'VC-WHEEL-50DISC', 'Depth', '50mm', 'Brake', 'Disc', 129900, 149900, 71000, 1520, 1, 1),
    (10, 9, 'VC-CARE-PRO', 'Kit', 'Pro', NULL, NULL, 4800, NULL, 1900, 620, 1, 1);

INSERT INTO inventory_locations (location_id, merchant_id, location_name, location_type, city, region, country_code, is_active) VALUES
    (1, 1, 'Reno Fulfillment Center', 'warehouse', 'Reno', 'NV', 'US', 1),
    (2, 1, 'Denver Retail Store', 'storefront', 'Denver', 'CO', 'US', 1),
    (3, 2, 'Portland Studio Warehouse', 'warehouse', 'Portland', 'OR', 'US', 1),
    (4, 2, 'Phoenix 3PL', 'third_party_logistics', 'Phoenix', 'AZ', 'US', 1),
    (5, 3, 'Boulder Distribution Hub', 'warehouse', 'Boulder', 'CO', 'US', 1),
    (6, 3, 'Seattle Service Center', 'storefront', 'Seattle', 'WA', 'US', 1);

INSERT INTO inventory_levels (variant_id, location_id, quantity_on_hand, quantity_reserved, reorder_point, updated_at) VALUES
    (1, 1, 42, 6, 12, '2024-05-31 08:00:00'),
    (1, 2, 7, 1, 4, '2024-05-31 08:00:00'),
    (2, 1, 18, 4, 12, '2024-05-31 08:00:00'),
    (3, 1, 65, 8, 15, '2024-05-31 08:00:00'),
    (4, 2, 5, 2, 10, '2024-05-31 08:00:00'),
    (5, 3, 16, 3, 8, '2024-05-31 08:00:00'),
    (5, 4, 28, 5, 8, '2024-05-31 08:00:00'),
    (6, 3, 9, 4, 10, '2024-05-31 08:00:00'),
    (7, 3, 24, 0, 6, '2024-05-31 08:00:00'),
    (8, 5, 31, 3, 8, '2024-05-31 08:00:00'),
    (9, 5, 6, 2, 5, '2024-05-31 08:00:00'),
    (9, 6, 2, 1, 3, '2024-05-31 08:00:00'),
    (10, 6, 44, 6, 12, '2024-05-31 08:00:00');

INSERT INTO discount_codes (discount_code_id, merchant_id, code, discount_type, discount_value, starts_at, ends_at, usage_limit, is_active) VALUES
    (1, 1, 'SUMMIT15', 'percentage', 15, '2024-05-01 00:00:00', '2024-06-01 00:00:00', 500, 1),
    (2, 1, 'FREESHIP', 'free_shipping', 0, '2024-04-01 00:00:00', NULL, NULL, 1),
    (3, 2, 'HOME25', 'fixed_amount', 2500, '2024-05-10 00:00:00', '2024-05-31 23:59:59', 300, 1),
    (4, 3, 'RACEWEEK', 'percentage', 10, '2024-05-20 00:00:00', '2024-06-03 00:00:00', 1000, 1);

INSERT INTO orders (order_id, merchant_id, customer_id, order_number, order_status, financial_status, fulfillment_status, source_channel, discount_code_id, subtotal_cents, discount_cents, tax_cents, shipping_cents, total_cents, placed_at, cancelled_at) VALUES
    (1, 1, 1, 'NS-1001', 'closed', 'paid', 'fulfilled', 'online_store', 1, 37800, 5670, 2651, 0, 34781, '2024-05-12 10:14:00', NULL),
    (2, 1, 2, 'NS-1002', 'open', 'paid', 'partial', 'online_store', 2, 46800, 0, 3744, 0, 50544, '2024-05-18 17:31:00', NULL),
    (3, 1, 3, 'NS-1003', 'closed', 'partially_refunded', 'returned', 'social', NULL, 8900, 0, 712, 700, 10312, '2024-05-20 20:22:00', NULL),
    (4, 2, 4, 'BH-2001', 'closed', 'paid', 'fulfilled', 'online_store', 3, 28000, 2500, 2040, 900, 28440, '2024-05-16 09:03:00', NULL),
    (5, 2, 5, 'BH-2002', 'open', 'authorized', 'unfulfilled', 'marketplace', NULL, 15600, 0, 1248, 1100, 17948, '2024-05-25 12:49:00', NULL),
    (6, 3, 6, 'VC-3001', 'closed', 'paid', 'fulfilled', 'online_store', 4, 151800, 15180, 10930, 0, 147550, '2024-05-21 07:18:00', NULL),
    (7, 3, 7, 'VC-3002', 'open', 'paid', 'unfulfilled', 'subscription', NULL, 9600, 0, 768, 500, 10868, '2024-05-26 06:42:00', NULL),
    (8, 3, 8, 'VC-3003', 'cancelled', 'voided', 'unfulfilled', 'online_store', NULL, 129900, 0, 0, 0, 0, '2024-05-27 22:10:00', '2024-05-28 08:15:00');

INSERT INTO subscriptions (subscription_id, merchant_id, customer_id, subscription_status, billing_interval, started_at, next_billing_at, cancelled_at, cancellation_reason) VALUES
    (1, 1, 1, 'active', 'quarterly', '2024-02-12 10:00:00', '2024-08-12 10:00:00', NULL, NULL),
    (2, 2, 5, 'paused', 'monthly', '2024-04-01 09:00:00', '2024-06-01 09:00:00', NULL, NULL),
    (3, 3, 7, 'active', 'monthly', '2024-03-26 06:00:00', '2024-06-26 06:00:00', NULL, NULL),
    (4, 3, 8, 'cancelled', 'monthly', '2024-02-27 07:30:00', NULL, '2024-05-28 08:20:00', 'Cancelled after wheelset order was voided');

INSERT INTO subscription_items (subscription_item_id, subscription_id, variant_id, quantity, unit_price_cents) VALUES
    (1, 1, 4, 2, 8900),
    (2, 2, 7, 1, 9800),
    (3, 3, 10, 2, 4800),
    (4, 4, 10, 1, 4800);

INSERT INTO order_items (order_item_id, order_id, variant_id, quantity, unit_price_cents, discount_cents, tax_cents, fulfillment_status) VALUES
    (1, 1, 1, 1, 28900, 4335, 1965, 'fulfilled'),
    (2, 1, 4, 1, 8900, 1335, 686, 'fulfilled'),
    (3, 2, 2, 1, 28900, 0, 2312, 'fulfilled'),
    (4, 2, 3, 1, 17900, 0, 1432, 'unfulfilled'),
    (5, 3, 4, 1, 8900, 0, 712, 'returned'),
    (6, 4, 5, 1, 12400, 1107, 903, 'fulfilled'),
    (7, 4, 6, 1, 15600, 1393, 1137, 'fulfilled'),
    (8, 5, 6, 1, 15600, 0, 1248, 'unfulfilled'),
    (9, 6, 9, 1, 129900, 12990, 9353, 'fulfilled'),
    (10, 6, 8, 1, 21900, 2190, 1577, 'fulfilled'),
    (11, 7, 10, 2, 4800, 0, 768, 'unfulfilled'),
    (12, 8, 9, 1, 129900, 0, 0, 'unfulfilled');

INSERT INTO payments (payment_id, order_id, payment_provider, payment_status, amount_cents, transaction_reference, processed_at) VALUES
    (1, 1, 'shop_pay', 'captured', 34781, 'txn_ns_1001_capture', '2024-05-12 10:15:00'),
    (2, 2, 'stripe', 'captured', 50544, 'txn_ns_1002_capture', '2024-05-18 17:32:00'),
    (3, 3, 'paypal', 'partially_refunded', 10312, 'txn_ns_1003_capture', '2024-05-20 20:24:00'),
    (4, 4, 'shop_pay', 'captured', 28440, 'txn_bh_2001_capture', '2024-05-16 09:04:00'),
    (5, 5, 'stripe', 'authorized', 17948, 'txn_bh_2002_auth', '2024-05-25 12:50:00'),
    (6, 6, 'stripe', 'captured', 147550, 'txn_vc_3001_capture', '2024-05-21 07:20:00'),
    (7, 7, 'gift_card', 'captured', 10868, 'txn_vc_3002_capture', '2024-05-26 06:43:00'),
    (8, 8, 'stripe', 'voided', 0, 'txn_vc_3003_void', '2024-05-28 08:16:00');

INSERT INTO fulfillments (fulfillment_id, order_id, location_id, carrier_name, tracking_number, fulfillment_status, shipped_at, delivered_at) VALUES
    (1, 1, 1, 'UPS', '1ZNS1001', 'delivered', '2024-05-13 08:00:00', '2024-05-15 13:10:00'),
    (2, 2, 1, 'FedEx', 'FDXNS1002A', 'in_transit', '2024-05-19 09:30:00', NULL),
    (3, 3, 2, 'USPS', 'USPSNS1003', 'returned', '2024-05-21 10:45:00', '2024-05-23 15:40:00'),
    (4, 4, 4, 'UPS', '1ZBH2001', 'delivered', '2024-05-17 07:50:00', '2024-05-20 11:30:00'),
    (5, 6, 5, 'DHL', 'DHLVC3001', 'delivered', '2024-05-21 16:20:00', '2024-05-24 09:05:00');

INSERT INTO shipments (shipment_id, fulfillment_id, carrier_name, service_level, tracking_number, shipment_status, estimated_delivery_at, shipped_at, delivered_at, shipping_cost_cents) VALUES
    (1, 1, 'UPS', 'standard', '1ZNS1001', 'delivered', '2024-05-16 20:00:00', '2024-05-13 08:00:00', '2024-05-15 13:10:00', 820),
    (2, 2, 'FedEx', 'expedited', 'FDXNS1002A', 'in_transit', '2024-05-22 20:00:00', '2024-05-19 09:30:00', NULL, 1130),
    (3, 3, 'USPS', 'standard', 'USPSNS1003', 'returned', '2024-05-24 20:00:00', '2024-05-21 10:45:00', '2024-05-23 15:40:00', 620),
    (4, 4, 'UPS', 'standard', '1ZBH2001', 'delivered', '2024-05-21 20:00:00', '2024-05-17 07:50:00', '2024-05-20 11:30:00', 1040),
    (5, 5, 'DHL', 'overnight', 'DHLVC3001', 'delivered', '2024-05-24 12:00:00', '2024-05-21 16:20:00', '2024-05-24 09:05:00', 2480);

INSERT INTO shipment_events (shipment_event_id, shipment_id, event_status, event_city, event_region, event_country_code, occurred_at, event_notes) VALUES
    (1, 1, 'label_created', 'Reno', 'NV', 'US', '2024-05-12 16:20:00', 'Label created by warehouse'),
    (2, 1, 'picked_up', 'Reno', 'NV', 'US', '2024-05-13 08:00:00', 'Package picked up'),
    (3, 1, 'delivered', 'San Francisco', 'CA', 'US', '2024-05-15 13:10:00', 'Delivered to front desk'),
    (4, 2, 'label_created', 'Reno', 'NV', 'US', '2024-05-18 19:10:00', 'First package in split fulfillment'),
    (5, 2, 'in_transit', 'Salt Lake City', 'UT', 'US', '2024-05-20 06:35:00', 'Departed regional facility'),
    (6, 3, 'picked_up', 'Denver', 'CO', 'US', '2024-05-21 10:45:00', 'Retail return shipment'),
    (7, 3, 'return_to_sender', 'Denver', 'CO', 'US', '2024-05-23 15:40:00', 'Returned to store location'),
    (8, 4, 'picked_up', 'Phoenix', 'AZ', 'US', '2024-05-17 07:50:00', 'Picked up from 3PL'),
    (9, 4, 'delivered', 'Portland', 'OR', 'US', '2024-05-20 11:30:00', 'Delivered to porch'),
    (10, 5, 'picked_up', 'Boulder', 'CO', 'US', '2024-05-21 16:20:00', 'Priority pickup'),
    (11, 5, 'exception', 'Cincinnati', 'OH', 'US', '2024-05-22 22:15:00', 'Weather delay at hub'),
    (12, 5, 'delivered', 'Boulder', 'CO', 'US', '2024-05-24 09:05:00', 'Delivered after delay');

INSERT INTO fulfillment_items (fulfillment_id, order_item_id, quantity) VALUES
    (1, 1, 1),
    (1, 2, 1),
    (2, 3, 1),
    (3, 5, 1),
    (4, 6, 1),
    (4, 7, 1),
    (5, 9, 1),
    (5, 10, 1);

INSERT INTO returns (return_id, order_id, requested_at, return_status, reason_code, customer_comment) VALUES
    (1, 3, '2024-05-24 08:12:00', 'received', 'too_small', 'Loved the fabric but need a larger size.'),
    (2, 4, '2024-05-23 18:19:00', 'requested', 'damaged', 'Lamp shade arrived dented.');

INSERT INTO return_items (return_item_id, return_id, order_item_id, quantity, restock_disposition) VALUES
    (1, 1, 5, 1, 'restock'),
    (2, 2, 6, 1, 'inspect');

INSERT INTO refunds (refund_id, order_id, return_id, amount_cents, reason, processed_at) VALUES
    (1, 3, 1, 9612, 'Returned merino base layer excluding original shipping', '2024-05-26 10:05:00');

INSERT INTO store_credit_accounts (store_credit_account_id, merchant_id, customer_id, current_balance_cents, created_at, updated_at) VALUES
    (1, 1, 3, 2500, '2024-05-26 10:06:00', '2024-05-26 10:06:00'),
    (2, 2, 4, 1000, '2024-05-23 19:00:00', '2024-05-23 19:00:00'),
    (3, 3, 8, 5000, '2024-05-28 09:10:00', '2024-05-28 09:10:00');

INSERT INTO store_credit_transactions (store_credit_transaction_id, store_credit_account_id, order_id, refund_id, transaction_type, amount_cents, balance_after_cents, reason, created_at) VALUES
    (1, 1, 3, 1, 'refund_credit', 2500, 2500, 'Goodwill credit after size return', '2024-05-26 10:06:00'),
    (2, 2, 4, NULL, 'grant', 1000, 1000, 'Damaged lamp shade apology credit', '2024-05-23 19:00:00'),
    (3, 3, 8, NULL, 'grant', 5000, 5000, 'Retention credit after cancelled wheelset order', '2024-05-28 09:10:00');

INSERT INTO marketing_campaigns (campaign_id, merchant_id, campaign_name, channel, budget_cents, started_at, ended_at) VALUES
    (1, 1, 'May Summit Sale', 'email', 180000, '2024-05-01 00:00:00', '2024-05-31 23:59:59'),
    (2, 1, 'Trail Season Launch', 'paid_social', 240000, '2024-04-15 00:00:00', NULL),
    (3, 2, 'Memorial Day Home Refresh', 'paid_search', 120000, '2024-05-10 00:00:00', '2024-05-28 23:59:59'),
    (4, 3, 'Race Week Performance Push', 'email', 90000, '2024-05-20 00:00:00', '2024-06-03 00:00:00');

INSERT INTO carts (cart_id, merchant_id, customer_id, cart_status, source_channel, created_at, updated_at, converted_order_id) VALUES
    (1, 1, 1, 'converted', 'online_store', '2024-05-12 09:58:00', '2024-05-12 10:14:00', 1),
    (2, 1, 3, 'abandoned', 'social', '2024-05-28 19:30:00', '2024-05-28 20:05:00', NULL),
    (3, 2, 5, 'active', 'marketplace', '2024-05-29 11:25:00', '2024-05-29 11:37:00', NULL),
    (4, 3, 8, 'abandoned', 'online_store', '2024-05-27 21:53:00', '2024-05-27 22:08:00', NULL);

INSERT INTO cart_items (cart_item_id, cart_id, variant_id, quantity, added_at) VALUES
    (1, 1, 1, 1, '2024-05-12 09:59:00'),
    (2, 1, 4, 1, '2024-05-12 10:01:00'),
    (3, 2, 3, 1, '2024-05-28 19:31:00'),
    (4, 2, 4, 2, '2024-05-28 19:35:00'),
    (5, 3, 5, 1, '2024-05-29 11:26:00'),
    (6, 4, 9, 1, '2024-05-27 21:54:00');

INSERT INTO customer_events (customer_event_id, merchant_id, customer_id, session_id, event_type, product_id, collection_id, cart_id, order_id, campaign_id, source_channel, device_type, occurred_at, metadata_json) VALUES
    (1, 1, 1, 'sess_ns_grace_001', 'email_click', NULL, NULL, NULL, NULL, 1, 'email', 'mobile', '2024-05-12 09:52:00', '{"utm_campaign":"May Summit Sale"}'),
    (2, 1, 1, 'sess_ns_grace_001', 'collection_view', NULL, 1, NULL, NULL, 1, 'email', 'mobile', '2024-05-12 09:55:00', '{"collection_handle":"rain-ready-essentials"}'),
    (3, 1, 1, 'sess_ns_grace_001', 'product_view', 1, NULL, NULL, NULL, 1, 'email', 'mobile', '2024-05-12 09:58:00', '{"sku":"NS-JACKET-BLK-M"}'),
    (4, 1, 1, 'sess_ns_grace_001', 'add_to_cart', 1, NULL, 1, NULL, 1, 'email', 'mobile', '2024-05-12 09:59:00', '{"quantity":1}'),
    (5, 1, 1, 'sess_ns_grace_001', 'checkout_completed', NULL, NULL, 1, 1, 1, 'email', 'mobile', '2024-05-12 10:14:00', '{"order_number":"NS-1001"}'),
    (6, 1, 3, 'sess_ns_priya_002', 'product_view', 2, NULL, NULL, NULL, 2, 'paid_social', 'desktop', '2024-05-28 19:28:00', '{"referrer":"instagram"}'),
    (7, 1, 3, 'sess_ns_priya_002', 'add_to_cart', 2, NULL, 2, NULL, 2, 'paid_social', 'desktop', '2024-05-28 19:31:00', '{"quantity":1}'),
    (8, 1, 3, 'sess_ns_priya_002', 'checkout_started', NULL, NULL, 2, NULL, 2, 'paid_social', 'desktop', '2024-05-28 19:40:00', '{"checkout_step":"shipping"}'),
    (9, 2, 5, 'sess_bh_rina_001', 'search', NULL, NULL, NULL, NULL, 3, 'paid_search', 'mobile', '2024-05-29 11:20:00', '{"query":"brass lamp"}'),
    (10, 2, 5, 'sess_bh_rina_001', 'product_view', 4, NULL, NULL, NULL, 3, 'paid_search', 'mobile', '2024-05-29 11:24:00', '{"sku":"BH-LAMP-BRASS"}'),
    (11, 2, 5, 'sess_bh_rina_001', 'add_to_cart', 4, NULL, 3, NULL, 3, 'paid_search', 'mobile', '2024-05-29 11:26:00', '{"quantity":1}'),
    (12, 3, 6, 'sess_vc_dante_001', 'email_click', NULL, NULL, NULL, NULL, 4, 'email', 'desktop', '2024-05-21 07:05:00', '{"utm_campaign":"Race Week Performance Push"}'),
    (13, 3, 6, 'sess_vc_dante_001', 'product_view', 8, 5, NULL, NULL, 4, 'email', 'desktop', '2024-05-21 07:11:00', '{"sku":"VC-WHEEL-50DISC"}'),
    (14, 3, 6, 'sess_vc_dante_001', 'checkout_completed', NULL, NULL, NULL, 6, 4, 'email', 'desktop', '2024-05-21 07:18:00', '{"order_number":"VC-3001"}'),
    (15, 3, 8, 'sess_vc_jordan_001', 'product_view', 8, 5, NULL, NULL, NULL, 'organic_search', 'tablet', '2024-05-27 21:53:00', '{"query":"carbon disc wheels"}'),
    (16, 3, 8, 'sess_vc_jordan_001', 'add_to_cart', 8, NULL, 4, NULL, NULL, 'organic_search', 'tablet', '2024-05-27 21:54:00', '{"quantity":1}');

INSERT INTO product_reviews (product_review_id, merchant_id, product_id, customer_id, order_id, rating, review_title, review_body, moderation_status, is_verified_purchase, created_at) VALUES
    (1, 1, 1, 1, 1, 5, 'Dry through a full storm', 'The jacket packed small and held up during a rainy weekend hike.', 'approved', 1, '2024-05-18 10:00:00'),
    (2, 1, 3, 3, 3, 3, 'Runs smaller than expected', 'Fabric is excellent, but sizing felt tight compared with the chart.', 'approved', 1, '2024-05-24 08:10:00'),
    (3, 2, 4, 4, 4, 2, 'Beautiful lamp, damaged shade', 'The base is great but the shade arrived dented.', 'approved', 1, '2024-05-23 18:14:00'),
    (4, 2, 5, 5, 5, 4, 'Looks handmade', 'Nice weight and color, still waiting for fulfillment.', 'pending', 1, '2024-05-26 09:30:00'),
    (5, 3, 8, 6, 6, 5, 'Fast and stiff wheelset', 'Noticeable speed gain on flats and handled crosswinds better than expected.', 'approved', 1, '2024-05-25 16:45:00'),
    (6, 3, 9, 7, 7, 4, 'Great maintenance bundle', 'Good recurring kit for keeping bikes ready through race season.', 'approved', 1, '2024-05-27 12:20:00');

INSERT INTO support_tickets (ticket_id, merchant_id, customer_id, order_id, assigned_staff_user_id, ticket_status, priority, topic, opened_at, resolved_at) VALUES
    (1, 1, 2, 2, 3, 'open', 'high', 'shipping', '2024-05-20 09:17:00', NULL),
    (2, 1, 3, 3, 3, 'resolved', 'normal', 'return', '2024-05-24 08:20:00', '2024-05-26 10:10:00'),
    (3, 2, 4, 4, NULL, 'pending', 'high', 'return', '2024-05-23 18:25:00', NULL),
    (4, 2, 5, 5, NULL, 'open', 'normal', 'billing', '2024-05-25 13:05:00', NULL),
    (5, 3, 6, 6, 7, 'closed', 'low', 'product_question', '2024-05-21 08:00:00', '2024-05-21 12:45:00'),
    (6, 3, 8, 8, 7, 'resolved', 'urgent', 'billing', '2024-05-28 08:20:00', '2024-05-28 09:01:00');
