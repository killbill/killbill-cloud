/*
 * Copyright 2020-2023 Equinix, Inc
 * Copyright 2014-2023 The Billing Project, LLC
 *
 * The Billing Project licenses this file to you under the Apache License, version 2.0
 * (the "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

/*! SET default_storage_engine=INNODB */;

drop table if exists adyen_hpp_requests;
create table adyen_hpp_requests (
  record_id serial
, kb_account_id char(36) not null
, kb_payment_id char(36) default null
, kb_payment_transaction_id char(36) default null
, transaction_external_key varchar(255) not null
, additional_data longtext default null
, created_date datetime not null
, kb_tenant_id char(36) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index adyen_hpp_requests_kb_account_id on adyen_hpp_requests(kb_account_id);
create index adyen_hpp_requests_kb_transaction_external_key on adyen_hpp_requests(transaction_external_key);
create index adyen_hpp_requests_kb_payment_transaction_id on adyen_hpp_requests(kb_payment_transaction_id);

drop table if exists adyen_responses;
create table adyen_responses (
  record_id serial
, kb_account_id char(36) not null
, kb_payment_id char(36) not null
, kb_payment_transaction_id char(36) not null
, transaction_type varchar(32) not null
, transaction_status varchar(32) not null
, amount numeric(15,9)
, currency char(3)
, session_id char(36) default null 
, psp_result varchar(64)
, psp_reference varchar(64)
, auth_code varchar(64)
, result_code varchar(64)
, refusal_reason varchar(64)
, reference varchar(64)
, psp_error_codes varchar(64)
, payment_internal_ref varchar(64)
, form_url varchar(1024)
, dcc_amount numeric(15,9)
, dcc_currency char(3)
, dcc_signature varchar(64)
, issuer_url varchar(1024)
, md text
, pa_request text
, additional_data longtext default null
, created_date datetime not null
, kb_tenant_id char(36) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index adyen_responses_kb_payment_id on adyen_responses(kb_payment_id);
create index adyen_responses_kb_payment_transaction_id on adyen_responses(kb_payment_transaction_id);
create index psp_reference_idx on adyen_responses(psp_reference);

drop table if exists adyen_notifications;
create table adyen_notifications (
  record_id serial
, kb_account_id char(36)
, kb_payment_id char(36)
, kb_payment_transaction_id char(36)
, transaction_type varchar(32)
, amount numeric(15,9)
, currency char(3)
, event_code varchar(64)
, event_date datetime
, merchant_account_code varchar(64)
, merchant_reference varchar(64)
, operations varchar(1024)
, original_reference varchar(64)
, payment_method varchar(64)
, psp_reference varchar(255)
, reason text
, success smallint not null default 0
, additional_data longtext default null
, created_date datetime not null
, kb_tenant_id char(36)
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
-- Not unique to handle retries
create index adyen_notifications_psp_reference on adyen_notifications(psp_reference);
create index adyen_notifications_kb_payment_id on adyen_notifications(kb_payment_id);
create index adyen_notifications_kb_payment_transaction_id on adyen_notifications(kb_payment_transaction_id);

drop table if exists adyen_payment_methods;
create table adyen_payment_methods (
  record_id serial
, kb_account_id char(36) not null
, kb_payment_method_id char(36) not null
, is_recurring smallint not null default 0
, is_default smallint not null default 0
, is_deleted smallint not null default 0
, recurring_detail_reference char(36) default null
, additional_data longtext default null
, created_date datetime not null
, updated_date datetime not null
, kb_tenant_id char(36) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create unique index adyen_payment_methods_kb_payment_id on adyen_payment_methods(kb_payment_method_id);