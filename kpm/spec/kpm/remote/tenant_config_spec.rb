require 'spec_helper'

describe KPM::TenantConfig do
  include_context 'connection_setup'

  let(:value) {"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<catalog>\n    <effectiveDate>2017-04-25T15:57:43Z</effectiveDate>\n    <catalogName>DEFAULT</catalogName>\n    <recurringBillingMode>IN_ADVANCE</recurringBillingMode>\n    <currencies/>\n    <units/>\n    <products/>\n    <rules>\n        <changePolicy>\n            <changePolicyCase>\n                <policy>IMMEDIATE</policy>\n            </changePolicyCase>\n        </changePolicy>\n        <changeAlignment>\n            <changeAlignmentCase>\n                <alignment>START_OF_BUNDLE</alignment>\n            </changeAlignmentCase>\n        </changeAlignment>\n        <cancelPolicy>\n            <cancelPolicyCase>\n                <policy>IMMEDIATE</policy>\n            </cancelPolicyCase>\n        </cancelPolicy>\n        <createAlignment>\n            <createAlignmentCase>\n                <alignment>START_OF_BUNDLE</alignment>\n            </createAlignmentCase>\n        </createAlignment>\n        <billingAlignment>\n            <billingAlignmentCase>\n                <alignment>ACCOUNT</alignment>\n            </billingAlignmentCase>\n        </billingAlignment>\n        <priceList>\n            <priceListCase>\n                <toPriceList>DEFAULT</toPriceList>\n            </priceListCase>\n        </priceList>\n    </rules>\n    <plans/>\n    <priceLists>\n        <defaultPriceList name=\"DEFAULT\">\n            <plans/>\n        </defaultPriceList>\n    </priceLists>\n</catalog>\n"}
  let(:key) {'CATALOG_RSPEC'}

  let(:user) {'KPM Tenant Spec'}
  let(:tenant_config_class) { described_class.new([killbill_api_key,killbill_api_secrets],
                                                  [killbill_user, killbill_password],url,logger)}
  let(:options){{
        :username => killbill_user,
        :password => killbill_password,
        :api_key => killbill_api_key,
        :api_secret => killbill_api_secrets
      }}
                                             
  describe '#initialize' do
    context 'when creating an instance of tenant config class' do
      it 'when initialized with defaults' do
        expect(described_class.new).to be_an_instance_of(KPM::TenantConfig)
      end

      it 'when initialized with options' do
        tenant_config_class.should be_an_instance_of(KPM::TenantConfig)
        expect(tenant_config_class.instance_variable_get(:@killbill_api_key)).to eq(killbill_api_key)
        expect(tenant_config_class.instance_variable_get(:@killbill_api_secrets)).to eq(killbill_api_secrets)
        expect(tenant_config_class.instance_variable_get(:@killbill_user)).to eq(killbill_user)
        expect(tenant_config_class.instance_variable_get(:@killbill_password)).to eq(killbill_password)
        expect(tenant_config_class.instance_variable_get(:@killbill_url)).to eq(url)
      end
    end
  end                                           
  
  describe '#export' do
    it 'when retrieving tenant configuration' do
      KillBillClient.url = url

      #Add a new tenant config
      tenant_config = KillBillClient::Model::Tenant.upload_tenant_user_key_value(key, value, user, nil, nil, options)
      expect(tenant_config.key).to eq(key)
      
      #get created tenant config
      export_file = tenant_config_class.export(key)
      expect(File.exist?(export_file)).to be_true
      expect(File.readlines(export_file).grep(/#{key}/)).to be_true
      
      #remove created tenant config
      KillBillClient::Model::Tenant.delete_tenant_user_key_value(key, user, nil, nil, options)
      
    end
  end
end