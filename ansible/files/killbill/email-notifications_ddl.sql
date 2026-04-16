/*
 * Copyright 2010-2014 Ning, Inc.
 * Copyright 2014-2020 Groupon, Inc
 * Copyright 2020-2020 Equinix, Inc
 * Copyright 2014-2020 The Billing Project, LLC
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

DROP table If exists email_notifications_configuration;
CREATE TABLE email_notifications_configuration (
  record_id serial unique,
  kb_account_id varchar(255) NOT NULL,
  kb_tenant_id varchar(255) NOT NULL,
  event_type varchar(255) NOT NULL,
  created_at datetime NOT NULL,
  PRIMARY KEY (record_id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE UNIQUE INDEX email_notifications_configuration_event_type_kb_account_id ON email_notifications_configuration(event_type, kb_account_id);
CREATE INDEX email_notifications_configuration_kb_account_id ON email_notifications_configuration(kb_account_id);
CREATE INDEX email_notifications_configuration_kb_tenant_id ON email_notifications_configuration(kb_tenant_id);
CREATE INDEX email_notifications_configuration_event_type_kb_tenant_id ON email_notifications_configuration(event_type, kb_tenant_id);