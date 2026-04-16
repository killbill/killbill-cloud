/*! SET default_storage_engine=INNODB */;

-- Subscription events
drop table if exists analytics_subscription_transitions;
create table analytics_subscription_transitions (
  record_id serial unique
, subscription_event_record_id bigint /*! unsigned */ default null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, subscription_id varchar(36) default null
, requested_timestamp date default null
, event varchar(50) default null
, prev_product_name varchar(255) default null
, prev_product_type varchar(50) default null
, prev_product_category varchar(50) default null
, prev_slug varchar(255) default null
, prev_phase varchar(255) default null
, prev_billing_period varchar(50) default null
, prev_price numeric(10, 4) default 0
, converted_prev_price numeric(10, 4) default null
, prev_price_list varchar(50) default null
, prev_mrr numeric(10, 4) default 0
, converted_prev_mrr numeric(10, 4) default null
, prev_currency varchar(50) default null
, prev_service varchar(50) default null
, prev_state varchar(50) default null
, prev_business_active bool default true
, prev_start_date date default null
, next_product_name varchar(255) default null
, next_product_type varchar(50) default null
, next_product_category varchar(50) default null
, next_slug varchar(255) default null
, next_phase varchar(255) default null
, next_billing_period varchar(50) default null
, next_price numeric(10, 4) default 0
, converted_next_price numeric(10, 4) default null
, next_price_list varchar(50) default null
, next_mrr numeric(10, 4) default 0
, converted_next_mrr numeric(10, 4) default null
, next_currency varchar(50) default null
, next_service varchar(50) default null
, next_state varchar(50) default null
, next_business_active bool default true
, next_start_date date default null
, next_end_date date default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_subscription_transitions_bundle_id on analytics_subscription_transitions(bundle_id);
create index analytics_subscription_transitions_bundle_external_key on analytics_subscription_transitions(bundle_external_key);
create index analytics_subscription_transitions_account_id on analytics_subscription_transitions(account_id);
create index analytics_subscription_transitions_account_record_id on analytics_subscription_transitions(account_record_id);
create index analytics_subscription_transitions_tenant_account_record_id on analytics_subscription_transitions(tenant_record_id, account_record_id);

-- Bundle summary
drop table if exists analytics_bundles;
create table analytics_bundles (
  record_id serial unique
, bundle_record_id bigint /*! unsigned */ default null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, subscription_id varchar(36) default null
, bundle_account_rank int default null
, latest_for_bundle_external_key bool default false
, charged_through_date date default null
, current_product_name varchar(255) default null
, current_product_type varchar(50) default null
, current_product_category varchar(50) default null
, current_slug varchar(255) default null
, current_phase varchar(255) default null
, current_billing_period varchar(50) default null
, current_price numeric(10, 4) default 0
, converted_current_price numeric(10, 4) default null
, current_price_list varchar(50) default null
, current_mrr numeric(10, 4) default 0
, converted_current_mrr numeric(10, 4) default null
, current_currency varchar(50) default null
, current_service varchar(50) default null
, current_state varchar(50) default null
, current_business_active bool default true
, current_start_date date default null
, current_end_date date default null
, converted_currency varchar(3) default null
, original_created_date datetime default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_bundles_bundle_bundle_id on analytics_bundles(bundle_id);
create index analytics_bundles_bundle_external_key on analytics_bundles(bundle_external_key);
create index analytics_bundles_account_id on analytics_bundles(account_id);
create index analytics_bundles_account_record_id on analytics_bundles(account_record_id);
create index analytics_bundles_tenant_account_record_id on analytics_bundles(tenant_record_id, account_record_id);

-- Accounts
drop table if exists analytics_accounts;
create table analytics_accounts (
  record_id serial unique
, email varchar(128) default null
, first_name_length int default null
, currency varchar(3) default null
, billing_cycle_day_local int default null
, payment_method_id varchar(36) default null
, time_zone varchar(50) default null
, locale varchar(5) default null
, address1 varchar(100) default null
, address2 varchar(100) default null
, company_name varchar(50) default null
, city varchar(50) default null
, state_or_province varchar(50) default null
, country varchar(50) default null
, postal_code varchar(16) default null
, phone varchar(25) default null
, migrated bool default false
, balance numeric(10, 4) default 0
, converted_balance numeric(10, 4) default null
, oldest_unpaid_invoice_date date default null
, oldest_unpaid_invoice_balance numeric(10, 4) default null
, oldest_unpaid_invoice_currency varchar(3) default null
, converted_oldest_unpaid_invoice_balance numeric(10, 4) default null
, oldest_unpaid_invoice_id varchar(36) default null
, last_invoice_date date default null
, last_invoice_balance numeric(10, 4) default null
, last_invoice_currency varchar(3) default null
, converted_last_invoice_balance numeric(10, 4) default null
, last_invoice_id varchar(36) default null
, last_payment_date datetime default null
, last_payment_status varchar(255) default null
, nb_active_bundles int default 0
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, updated_date datetime default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, parent_account_id varchar(36) default null
, parent_account_name varchar(100) default null
, parent_account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_accounts_account_external_key on analytics_accounts(account_external_key);
create index analytics_accounts_account_id on analytics_accounts(account_id);
create index analytics_accounts_account_record_id on analytics_accounts(account_record_id);
create index analytics_accounts_tenant_account_record_id on analytics_accounts(tenant_record_id, account_record_id);
create index analytics_accounts_created_date_tenant_record_id_report_group on analytics_accounts(created_date, tenant_record_id, report_group);

drop table if exists analytics_account_transitions;
create table analytics_account_transitions (
  record_id serial unique
, blocking_state_record_id bigint /*! unsigned */ default null
, service varchar(50) default null
, state varchar(50) default null
, start_date date default null
, end_date date default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_account_transitions_account_id on analytics_account_transitions(account_id);
create index analytics_account_transitions_account_record_id on analytics_account_transitions(account_record_id);
create index analytics_account_transitions_tenant_account_record_id on analytics_account_transitions(tenant_record_id, account_record_id);
-- For sanity queries
create index analytics_account_transitions_blocking_state_record_id on analytics_account_transitions(blocking_state_record_id);

-- Invoices
drop table if exists analytics_invoices;
create table analytics_invoices (
  record_id serial unique
, invoice_record_id bigint /*! unsigned */ default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_date date default null
, target_date date default null
, currency varchar(50) default null
, raw_balance numeric(10, 4) default 0
, converted_raw_balance numeric(10, 4) default null
, balance numeric(10, 4) default 0
, converted_balance numeric(10, 4) default null
, amount_paid numeric(10, 4) default 0
, converted_amount_paid numeric(10, 4) default null
, amount_charged numeric(10, 4) default 0
, converted_amount_charged numeric(10, 4) default null
, original_amount_charged numeric(10, 4) default 0
, converted_original_amount_charged numeric(10, 4) default null
, amount_credited numeric(10, 4) default 0
, converted_amount_credited numeric(10, 4) default null
, amount_refunded numeric(10, 4) default 0
, converted_amount_refunded numeric(10, 4) default null
, converted_currency varchar(3) default null
, written_off bool default false
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoices_invoice_record_id on analytics_invoices(invoice_record_id);
create index analytics_invoices_invoice_id on analytics_invoices(invoice_id);
create index analytics_invoices_account_id on analytics_invoices(account_id);
create index analytics_invoices_account_record_id on analytics_invoices(account_record_id);
create index analytics_invoices_tenant_account_record_id on analytics_invoices(tenant_record_id, account_record_id);

-- Invoice adjustments (type REFUND_ADJ)
drop table if exists analytics_invoice_adjustments;
create table analytics_invoice_adjustments (
  record_id serial unique
, invoice_item_record_id bigint /*! unsigned */ default null
, second_invoice_item_record_id bigint /*! unsigned */ default null
, item_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, raw_invoice_balance numeric(10, 4) default 0
, converted_raw_invoice_balance numeric(10, 4) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_written_off bool default false
, item_type varchar(50) default null
, item_source varchar(50) not null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, product_name varchar(255) default null
, product_type varchar(50) default null
, product_category varchar(50) default null
, slug varchar(255) default null
, phase varchar(255) default null
, billing_period varchar(50) default null
, start_date date default null
, end_date date default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, linked_item_id varchar(36) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_adjustments_invoice_item_record_id on analytics_invoice_adjustments(invoice_item_record_id);
create index analytics_invoice_adjustments_item_id on analytics_invoice_adjustments(item_id);
create index analytics_invoice_adjustments_invoice_id on analytics_invoice_adjustments(invoice_id);
create index analytics_invoice_adjustments_account_id on analytics_invoice_adjustments(account_id);
create index analytics_invoice_adjustments_account_record_id on analytics_invoice_adjustments(account_record_id);
create index analytics_invoice_adjustments_tenant_account_record_id on analytics_invoice_adjustments(tenant_record_id, account_record_id);

-- Invoice items (without adjustments, type EXTERNAL_CHARGE, FIXED, RECURRING, USAGE and TAX)
drop table if exists analytics_invoice_items;
create table analytics_invoice_items (
  record_id serial unique
, invoice_item_record_id bigint /*! unsigned */ default null
, second_invoice_item_record_id bigint /*! unsigned */ default null
, item_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, raw_invoice_balance numeric(10, 4) default 0
, converted_raw_invoice_balance numeric(10, 4) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_written_off bool default false
, item_type varchar(50) default null
, item_source varchar(50) not null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, product_name varchar(255) default null
, product_type varchar(50) default null
, product_category varchar(50) default null
, slug varchar(255) default null
, usage_name varchar(255) default null
, phase varchar(255) default null
, billing_period varchar(50) default null
, start_date date default null
, end_date date default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, linked_item_id varchar(36) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_items_invoice_item_record_id on analytics_invoice_items(invoice_item_record_id);
create index analytics_invoice_items_item_id on analytics_invoice_items(item_id);
create index analytics_invoice_items_invoice_id on analytics_invoice_items(invoice_id);
create index analytics_invoice_items_account_id on analytics_invoice_items(account_id);
create index analytics_invoice_items_account_record_id on analytics_invoice_items(account_record_id);
create index analytics_invoice_items_tenant_account_record_id on analytics_invoice_items(tenant_record_id, account_record_id);

-- Invoice items adjustments (type ITEM_ADJ)
drop table if exists analytics_invoice_item_adjustments;
create table analytics_invoice_item_adjustments (
  record_id serial unique
, invoice_item_record_id bigint /*! unsigned */ default null
, second_invoice_item_record_id bigint /*! unsigned */ default null
, item_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, raw_invoice_balance numeric(10, 4) default 0
, converted_raw_invoice_balance numeric(10, 4) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_written_off bool default false
, item_type varchar(50) default null
, item_source varchar(50) not null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, product_name varchar(255) default null
, product_type varchar(50) default null
, product_category varchar(50) default null
, slug varchar(255) default null
, phase varchar(255) default null
, billing_period varchar(50) default null
, start_date date default null
, end_date date default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, linked_item_id varchar(36) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_item_adjustments_invoice_item_record_id on analytics_invoice_item_adjustments(invoice_item_record_id);
create index analytics_invoice_item_adjustments_item_id on analytics_invoice_item_adjustments(item_id);
create index analytics_invoice_item_adjustments_invoice_id on analytics_invoice_item_adjustments(invoice_id);
create index analytics_invoice_item_adjustments_account_id on analytics_invoice_item_adjustments(account_id);
create index analytics_invoice_item_adjustments_account_record_id on analytics_invoice_item_adjustments(account_record_id);
create index analytics_invoice_item_adjustments_tenant_account_record_id on analytics_invoice_item_adjustments(tenant_record_id, account_record_id);

-- Account credits (type CBA_ADJ and CREDIT_ADJ)
drop table if exists analytics_invoice_credits;
create table analytics_invoice_credits (
  record_id serial unique
, invoice_item_record_id bigint /*! unsigned */ default null
, second_invoice_item_record_id bigint /*! unsigned */ default null
, item_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, raw_invoice_balance numeric(10, 4) default 0
, converted_raw_invoice_balance numeric(10, 4) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_written_off bool default false
, item_type varchar(50) default null
, item_source varchar(50) not null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, product_name varchar(255) default null
, product_type varchar(50) default null
, product_category varchar(50) default null
, slug varchar(255) default null
, phase varchar(255) default null
, billing_period varchar(50) default null
, start_date date default null
, end_date date default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, linked_item_id varchar(36) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_credits_invoice_item_record_id on analytics_invoice_credits(invoice_item_record_id);
create index analytics_invoice_credits_item_id on analytics_invoice_credits(item_id);
create index analytics_invoice_credits_invoice_id on analytics_invoice_credits(invoice_id);
create index analytics_invoice_credits_account_id on analytics_invoice_credits(account_id);
create index analytics_invoice_credits_account_record_id on analytics_invoice_credits(account_record_id);
create index analytics_invoice_credits_tenant_account_record_id on analytics_invoice_credits(tenant_record_id, account_record_id);

-- Payments

drop table if exists analytics_payment_auths;
create table analytics_payment_auths (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_auths_created_date on analytics_payment_auths(created_date);
create index analytics_payment_auths_date_trid_plugin_name on analytics_payment_auths(created_date, tenant_record_id, plugin_name);
create index analytics_payment_auths_invoice_payment_record_id on analytics_payment_auths(invoice_payment_record_id);
create index analytics_payment_auths_invoice_payment_id on analytics_payment_auths(invoice_payment_id);
create index analytics_payment_auths_invoice_id on analytics_payment_auths(invoice_id);
create index analytics_payment_auths_account_id on analytics_payment_auths(account_id);
create index analytics_payment_auths_account_record_id on analytics_payment_auths(account_record_id);
create index analytics_payment_auths_tenant_account_record_id on analytics_payment_auths(tenant_record_id, account_record_id);
create index analytics_payment_auths_cdate_trid_crcy_status_rgroup_camount on analytics_payment_auths(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_auths_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_auths(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

drop table if exists analytics_payment_captures;
create table analytics_payment_captures (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_captures_created_date on analytics_payment_captures(created_date);
create index analytics_payment_captures_date_trid_plugin_name on analytics_payment_captures(created_date, tenant_record_id, plugin_name);
create index analytics_payment_captures_invoice_payment_record_id on analytics_payment_captures(invoice_payment_record_id);
create index analytics_payment_captures_invoice_payment_id on analytics_payment_captures(invoice_payment_id);
create index analytics_payment_captures_invoice_id on analytics_payment_captures(invoice_id);
create index analytics_payment_captures_account_id on analytics_payment_captures(account_id);
create index analytics_payment_captures_account_record_id on analytics_payment_captures(account_record_id);
create index analytics_payment_captures_tenant_account_record_id on analytics_payment_captures(tenant_record_id, account_record_id);
create index analytics_payment_captures_cdate_trid_crcy_status_rgroup_camount on analytics_payment_captures(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_captures_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_captures(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

drop table if exists analytics_payment_purchases;
create table analytics_payment_purchases (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_purchases_created_date on analytics_payment_purchases(created_date);
create index analytics_payment_purchases_date_trid_plugin_name on analytics_payment_purchases(created_date, tenant_record_id, plugin_name);
create index analytics_payment_purchases_invoice_payment_record_id on analytics_payment_purchases(invoice_payment_record_id);
create index analytics_payment_purchases_invoice_payment_id on analytics_payment_purchases(invoice_payment_id);
create index analytics_payment_purchases_invoice_id on analytics_payment_purchases(invoice_id);
create index analytics_payment_purchases_account_id on analytics_payment_purchases(account_id);
create index analytics_payment_purchases_account_record_id on analytics_payment_purchases(account_record_id);
create index analytics_payment_purchases_tenant_account_record_id on analytics_payment_purchases(tenant_record_id, account_record_id);
create index analytics_payment_prchses_cdate_trid_crcy_status_rgroup_camount on analytics_payment_purchases(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_prchses_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_purchases(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

drop table if exists analytics_payment_refunds;
create table analytics_payment_refunds (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_refunds_created_date on analytics_payment_refunds(created_date);
create index analytics_payment_refunds_date_trid_plugin_name on analytics_payment_refunds(created_date, tenant_record_id, plugin_name);
create index analytics_payment_refunds_invoice_payment_record_id on analytics_payment_refunds(invoice_payment_record_id);
create index analytics_payment_refunds_invoice_payment_id on analytics_payment_refunds(invoice_payment_id);
create index analytics_payment_refunds_invoice_id on analytics_payment_refunds(invoice_id);
create index analytics_payment_refunds_account_id on analytics_payment_refunds(account_id);
create index analytics_payment_refunds_account_record_id on analytics_payment_refunds(account_record_id);
create index analytics_payment_refunds_tenant_account_record_id on analytics_payment_refunds(tenant_record_id, account_record_id);
create index analytics_payment_refunds_cdate_trid_crcy_status_rgroup_camount on analytics_payment_refunds(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_refunds_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_refunds(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

drop table if exists analytics_payment_credits;
create table analytics_payment_credits (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_credits_created_date on analytics_payment_credits(created_date);
create index analytics_payment_credits_date_trid_plugin_name on analytics_payment_credits(created_date, tenant_record_id, plugin_name);
create index analytics_payment_credits_invoice_payment_record_id on analytics_payment_credits(invoice_payment_record_id);
create index analytics_payment_credits_invoice_payment_id on analytics_payment_credits(invoice_payment_id);
create index analytics_payment_credits_invoice_id on analytics_payment_credits(invoice_id);
create index analytics_payment_credits_account_id on analytics_payment_credits(account_id);
create index analytics_payment_credits_account_record_id on analytics_payment_credits(account_record_id);
create index analytics_payment_credits_tenant_account_record_id on analytics_payment_credits(tenant_record_id, account_record_id);
create index analytics_payment_credits_cdate_trid_crcy_status_rgroup_camount on analytics_payment_credits(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_credits_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_credits(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

drop table if exists analytics_payment_chargebacks;
create table analytics_payment_chargebacks (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_chargebacks_created_date on analytics_payment_chargebacks(created_date);
create index analytics_payment_chargebacks_date_trid_plugin_name on analytics_payment_chargebacks(created_date, tenant_record_id, plugin_name);
create index analytics_payment_chargebacks_invoice_payment_record_id on analytics_payment_chargebacks(invoice_payment_record_id);
create index analytics_payment_chargebacks_invoice_payment_id on analytics_payment_chargebacks(invoice_payment_id);
create index analytics_payment_chargebacks_invoice_id on analytics_payment_chargebacks(invoice_id);
create index analytics_payment_chargebacks_account_id on analytics_payment_chargebacks(account_id);
create index analytics_payment_chargebacks_account_record_id on analytics_payment_chargebacks(account_record_id);
create index analytics_payment_chargebacks_tenant_account_record_id on analytics_payment_chargebacks(tenant_record_id, account_record_id);
create index analytics_payment_cbacks_cdate_trid_crcy_status_rgroup_camount on analytics_payment_chargebacks(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_cbacks_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_chargebacks(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

drop table if exists analytics_payment_voids;
create table analytics_payment_voids (
  record_id serial unique
, invoice_payment_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, invoice_id varchar(36) default null
, invoice_number bigint default null
, invoice_created_date datetime default null
, invoice_date date default null
, invoice_target_date date default null
, invoice_currency varchar(50) default null
, invoice_balance numeric(10, 4) default 0
, converted_invoice_balance numeric(10, 4) default null
, invoice_amount_paid numeric(10, 4) default 0
, converted_invoice_amount_paid numeric(10, 4) default null
, invoice_amount_charged numeric(10, 4) default 0
, converted_invoice_amount_charged numeric(10, 4) default null
, invoice_original_amount_charged numeric(10, 4) default 0
, converted_invoice_original_amount_charged numeric(10, 4) default null
, invoice_amount_credited numeric(10, 4) default 0
, converted_invoice_amount_credited numeric(10, 4) default null
, invoice_amount_refunded numeric(10, 4) default 0
, converted_invoice_amount_refunded numeric(10, 4) default null
, invoice_payment_type varchar(50) default null
, payment_id varchar(36) default null
, refund_id varchar(36) default null
, payment_number bigint default null
, payment_external_key varchar(255) default null
, payment_transaction_id varchar(36) default null
, payment_transaction_external_key varchar(255) default null
, payment_transaction_status varchar(255) default null
, linked_invoice_payment_id varchar(36) default null
, amount numeric(10, 4) default 0
, converted_amount numeric(10, 4) default null
, currency varchar(50) default null
, plugin_name varchar(255) default null
, payment_method_id varchar(36) default null
, payment_method_external_key varchar(255) default null
, plugin_created_date datetime default null
, plugin_effective_date datetime default null
, plugin_status varchar(255) default null
, plugin_gateway_error text default null
, plugin_gateway_error_code varchar(255) default null
, plugin_first_reference_id varchar(255) default null
, plugin_second_reference_id varchar(255) default null
, plugin_property_1 varchar(255) default null
, plugin_property_2 varchar(255) default null
, plugin_property_3 varchar(255) default null
, plugin_property_4 varchar(255) default null
, plugin_property_5 varchar(255) default null
, plugin_pm_id varchar(255) default null
, plugin_pm_is_default bool default null
, plugin_pm_type varchar(255) default null
, plugin_pm_cc_name varchar(255) default null
, plugin_pm_cc_type varchar(255) default null
, plugin_pm_cc_expiration_month varchar(255) default null
, plugin_pm_cc_expiration_year varchar(255) default null
, plugin_pm_cc_last_4 varchar(255) default null
, plugin_pm_address1 varchar(255) default null
, plugin_pm_address2 varchar(255) default null
, plugin_pm_city varchar(255) default null
, plugin_pm_state varchar(255) default null
, plugin_pm_zip varchar(255) default null
, plugin_pm_country varchar(255) default null
, converted_currency varchar(3) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_voids_created_date on analytics_payment_voids(created_date);
create index analytics_payment_voids_date_trid_plugin_name on analytics_payment_voids(created_date, tenant_record_id, plugin_name);
create index analytics_payment_voids_invoice_payment_record_id on analytics_payment_voids(invoice_payment_record_id);
create index analytics_payment_voids_invoice_payment_id on analytics_payment_voids(invoice_payment_id);
create index analytics_payment_voids_invoice_id on analytics_payment_voids(invoice_id);
create index analytics_payment_voids_account_id on analytics_payment_voids(account_id);
create index analytics_payment_voids_account_record_id on analytics_payment_voids(account_record_id);
create index analytics_payment_voids_tenant_account_record_id on analytics_payment_voids(tenant_record_id, account_record_id);
create index analytics_payment_voids_cdate_trid_crcy_status_rgroup_camount on analytics_payment_voids(created_date, tenant_record_id, currency, payment_transaction_status, report_group, converted_amount);
create index ap_voids_cdate_trid_crcy_status_rgroup_camount_pname_perror on analytics_payment_voids(created_date, tenant_record_id, currency, payment_transaction_status, report_group, plugin_name /*! , plugin_gateway_error(80) */);

-- Tags

drop table if exists analytics_account_tags;
create table analytics_account_tags (
  record_id serial unique
, tag_record_id bigint /*! unsigned */ default null
, name varchar(50) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_account_tags_account_id on analytics_account_tags(account_id);
create index analytics_account_tags_account_record_id on analytics_account_tags(account_record_id);
create index analytics_account_tags_tenant_account_record_id on analytics_account_tags(tenant_record_id, account_record_id);

drop table if exists analytics_bundle_tags;
create table analytics_bundle_tags (
  record_id serial unique
, tag_record_id bigint /*! unsigned */ default null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, name varchar(50) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_bundle_tags_account_id on analytics_bundle_tags(account_id);
create index analytics_bundle_tags_bundle_id on analytics_bundle_tags(bundle_id);
create index analytics_bundle_tags_bundle_external_key on analytics_bundle_tags(bundle_external_key);
create index analytics_bundle_tags_account_record_id on analytics_bundle_tags(account_record_id);
create index analytics_bundle_tags_tenant_account_record_id on analytics_bundle_tags(tenant_record_id, account_record_id);

drop table if exists analytics_invoice_tags;
create table analytics_invoice_tags (
  record_id serial unique
, tag_record_id bigint /*! unsigned */ default null
, invoice_id varchar(36) default null
, name varchar(50) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_tags_account_id on analytics_invoice_tags(account_id);
create index analytics_invoice_tags_account_record_id on analytics_invoice_tags(account_record_id);
create index analytics_invoice_tags_tenant_account_record_id on analytics_invoice_tags(tenant_record_id, account_record_id);

drop table if exists analytics_payment_tags;
create table analytics_payment_tags (
  record_id serial unique
, tag_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, name varchar(50) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_tags_account_id on analytics_payment_tags(account_id);
create index analytics_payment_tags_account_record_id on analytics_payment_tags(account_record_id);
create index analytics_payment_tags_tenant_account_record_id on analytics_payment_tags(tenant_record_id, account_record_id);

drop table if exists analytics_account_fields;
create table analytics_account_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_account_fields_account_id on analytics_account_fields(account_id);
create index analytics_account_fields_account_record_id on analytics_account_fields(account_record_id);
create index analytics_account_fields_tenant_account_record_id on analytics_account_fields(tenant_record_id, account_record_id);

drop table if exists analytics_bundle_fields;
create table analytics_bundle_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, bundle_id varchar(36) default null
, bundle_external_key varchar(255) default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_bundle_fields_account_id on analytics_bundle_fields(account_id);
create index analytics_bundle_fields_bundle_id on analytics_bundle_fields(bundle_id);
create index analytics_bundle_fields_bundle_external_key on analytics_bundle_fields(bundle_external_key);
create index analytics_bundle_fields_account_record_id on analytics_bundle_fields(account_record_id);
create index analytics_bundle_fields_tenant_account_record_id on analytics_bundle_fields(tenant_record_id, account_record_id);

drop table if exists analytics_invoice_fields;
create table analytics_invoice_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, invoice_id varchar(36) default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_fields_account_id on analytics_invoice_fields(account_id);
create index analytics_invoice_fields_account_record_id on analytics_invoice_fields(account_record_id);
create index analytics_invoice_fields_tenant_account_record_id on analytics_invoice_fields(tenant_record_id, account_record_id);

drop table if exists analytics_invoice_payment_fields;
create table analytics_invoice_payment_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, invoice_payment_id varchar(36) default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_invoice_payment_fields_account_id on analytics_invoice_payment_fields(account_id);
create index analytics_invoice_payment_fields_account_record_id on analytics_invoice_payment_fields(account_record_id);
create index analytics_invoice_payment_fields_tenant_account_record_id on analytics_invoice_payment_fields(tenant_record_id, account_record_id);

drop table if exists analytics_payment_fields;
create table analytics_payment_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, payment_id varchar(36) default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_fields_account_id on analytics_payment_fields(account_id);
create index analytics_payment_fields_account_record_id on analytics_payment_fields(account_record_id);
create index analytics_payment_fields_tenant_account_record_id on analytics_payment_fields(tenant_record_id, account_record_id);

drop table if exists analytics_payment_method_fields;
create table analytics_payment_method_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, payment_method_id varchar(36) default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_payment_method_fields_account_id on analytics_payment_method_fields(account_id);
create index analytics_payment_method_fields_account_record_id on analytics_payment_method_fields(account_record_id);
create index analytics_payment_method_fields_tenant_account_record_id on analytics_payment_method_fields(tenant_record_id, account_record_id);

drop table if exists analytics_transaction_fields;
create table analytics_transaction_fields (
  record_id serial unique
, custom_field_record_id bigint /*! unsigned */ default null
, transaction_id varchar(36) default null
, name varchar(64) default null
, field_value varchar(255) default null
, created_date datetime default null
, created_by varchar(50) default null
, created_reason_code varchar(255) default null
, created_comments varchar(255) default null
, account_id varchar(36) default null
, account_name varchar(100) default null
, account_external_key varchar(255) default null
, account_record_id bigint /*! unsigned */ default null
, tenant_record_id bigint /*! unsigned */ default null
, report_group varchar(50) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_transaction_fields_account_id on analytics_transaction_fields(account_id);
create index analytics_transaction_fields_account_record_id on analytics_transaction_fields(account_record_id);
create index analytics_transaction_fields_tenant_account_record_id on analytics_transaction_fields(tenant_record_id, account_record_id);

drop table if exists analytics_notifications;
create table analytics_notifications (
  record_id serial unique
, class_name varchar(256) not null
, event_json varchar(2048) not null
, user_token varchar(36)
, created_date datetime not null
, creating_owner varchar(50) not null
, processing_owner varchar(50) default null
, processing_available_date datetime default null
, processing_state varchar(14) default 'AVAILABLE'
, error_count int /*! unsigned */ DEFAULT 0
, search_key1 int /*! unsigned */ default null
, search_key2 int /*! unsigned */ default null
, queue_name varchar(64) not null
, effective_date datetime not null
, future_user_token varchar(36)
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_notifications_comp_where on analytics_notifications(effective_date, processing_state, processing_owner, processing_available_date);
create index analytics_notifications_update on analytics_notifications(processing_state,processing_owner,processing_available_date);
create index analytics_notifications_get_ready on analytics_notifications(effective_date,created_date);
create index analytics_notifications_search_keys on analytics_notifications(search_key2, search_key1);

drop table if exists analytics_notifications_history;
create table analytics_notifications_history (
  record_id serial unique
, class_name varchar(256) not null
, event_json varchar(2048) not null
, user_token varchar(36)
, created_date datetime not null
, creating_owner varchar(50) not null
, processing_owner varchar(50) default null
, processing_available_date datetime default null
, processing_state varchar(14) default 'AVAILABLE'
, error_count int /*! unsigned */ DEFAULT 0
, search_key1 int /*! unsigned */ default null
, search_key2 int /*! unsigned */ default null
, queue_name varchar(64) not null
, effective_date datetime not null
, future_user_token varchar(36)
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;

drop table if exists analytics_currency_conversion;
create table analytics_currency_conversion (
  record_id serial unique
, currency varchar(3) not null
, start_date date not null
, end_date date not null
, reference_rate decimal(10, 4) not null
, reference_currency varchar(3) default 'USD'
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index analytics_currency_conversion_dates_currencies on analytics_currency_conversion(start_date, end_date, currency, reference_currency);

drop table if exists analytics_reports;
create table analytics_reports (
  record_id serial unique
, report_name varchar(100) not null
, report_pretty_name varchar(256) default null
, report_type varchar(24) not null default 'TIMELINE'
, source_table_name varchar(256) default null
, source_name varchar(256) default null
, source_query varchar(4096) default null
, refresh_procedure_name varchar(256) default null
, refresh_frequency varchar(50) default null
, refresh_hour_of_day_gmt smallint default null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create unique index analytics_reports_report_name on analytics_reports(report_name);
