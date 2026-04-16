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

drop table if exists hyperswitch_payment_methods ;
create table hyperswitch_payment_methods (
  record_id serial
, kb_account_id char(36) not null
, kb_payment_method_id char(36) not null
, hyperswitch_id varchar(255) not null
, is_default smallint not null default 0
, is_deleted smallint not null default 0
, additional_data longtext default null
, created_date datetime not null
, updated_date datetime not null
, kb_tenant_id char(36) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create unique index hyperswitch_payment_methods_kb_payment_id on hyperswitch_payment_methods(kb_payment_method_id);
create index hyperswitch_payment_methods_hyperswitch_id on hyperswitch_payment_methods(hyperswitch_id);


drop table if exists hyperswitch_responses;
create table hyperswitch_responses (
  record_id serial
, kb_account_id char(36) not null
, kb_payment_id char(36) not null
, kb_payment_transaction_id char(36) not null
, transaction_type varchar(32) not null
, amount numeric(15,9)
, currency char(3)
, payment_attempt_id varchar(64) not null
, error_message varchar(64)
, error_code varchar(64)
, additional_data longtext default null
, created_date datetime not null
, kb_tenant_id char(36) not null
, primary key(record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
create index hyperswitch_responses_kb_payment_id on hyperswitch_responses(kb_payment_id);
create index hyperswitch_responses_kb_payment_transaction_id on hyperswitch_responses(kb_payment_transaction_id);
create index hyperswitch_responses_payment_attempt_id on hyperswitch_responses(payment_attempt_id);