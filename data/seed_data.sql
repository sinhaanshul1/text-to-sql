PRAGMA foreign_keys = ON;

DELETE FROM support_tickets;
DELETE FROM cart_items;
DELETE FROM carts;
DELETE FROM marketing_campaigns;
DELETE FROM refunds;
DELETE FROM return_items;
DELETE FROM returns;
DELETE FROM fulfillment_items;
DELETE FROM fulfillments;
DELETE FROM payments;
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM discount_codes;
DELETE FROM inventory_levels;
DELETE FROM inventory_locations;
DELETE FROM product_variants;
DELETE FROM products;
DELETE FROM product_categories;
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

INSERT INTO products (product_id, merchant_id, category_id, title, vendor_name, product_type, status, published_at, created_at, updated_at) VALUES
    (1, 1, 3, 'Alpine Shell Jacket', 'Northstar Gear Co', 'jacket', 'active', '2023-09-01 07:00:00', '2023-08-15 10:00:00', '2024-05-10 09:30:00'),
    (2, 1, 2, 'Trailhead 35L Pack', 'Northstar Gear Co', 'backpack', 'active', '2023-03-10 07:00:00', '2023-02-20 14:12:00', '2024-04-22 11:00:00'),
    (3, 1, 1, 'Merino Base Layer', 'Summit Knitworks', 'shirt', 'active', '2023-11-05 07:00:00', '2023-10-12 09:45:00', '2024-05-18 16:10:00'),
    (4, 2, 4, 'Aurora Table Lamp', 'Bloom Studio', 'lamp', 'active', '2023-08-14 08:00:00', '2023-07-28 15:00:00', '2024-05-20 10:30:00'),
    (5, 2, 5, 'Stoneware Dinner Set', 'Clay & Co', 'dinnerware', 'active', '2023-10-09 08:00:00', '2023-09-01 09:20:00', '2024-05-08 12:15:00'),
    (6, 2, 6, 'Linen Throw Blanket', 'Bloom Studio', 'textile', 'draft', NULL, '2024-05-01 10:00:00', '2024-05-24 09:00:00'),
    (7, 3, 7, 'Apex 12-Speed Cassette', 'VoltCycle Labs', 'cassette', 'active', '2023-02-18 06:30:00', '2023-01-28 14:00:00', '2024-05-01 11:40:00'),
    (8, 3, 8, 'Carbon Aero Wheelset', 'VoltCycle Labs', 'wheelset', 'active', '2023-06-21 06:30:00', '2023-05-30 08:22:00', '2024-05-16 10:20:00'),
    (9, 3, 9, 'Pro Chain Care Kit', 'Workshop Nine', 'maintenance_kit', 'active', '2024-01-08 06:30:00', '2023-12-12 13:10:00', '2024-05-17 14:55:00');

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

INSERT INTO support_tickets (ticket_id, merchant_id, customer_id, order_id, assigned_staff_user_id, ticket_status, priority, topic, opened_at, resolved_at) VALUES
    (1, 1, 2, 2, 3, 'open', 'high', 'shipping', '2024-05-20 09:17:00', NULL),
    (2, 1, 3, 3, 3, 'resolved', 'normal', 'return', '2024-05-24 08:20:00', '2024-05-26 10:10:00'),
    (3, 2, 4, 4, NULL, 'pending', 'high', 'return', '2024-05-23 18:25:00', NULL),
    (4, 2, 5, 5, NULL, 'open', 'normal', 'billing', '2024-05-25 13:05:00', NULL),
    (5, 3, 6, 6, 7, 'closed', 'low', 'product_question', '2024-05-21 08:00:00', '2024-05-21 12:45:00'),
    (6, 3, 8, 8, 7, 'resolved', 'urgent', 'billing', '2024-05-28 08:20:00', '2024-05-28 09:01:00');
