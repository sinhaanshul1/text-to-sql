PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS merchants (
    merchant_id INTEGER PRIMARY KEY,
    merchant_name TEXT NOT NULL,
    industry TEXT NOT NULL,
    plan_name TEXT NOT NULL CHECK (plan_name IN ('starter', 'growth', 'plus', 'enterprise')),
    country_code TEXT NOT NULL,
    currency_code TEXT NOT NULL,
    created_at TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE IF NOT EXISTS staff_users (
    staff_user_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role_name TEXT NOT NULL CHECK (role_name IN ('owner', 'admin', 'fulfillment', 'support', 'marketing', 'analyst')),
    hired_at TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    accepts_marketing INTEGER NOT NULL DEFAULT 0 CHECK (accepts_marketing IN (0, 1)),
    customer_tier TEXT NOT NULL DEFAULT 'standard' CHECK (customer_tier IN ('standard', 'silver', 'gold', 'vip')),
    created_at TEXT NOT NULL,
    last_seen_at TEXT,
    UNIQUE (merchant_id, email),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS customer_addresses (
    address_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    address_type TEXT NOT NULL CHECK (address_type IN ('billing', 'shipping')),
    line1 TEXT NOT NULL,
    line2 TEXT,
    city TEXT NOT NULL,
    region TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country_code TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS vendors (
    vendor_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    vendor_name TEXT NOT NULL,
    contact_email TEXT,
    country_code TEXT NOT NULL,
    average_lead_time_days INTEGER NOT NULL CHECK (average_lead_time_days >= 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE (merchant_id, vendor_name),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS product_categories (
    category_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    category_name TEXT NOT NULL,
    parent_category_id INTEGER,
    UNIQUE (merchant_id, category_name),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (parent_category_id) REFERENCES product_categories(category_id)
);

CREATE TABLE IF NOT EXISTS products (
    product_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    vendor_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    vendor_name TEXT NOT NULL,
    product_type TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'archived')),
    published_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id),
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);

CREATE TABLE IF NOT EXISTS collections (
    collection_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    collection_name TEXT NOT NULL,
    collection_type TEXT NOT NULL CHECK (collection_type IN ('manual', 'automated')),
    handle TEXT NOT NULL,
    published_at TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE (merchant_id, handle),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS product_collections (
    product_id INTEGER NOT NULL,
    collection_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    PRIMARY KEY (product_id, collection_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (collection_id) REFERENCES collections(collection_id)
);

CREATE TABLE IF NOT EXISTS product_variants (
    variant_id INTEGER PRIMARY KEY,
    product_id INTEGER NOT NULL,
    sku TEXT NOT NULL UNIQUE,
    option_1_name TEXT,
    option_1_value TEXT,
    option_2_name TEXT,
    option_2_value TEXT,
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    compare_at_price_cents INTEGER CHECK (compare_at_price_cents IS NULL OR compare_at_price_cents >= price_cents),
    cost_cents INTEGER NOT NULL CHECK (cost_cents >= 0),
    weight_grams INTEGER NOT NULL DEFAULT 0 CHECK (weight_grams >= 0),
    is_taxable INTEGER NOT NULL DEFAULT 1 CHECK (is_taxable IN (0, 1)),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE IF NOT EXISTS inventory_locations (
    location_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    location_name TEXT NOT NULL,
    location_type TEXT NOT NULL CHECK (location_type IN ('warehouse', 'storefront', 'third_party_logistics')),
    city TEXT NOT NULL,
    region TEXT NOT NULL,
    country_code TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS inventory_levels (
    variant_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    reorder_point INTEGER NOT NULL DEFAULT 0 CHECK (reorder_point >= 0),
    updated_at TEXT NOT NULL,
    PRIMARY KEY (variant_id, location_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
    FOREIGN KEY (location_id) REFERENCES inventory_locations(location_id)
);

CREATE TABLE IF NOT EXISTS discount_codes (
    discount_code_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    code TEXT NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount', 'free_shipping')),
    discount_value INTEGER NOT NULL CHECK (discount_value >= 0),
    starts_at TEXT NOT NULL,
    ends_at TEXT,
    usage_limit INTEGER CHECK (usage_limit IS NULL OR usage_limit > 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE (merchant_id, code),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    order_number TEXT NOT NULL,
    order_status TEXT NOT NULL CHECK (order_status IN ('open', 'closed', 'cancelled')),
    financial_status TEXT NOT NULL CHECK (financial_status IN ('pending', 'authorized', 'paid', 'partially_refunded', 'refunded', 'voided')),
    fulfillment_status TEXT NOT NULL CHECK (fulfillment_status IN ('unfulfilled', 'partial', 'fulfilled', 'returned')),
    source_channel TEXT NOT NULL CHECK (source_channel IN ('online_store', 'pos', 'marketplace', 'social', 'subscription')),
    discount_code_id INTEGER,
    subtotal_cents INTEGER NOT NULL CHECK (subtotal_cents >= 0),
    discount_cents INTEGER NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    tax_cents INTEGER NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
    shipping_cents INTEGER NOT NULL DEFAULT 0 CHECK (shipping_cents >= 0),
    total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
    placed_at TEXT NOT NULL,
    cancelled_at TEXT,
    UNIQUE (merchant_id, order_number),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (discount_code_id) REFERENCES discount_codes(discount_code_id)
);

CREATE TABLE IF NOT EXISTS subscriptions (
    subscription_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    subscription_status TEXT NOT NULL CHECK (subscription_status IN ('active', 'paused', 'cancelled', 'expired')),
    billing_interval TEXT NOT NULL CHECK (billing_interval IN ('weekly', 'monthly', 'quarterly', 'annual')),
    started_at TEXT NOT NULL,
    next_billing_at TEXT,
    cancelled_at TEXT,
    cancellation_reason TEXT,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS subscription_items (
    subscription_item_id INTEGER PRIMARY KEY,
    subscription_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
    discount_cents INTEGER NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    tax_cents INTEGER NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
    fulfillment_status TEXT NOT NULL CHECK (fulfillment_status IN ('unfulfilled', 'partial', 'fulfilled', 'returned')),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    payment_provider TEXT NOT NULL CHECK (payment_provider IN ('stripe', 'paypal', 'shop_pay', 'gift_card', 'store_credit', 'manual')),
    payment_status TEXT NOT NULL CHECK (payment_status IN ('authorized', 'captured', 'failed', 'voided', 'refunded', 'partially_refunded')),
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    transaction_reference TEXT NOT NULL UNIQUE,
    processed_at TEXT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE IF NOT EXISTS fulfillments (
    fulfillment_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    carrier_name TEXT NOT NULL,
    tracking_number TEXT,
    fulfillment_status TEXT NOT NULL CHECK (fulfillment_status IN ('label_created', 'in_transit', 'delivered', 'failed', 'returned')),
    shipped_at TEXT,
    delivered_at TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (location_id) REFERENCES inventory_locations(location_id)
);

CREATE TABLE IF NOT EXISTS shipments (
    shipment_id INTEGER PRIMARY KEY,
    fulfillment_id INTEGER NOT NULL,
    carrier_name TEXT NOT NULL,
    service_level TEXT NOT NULL CHECK (service_level IN ('standard', 'expedited', 'overnight', 'freight')),
    tracking_number TEXT NOT NULL UNIQUE,
    shipment_status TEXT NOT NULL CHECK (shipment_status IN ('label_created', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'exception', 'returned')),
    estimated_delivery_at TEXT,
    shipped_at TEXT,
    delivered_at TEXT,
    shipping_cost_cents INTEGER NOT NULL DEFAULT 0 CHECK (shipping_cost_cents >= 0),
    FOREIGN KEY (fulfillment_id) REFERENCES fulfillments(fulfillment_id)
);

CREATE TABLE IF NOT EXISTS shipment_events (
    shipment_event_id INTEGER PRIMARY KEY,
    shipment_id INTEGER NOT NULL,
    event_status TEXT NOT NULL CHECK (event_status IN ('label_created', 'picked_up', 'arrived_at_facility', 'departed_facility', 'in_transit', 'out_for_delivery', 'delivered', 'exception', 'return_to_sender')),
    event_city TEXT,
    event_region TEXT,
    event_country_code TEXT,
    occurred_at TEXT NOT NULL,
    event_notes TEXT,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

CREATE TABLE IF NOT EXISTS fulfillment_items (
    fulfillment_id INTEGER NOT NULL,
    order_item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (fulfillment_id, order_item_id),
    FOREIGN KEY (fulfillment_id) REFERENCES fulfillments(fulfillment_id),
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
);

CREATE TABLE IF NOT EXISTS returns (
    return_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    requested_at TEXT NOT NULL,
    return_status TEXT NOT NULL CHECK (return_status IN ('requested', 'approved', 'received', 'rejected', 'closed')),
    reason_code TEXT NOT NULL CHECK (reason_code IN ('too_large', 'too_small', 'damaged', 'not_as_described', 'changed_mind', 'late_delivery')),
    customer_comment TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE IF NOT EXISTS return_items (
    return_item_id INTEGER PRIMARY KEY,
    return_id INTEGER NOT NULL,
    order_item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    restock_disposition TEXT NOT NULL CHECK (restock_disposition IN ('restock', 'inspect', 'discard')),
    FOREIGN KEY (return_id) REFERENCES returns(return_id),
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
);

CREATE TABLE IF NOT EXISTS refunds (
    refund_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    return_id INTEGER,
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    reason TEXT NOT NULL,
    processed_at TEXT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (return_id) REFERENCES returns(return_id)
);

CREATE TABLE IF NOT EXISTS store_credit_accounts (
    store_credit_account_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    current_balance_cents INTEGER NOT NULL DEFAULT 0 CHECK (current_balance_cents >= 0),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE (merchant_id, customer_id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS store_credit_transactions (
    store_credit_transaction_id INTEGER PRIMARY KEY,
    store_credit_account_id INTEGER NOT NULL,
    order_id INTEGER,
    refund_id INTEGER,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('grant', 'redeem', 'refund_credit', 'adjustment', 'expire')),
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    balance_after_cents INTEGER NOT NULL CHECK (balance_after_cents >= 0),
    reason TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (store_credit_account_id) REFERENCES store_credit_accounts(store_credit_account_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (refund_id) REFERENCES refunds(refund_id)
);

CREATE TABLE IF NOT EXISTS marketing_campaigns (
    campaign_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    campaign_name TEXT NOT NULL,
    channel TEXT NOT NULL CHECK (channel IN ('email', 'sms', 'paid_search', 'paid_social', 'affiliate')),
    budget_cents INTEGER NOT NULL CHECK (budget_cents >= 0),
    started_at TEXT NOT NULL,
    ended_at TEXT,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

CREATE TABLE IF NOT EXISTS carts (
    cart_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    customer_id INTEGER,
    cart_status TEXT NOT NULL CHECK (cart_status IN ('active', 'converted', 'abandoned')),
    source_channel TEXT NOT NULL CHECK (source_channel IN ('online_store', 'pos', 'marketplace', 'social')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    converted_order_id INTEGER,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (converted_order_id) REFERENCES orders(order_id)
);

CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id INTEGER PRIMARY KEY,
    cart_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    added_at TEXT NOT NULL,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

CREATE TABLE IF NOT EXISTS customer_events (
    customer_event_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    customer_id INTEGER,
    session_id TEXT NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('page_view', 'product_view', 'collection_view', 'search', 'add_to_cart', 'remove_from_cart', 'checkout_started', 'checkout_completed', 'email_click')),
    product_id INTEGER,
    collection_id INTEGER,
    cart_id INTEGER,
    order_id INTEGER,
    campaign_id INTEGER,
    source_channel TEXT NOT NULL CHECK (source_channel IN ('direct', 'email', 'paid_search', 'paid_social', 'organic_search', 'marketplace', 'social')),
    device_type TEXT NOT NULL CHECK (device_type IN ('desktop', 'mobile', 'tablet')),
    occurred_at TEXT NOT NULL,
    metadata_json TEXT,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (collection_id) REFERENCES collections(collection_id),
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id)
);

CREATE TABLE IF NOT EXISTS product_reviews (
    product_review_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    customer_id INTEGER,
    order_id INTEGER,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_title TEXT NOT NULL,
    review_body TEXT,
    moderation_status TEXT NOT NULL CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
    is_verified_purchase INTEGER NOT NULL DEFAULT 0 CHECK (is_verified_purchase IN (0, 1)),
    created_at TEXT NOT NULL,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE IF NOT EXISTS support_tickets (
    ticket_id INTEGER PRIMARY KEY,
    merchant_id INTEGER NOT NULL,
    customer_id INTEGER,
    order_id INTEGER,
    assigned_staff_user_id INTEGER,
    ticket_status TEXT NOT NULL CHECK (ticket_status IN ('open', 'pending', 'resolved', 'closed')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    topic TEXT NOT NULL CHECK (topic IN ('shipping', 'return', 'billing', 'product_question', 'technical_issue')),
    opened_at TEXT NOT NULL,
    resolved_at TEXT,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (assigned_staff_user_id) REFERENCES staff_users(staff_user_id)
);

CREATE INDEX IF NOT EXISTS idx_customers_merchant_tier ON customers(merchant_id, customer_tier);
CREATE INDEX IF NOT EXISTS idx_products_merchant_status ON products(merchant_id, status);
CREATE INDEX IF NOT EXISTS idx_products_vendor ON products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_merchant_placed_at ON orders(merchant_id, placed_at);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_variant ON order_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location ON inventory_levels(location_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status_priority ON support_tickets(ticket_status, priority);
CREATE INDEX IF NOT EXISTS idx_carts_status_updated_at ON carts(cart_status, updated_at);
CREATE INDEX IF NOT EXISTS idx_customer_events_session ON customer_events(session_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_customer_events_customer ON customer_events(customer_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_product_reviews_product ON product_reviews(product_id, rating);
CREATE INDEX IF NOT EXISTS idx_shipments_status ON shipments(shipment_status, estimated_delivery_at);
CREATE INDEX IF NOT EXISTS idx_shipment_events_shipment ON shipment_events(shipment_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(merchant_id, subscription_status);

CREATE VIEW IF NOT EXISTS order_profit_summary AS
SELECT
    o.order_id,
    o.merchant_id,
    o.order_number,
    o.placed_at,
    o.total_cents,
    SUM((oi.unit_price_cents - pv.cost_cents) * oi.quantity - oi.discount_cents) AS gross_profit_cents
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
JOIN product_variants AS pv ON pv.variant_id = oi.variant_id
GROUP BY o.order_id;
