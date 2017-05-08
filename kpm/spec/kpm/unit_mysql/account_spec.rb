require 'spec_helper'

describe KPM::Account do
  
  shared_context 'account' do
    include_context 'connection_setup'

    let(:account_class) { described_class.new(nil,[killbill_api_key,killbill_api_secrets],
                                             [killbill_user, killbill_password],url,
                                             db_name, [db_username, db_password],nil,logger)}
    let(:dummy_account_id) {SecureRandom.uuid}
    let(:account_id_invalid) {SecureRandom.uuid}
    let(:dummy_data) {
      "-- accounts record_id|id|external_key|email|name|first_name_length|currency|billing_cycle_day_local|parent_account_id|is_payment_delegated_to_parent|payment_method_id|time_zone|locale|address1|address2|company_name|city|state_or_province|country|postal_code|phone|notes|migrated|is_notified_for_invoices|created_date|created_by|updated_date|updated_by|tenant_record_id\n"\
      "5|#{dummy_account_id}|#{dummy_account_id}|willharnet@example.com|Will Harnet||USD|0||||UTC||||||||||||false|2017-04-03T15:50:14.000+0000|demo|2017-04-05T15:01:39.000+0000|Killbill::Stripe::PaymentPlugin|2\n"\
      "-- account_history record_id|id|target_record_id|external_key|email|name|first_name_length|currency|billing_cycle_day_local|parent_account_id|payment_method_id|is_payment_delegated_to_parent|time_zone|locale|address1|address2|company_name|city|state_or_province|country|postal_code|phone|notes|migrated|is_notified_for_invoices|change_type|created_by|created_date|updated_by|updated_date|tenant_record_id\n"\
      "3|#{SecureRandom.uuid}|5|#{dummy_account_id}|willharnet@example.com|Will Harnet||USD|0||||UTC||||||||||||false|INSERT|demo|2017-04-03T15:50:14.000+0000|demo|2017-04-03T15:50:14.000+0000|2\n"
    }
    let(:cols_names) {dummy_data.split("\n")[0].split(" ")[2]}
    let(:cols_data) {dummy_data.split("\n")[1]}
    let(:table_name) {dummy_data.split("\n")[0].split(" ")[1]}
    let(:obfuscating_marker) {:email}
    let(:mysql_cli) {"mysql #{db_name} --user=#{db_username} --password=#{db_password} "}
    let(:test_ddl) {Dir["#{Dir.pwd}/**/account_test_ddl.sql"][0]}
  end

  describe '#initialize' do
    include_context 'account'  

    context 'when creating an instance of account class' do

      it 'when initialized with defaults' do
        expect(described_class.new).to be_an_instance_of(KPM::Account)
      end

      it 'when initialized with options' do
        account_class.should be_an_instance_of(KPM::Account)
        expect(account_class.instance_variable_get(:@killbill_api_key)).to eq(killbill_api_key)
        expect(account_class.instance_variable_get(:@killbill_api_secrets)).to eq(killbill_api_secrets)
        expect(account_class.instance_variable_get(:@killbill_user)).to eq(killbill_user)
        expect(account_class.instance_variable_get(:@killbill_password)).to eq(killbill_password)
        expect(account_class.instance_variable_get(:@killbill_url)).to eq(url)

      end

    end

  end

  # export data tests
  describe '#fetch_export_data' do
    include_context 'account'

    context 'when fetching account from api' do

      it 'when account id not found' do
        expect{ account_class.send(:fetch_export_data, account_id_invalid) }.to raise_error(Interrupt, 'Account id not found')
      end

      it 'when account id found' do
        account_id = creating_account_with_client
        expect(account_id).to match(/\w{8}(-\w{4}){3}-\w{12}?/)
        expect{ account_class.send(:fetch_export_data, account_id) }.not_to raise_error(Interrupt, 'Account id not found')
        expect(account_class.send(:fetch_export_data, account_id)).to match(account_id)
      end

    end

  end

  describe '#process_export_data' do
    include_context 'account'

    context 'when processing data to export' do

      it 'when column name qty eq column data qty' do
        expect(account_class.send(:process_export_data, cols_data, table_name, cols_names.split("|")).split("|").size).to eq(cols_names.split("|").size)
      end

      it 'when obfuscating data' do
        marker_index = 0
        cols_names.split("|").each do |col_name|
          if col_name.equal?(obfuscating_marker.to_s)
            break
          end
          marker_index += 1
        end

        obfuscating_marker_data = account_class.send(:process_export_data, cols_data, table_name, cols_names.split("|")).split("|")
        expect(obfuscating_marker_data[marker_index]).to be_nil
      end

    end

  end

  describe '#remove_export_data' do
    include_context 'account'

    it 'when obfuscating value' do
      expect(account_class.send(:remove_export_data, table_name, obfuscating_marker.to_s, 'willharnet@example.com')).to be_nil
    end

  end

  describe '#export' do
    include_context 'account'

    context 'when exporting data' do

      it 'when file created' do
        expect(File.exist?(account_class.send(:export, dummy_data))).to be_true
      end

      it 'when file contains account record' do
        expect(File.readlines(account_class.send(:export, dummy_data)).grep(/#{table_name}/)).to be_true
        expect(File.readlines(account_class.send(:export, dummy_data)).grep(/#{cols_names}/)).to be_true
      end

    end

  end

  describe '#export_data' do
    include_context 'account'

    context 'when exporting data; main method' do

      it 'when no account id' do
        expect{ account_class.export_data }.to raise_error(Interrupt, 'Account id not found')
      end

      it 'when file created' do
        account_id = creating_account_with_client
        expect(account_id).to match(/\w{8}(-\w{4}){3}-\w{12}?/)
        expect(File.exist?(account_class.export_data(account_id))).to be_true
      end

      it 'when file contains account record' do
        account_id = creating_account_with_client
        expect(account_id).to match(/\w{8}(-\w{4}){3}-\w{12}?/)
        expect(File.readlines(account_class.export_data(account_id)).grep(/#{table_name}/)).to be_true
        expect(File.readlines(account_class.export_data(account_id)).grep(/#{cols_names}/)).to be_true
      end

    end

  end

  # import data tests
  describe '#sniff_delimiter' do
    include_context 'account'

    it 'when data delimiter is sniffed as "|"' do
      open (dummy_data_file), 'w' do |io|
          io.puts(dummy_data)
      end
      
      expect(account_class.send(:sniff_delimiter, dummy_data_file)).to eq('|')
    end
  end
  
  describe '#fill_empty_column' do
    include_context 'account'

    it 'when empty value' do
      expect(account_class.send(:fill_empty_column, '')).to eq(:DEFAULT)
    end
  end

  describe '#fix_dates' do
    include_context 'account'

    it 'when valid date value' do
      expect{DateTime.parse(account_class.send(:fix_dates, '2017-04-05T15:01:39.000+0000'))}.not_to raise_error(ArgumentError)
    end

    it 'when valid date value match YYYY-MM-DD HH:MM:SS' do
      expect(account_class.send(:fix_dates, '2017-04-05T15:01:39.000+0000')).to match(/^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}/)
    end

    it 'when invalid date value' do
      expect{DateTime.parse(account_class.send(:fix_dates, 'JO'))}.to raise_error(ArgumentError)
    end
  end

  describe '#replace_boolean' do
    include_context 'account'

    context 'when value is boolean; replace' do
      it 'when true' do
        expect(account_class.send(:replace_boolean, true)).to eq(1)
      end

      it 'when false' do
        expect(account_class.send(:replace_boolean, false)).to eq(0)
      end

    end
  end

  describe '#replace_account_record_id' do
    include_context 'account'

    it 'when field is account_record_id' do
      expect(account_class.send(:replace_account_record_id, table_name, 'account_record_id', '1')).to eq(:@account_record_id)
    end

    it 'when field is record_id' do
      expect(account_class.send(:replace_account_record_id, table_name, 'record_id', '1')).to be_nil
    end

    it 'when field is target_record_id and table account_history' do
      expect(account_class.send(:replace_account_record_id, 'account_history', 'target_record_id', '1')).to eq(:@account_record_id)
    end

    it 'when field is search_key1 and table bus_ext_events_history' do
      expect(account_class.send(:replace_account_record_id, 'bus_ext_events_history', 'search_key1', '1')).to eq(:@account_record_id)
    end

    it 'when field is search_key1 and table bus_events_history' do
      expect(account_class.send(:replace_account_record_id, 'bus_events_history', 'search_key1', '1')).to eq(:@account_record_id)
    end

  end

  describe '#replace_tenant_record_id' do
    include_context 'account'

    it 'when field is tenant_record_id' do
      account_class.instance_variable_set(:@tenant_record_id, 10)
      expect(account_class.send(:replace_tenant_record_id, table_name, 'tenant_record_id', '1')).to eq(10)
    end

    it 'when field is search_key2 and table bus_ext_events_history' do
      account_class.instance_variable_set(:@tenant_record_id, 10)
      expect(account_class.send(:replace_tenant_record_id, 'bus_ext_events_history', 'search_key2', '1')).to eq(10)
    end

    it 'when field is search_key2 and table bus_events_history' do
      account_class.instance_variable_set(:@tenant_record_id, 10)
      expect(account_class.send(:replace_tenant_record_id, 'bus_events_history', 'search_key2', '1')).to eq(10)
    end

  end

  describe '#replace_uuid' do
    include_context 'account'

    context 'when round trip true' do
      it 'when replace uuid value' do
        account_class.instance_variable_set(:@round_trip_export_import, true)
        expect(account_class.send(:replace_uuid, table_name, 'account_id', dummy_account_id)).not_to eq(dummy_account_id)
      end

      it 'when do not replace value' do
        account_class.instance_variable_set(:@round_trip_export_import, true)
        expect(account_class.send(:replace_uuid, table_name, 'other_id', dummy_account_id)).to eq(dummy_account_id)
      end
    end

  end

  describe '#sanitize' do
    include_context 'account'

    it 'when skip payment method' do
      expect(account_class.send(:sanitize, 'payment_methods', 'plugin_name', 'Payment Method',true)).to eq('__EXTERNAL_PAYMENT__')
    end
    it 'when nothing to sanitize' do
      expect(account_class.send(:sanitize, table_name, 'id', dummy_account_id,false)).to eq(dummy_account_id)
    end

  end

  describe '#process_import_data' do
    include_context 'account'

    context 'when processing data to import' do
      it 'when column name qty eq column data qty without record_id' do
        account_class.instance_variable_set(:@generate_record_id,true)
        expect(account_class.send(:process_import_data, cols_data, table_name, cols_names.split('|'), false, []).size).to eq(cols_names.split("|").size-1)
      end
    end

  end

  describe '#import_data' do
    include_context 'account'

    context 'when data to import; main import method' do
      
      it 'when creating test schema' do
        db = create_test_schema
        expect(db).to eq(db_name)
      end
      
      it 'when importing data with empty file' do
        File.new(dummy_data_file, 'w+').close
        expect{account_class.import_data(dummy_data_file,nil,true,false,true) }.to raise_error(Interrupt,"Data on #{dummy_data_file} is invalid")
        File.delete(dummy_data_file)
      end
      
      it 'when importing data with no file' do
        expect{account_class.import_data(dummy_data_file,nil,true,false,true) }.to raise_error(Interrupt,'Need to specify a valid file')
      end
      
      it 'when importing data with new record_id' do
        open (dummy_data_file), 'w' do |io|
          io.puts(dummy_data)
        end
        expect{account_class.import_data(dummy_data_file,nil,true,false,true) }.not_to raise_error(Interrupt)

        row_count_inserted = delete_statement('accounts','id',dummy_account_id)
        expect(row_count_inserted).to eq('1')
        row_count_inserted = delete_statement('account_history','external_key',dummy_account_id)
        expect(row_count_inserted).to eq('1')
      end

      it 'when importing data reusing record_id' do
        open (dummy_data_file), 'w' do |io|
          io.puts(dummy_data)
        end
        expect{account_class.import_data(dummy_data_file,nil,true,false,false) }.not_to raise_error(Interrupt)

        row_count_inserted = delete_statement('accounts','id',dummy_account_id)
        expect(row_count_inserted).to eq('1')
        row_count_inserted = delete_statement('account_history','external_key',dummy_account_id)
        expect(row_count_inserted).to eq('1')
      end

      it 'when importing data with different tenant_record_id' do
        open (dummy_data_file), 'w' do |io|
          io.puts(dummy_data)
        end
        expect{account_class.import_data(dummy_data_file,10,true,false,true) }.not_to raise_error(Interrupt)

        row_count_inserted = delete_statement('accounts','id',dummy_account_id)
        expect(row_count_inserted).to eq('1')
        row_count_inserted = delete_statement('account_history','external_key',dummy_account_id)
        expect(row_count_inserted).to eq('1')
      end

      it 'when round trip' do
        open (dummy_data_file), 'w' do |io|
          io.puts(dummy_data)
        end
        expect{account_class.import_data(dummy_data_file,10,true,true,true) }.not_to raise_error(Interrupt)
        new_account_id = account_class.instance_variable_get(:@tables_id)

        row_count_inserted = delete_statement('accounts','id',new_account_id['accounts_id'])
        expect(row_count_inserted).to eq('1')
        row_count_inserted = delete_statement('account_history','external_key',new_account_id['accounts_id'])
        expect(row_count_inserted).to eq('1')
      end
      
      it 'when droping test schema' do
        response = drop_test_schema
        expect(response).to match('')
      end
     
    end
 
  end
  
  private 
    def creating_account_with_client
      if $account_id.nil?
        KillBillClient.url = url
        
        options = {
          :username => killbill_user,
          :password => killbill_password,
          :api_key => killbill_api_key,
          :api_secret => killbill_api_secrets
        }
    
        account = KillBillClient::Model::Account.new
        account.name = 'KPM Account Test'
        account.first_name_length = 3
        account.external_key = SecureRandom.uuid
        account.currency = 'USD'
        account = account.create('kpm_account_test', 'kpm_account_test', 'kpm_account_test', options)
        
        $account_id = account.account_id

      end
      
      $account_id
    end
    
    def delete_statement(table_name,column_name,account_id)
      response = `#{mysql_cli} -e "DELETE FROM #{table_name} WHERE #{column_name} = '#{account_id}'; SELECT ROW_COUNT();" 2>&1`
      response_msg = response.split("\n")
      row_count_inserted = response_msg[response_msg.size - 1]
        
      row_count_inserted
    end
    
    def create_test_schema
      response = `mysql --user=#{db_username} --password=#{db_password} -e "CREATE DATABASE IF NOT EXISTS #{db_name};"`
      response = `#{mysql_cli} < "#{test_ddl}" 2>&1`
      response_msg = response.split("\n")
      used_database = response_msg[response_msg.size - 1]
        
      used_database
    end
    
    def drop_test_schema
      response = `mysql --user=#{db_username} --password=#{db_password} -e "DROP DATABASE #{db_name};"`;
      response
    end

end