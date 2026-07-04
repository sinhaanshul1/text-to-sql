## 2026-06-27

- Added `scripts/split_training_corpus.py` to create deterministic train/validation/test splits while keeping paraphrase variants of the same SQL in the same split to reduce evaluation leakage.
- Added `data/train.jsonl`, `data/valid.jsonl`, and `data/test.jsonl` from the 1,500-example corpus for downstream fine-tuning and evaluation.
- Added `scripts/generate_training_corpus.py` to deterministically expand the text-to-SQL fine-tuning dataset from the hand-authored seed set to a larger schema-aware corpus.
- Regenerated `data/training_corpus.jsonl` to 1,500 validated examples using reusable template families and prompt rephrasings while retaining full schema coverage across all tables and views.
- Expanded `data/training_corpus.jsonl` from 64 to 100 examples, adding targeted coverage for every schema table/view plus more joins, aggregates, self-joins, inserts, and updates across categories, payments, fulfillment items, return items, cart items, addresses, campaigns, and collections.
- Added `scripts/audit_corpus_coverage.py` to report which schema tables and views are referenced by the fine-tuning corpus so dataset coverage can be checked before training.
- Added `data/training_corpus.jsonl` with 64 fine-tuning examples in chat JSONL format, covering realistic read and write requests across products, inventory, orders, subscriptions, returns, support, marketing, and fulfillment.
- Added `scripts/validate_corpus.py` to recreate the seeded SQLite database and execute every corpus example as a validation gate before model training.

## 2026-06-24

- Expanded the Shopify-style schema with vendors, collections, subscription tables, store credit tables, customer events, product reviews, shipments, and shipment events.
- Made seed data more robust by adding vendor relationships, merchandising collections, recurring subscriptions, shipment tracking histories, store credit balances, web behavior events, and product reviews across merchants.

## 2026-06-22

- Added a Shopify-style SQLite sample database initializer in `data/init_db.py`.
- Added `data/schema.sql` with a multi-tenant commerce schema covering merchants, staff, customers, products, variants, inventory, orders, payments, fulfillments, returns, carts, campaigns, and support tickets.
- Added `data/seed_data.sql` with realistic seed data across multiple merchants and operational scenarios for future text-to-SQL dataset generation.
