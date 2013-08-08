#! /usr/bin/env ruby

###################################################################################
#                                                                                 #
#                   Copyright 2010-2013 Ning, Inc.                                #
#                                                                                 #
#      Ning licenses this file to you under the Apache License, version 2.0       #
#      (the "License"); you may not use this file except in compliance with the   #
#      License.  You may obtain a copy of the License at:                         #
#                                                                                 #
#          http://www.apache.org/licenses/LICENSE-2.0                             #
#                                                                                 #
#      Unless required by applicable law or agreed to in writing, software        #
#      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT  #
#      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the  #
#      License for the specific language governing permissions and limitations    #
#      under the License.                                                         #
#                                                                                 #
###################################################################################

require 'aws-sdk'
require 'net/http'
require 'net/scp'
require 'net/ssh'
require 'openssl'
require 'tmpdir'
require 'optparse'
require 'erb'
require 'yaml'


EC2_INSTALL_DEST="/home/ubuntu/killbill_install"
EC2_INSTALL_CONFIG_DEST="#{EC2_INSTALL_DEST}/config"


# Script to terminate the instances
TERMINATE_FILE_NAME = "/tmp/ec2_terminate.in"

#
# Remote script that live under same directory
#
AMI_INSTALL_SCRIPT="ami_install.sh"
KILLBILL_INSTALL_SCRIPT="killbill_install.rb"


class SimpleEC2

  attr_reader :aws_ec2, :ami, :instance_type, :zone, :key_name, :security_groups, :ssh_private_key

  def initialize(access_key, secret_key, ami, instance_type, zone, key_name, security_groups, ssh_private_key)
    @aws_ec2 = AWS::EC2.new({:access_key_id => access_key,
                             :secret_access_key => secret_key})
    @ami = ami
    @instance_type = instance_type
    @zone = zone
    @key_name = key_name
    @ssh_private_key= ssh_private_key
    @security_groups = security_groups
  end

  def create_instance(wait_for_completion)
    result = @aws_ec2.instances.create(:image_id => @ami,
                                       :security_groups => @security_groups,
                                       :instance_type => @instance_type,
                                       :placement => {:availability_zone => @zone},
                                       :key_name => @key_name)
    add_tags(result.id, [{:key => 'role',
                          :value => 'ri-test'}])
    wait_for_instance(result.id, :running) if wait_for_completion
    result
  end

  def terminate_all_running_instances(wait_for_completion)

    instances = running_instances
    return if instances.length == 0
    terminate_instances(instances.map { |i| i[:id] }, wait_for_completion)
  end


  def stop_instances(instances_id, force, wait_for_completion)
    result = @aws_ec2.client.stop_instances({:instance_ids => instances_id},
                                            :force => force)
    result.instances_set.each do |r|
      wait_for_instance(r.id, :stopped) if wait_for_completion
      puts "Instance #{r.instance_id} is now #{r.current_state.name}"
    end
  end

  def terminate_instances(instances_id, wait_for_completion)

    result = @aws_ec2.client.terminate_instances({:instance_ids => instances_id})
    result.instances_set.each do |r|
      wait_for_instance(r.instance_id, :terminated) if wait_for_completion
      puts "Instance #{r.instance_id} is now #{r.current_state.name}"
    end
  end

  def upload_file_to_running_instances(src, dest)
    running_instances.each do |i|
      upload_file(i[:dns], src, dest)
    end
  end

  def upload_file(dns_name, src, dest)
    puts "Uploading file #{src} to #{dns_name}:#{dest}"
    Net::SCP.start(dns_name, "ubuntu", :keys => @ssh_private_key) do |scp|
      scp.upload! src, dest
    end
  end

  def execute_remote(dns_name, cmd)
    puts "Starting script #{cmd} on #{dns_name}"
    Net::SSH.start(dns_name, "ubuntu", :keys => @ssh_private_key) do |ssh|
      result = ssh.exec!(cmd)
    end
  end

  def running_instances
    instances = @aws_ec2.instances
    result = []
    instances.each do |i|
      result.push(i) if i.status == :running
      puts "found running instance #{i.inspect}"
    end
    result
  end

  private

  def wait_for_instance(instance_id, state)
    puts "wait_for_instance #{instance_id} => state = #{state}"
    has_completed = false
    nb_attempt = 1
    begin
      instance = @aws_ec2.instances[instance_id]
      if instance.nil?
        puts "Null instance"
        return
      end

      current_status = instance.status
      has_completed = case state
                        when :terminated then
                          instance.nil? || current_status == state
                        else
                          current_status == state
                      end
      puts "Waiting for instance = #{instance_id} #{current_status} -> #{state} [attempt #{nb_attempt}]" if !has_completed
      nb_attempt = nb_attempt + 1
      sleep(3.0)
    end while !has_completed
  end


  def add_tags(instance_id, tags)
    @aws_ec2.client.create_tags(:resources => [instance_id],
                                :tags => tags)
  end
end

# Used to debug and avoid having to restart instances
class FakeInstance

  attr_reader :id, :public_dns_name

  def initialize(id, public_dns_name)
    @id = id
    @public_dns_name = public_dns_name
  end
end


class Launcher

  attr_reader :ec2, :nb_instances, :install_config, :instances

  def initialize(config, nb_instances=1)
    # Command line
    @config = config
    @input_config_dir = @config.input_config_dir
    @killbill_config = "#{@input_config_dir}/#{@config.killbill_config}"
    @aws_config = "#{@input_config_dir}/#{@config.aws_config}"

    @aws_config = YAML.load(ERB.new(File.read(@aws_config)).result)
    @ec2_config = @aws_config[:aws][:ec2]
    @rds_config = @aws_config[:aws][:rds]


    @ec2 = SimpleEC2.new(@ec2_config[:access_key],
                         @ec2_config[:secret_key],
                         @ec2_config[:ami],
                         @ec2_config[:instance_type],
                         @ec2_config[:availability_zone],
                         @ec2_config[:key_name],
                         @ec2_config[:security_group],
                         "#{@input_config_dir}/#{@ec2_config[:ssh_private_key_file_name]}")
    @nb_instances = nb_instances
    @instances = []
  end


  def do_it
    if @config.terminate.nil?
      install_and_launch
    else
      terminate(@config.terminate)
    end
  end

  private

  def install_and_launch
    # First we start the instances
    start_instances
    #@instances = [ FakeInstance.new("i-c10fe5a0", "ec2-54-242-133-4.compute-1.amazonaws.com")]

    # Second we upload the scripts
    upload_scripts
    # Third we initialize the ami to bootstrap the zone
    initialize_ami
    # Fourth, we copy the config files into the remote install directory
    upload_configs
    # Finally run the install script on each zone
    install_killbill
  end

  def terminate(running_instance_file)
    terminate_list = []
    File.open(running_instance_file, "r") do |f|
      while (instance_id = f.gets)
        terminate_list << instance_id.strip
      end
    end
    @ec2.terminate_instances(terminate_list, false)
  end


  def create_tmp_config_with_rds(input_properties)

    tmp = "/tmp/#{File.basename(input_properties)}"
    File.delete(tmp) if File.exists?(tmp)

    jdbc_url = "jdbc:mysql://#{@rds_config[:endpoint]}:3306/killbill"
    jdbc_user = "#{@rds_config[:user_name]}"
    jdbc_pwd = "#{@rds_config[:password]}"

    if File.extname(input_properties) == ".yml"
      input = YAML.load(ERB.new(File.read(input_properties)).result)
      if input[:database].nil?
        return input_properties
      end
      input[:database][:url] = jdbc_url
      input[:database][:username] = jdbc_user
      input[:database][:password] = jdbc_pwd
      File.open(tmp, "w") { |f| f.write(input.to_yaml) }
    else
      FileUtils.copy(input_properties, tmp)
      File.open(tmp, "a") do |f|
        f.write("com.ning.jetty.jdbi.url=jdbc:mysql://#{@rds_config[:endpoint]}:3306/killbill\n")
        f.write("com.ning.jetty.jdbi.user=#{@rds_config[:user_name]}\n")
        f.write("com.ning.jetty.jdbi.password=#{@rds_config[:password]}\n")
      end
    end
    tmp
  end


  def start_instances
    @nb_instances.times do |i|
      instance = @ec2.create_instance(true)
      puts "started instance #{instance.id} -> #{instance.public_dns_name}"
      @instances << instance
    end
    generate_terminate_script(TERMINATE_FILE_NAME)
  end


  def upload_scripts
    @instances.each do |i|
      upload_with_retry(i, AMI_INSTALL_SCRIPT, "/tmp")
      upload_with_retry(i, KILLBILL_INSTALL_SCRIPT, "/tmp")
    end
  end

  def upload_configs
    @instances.each do |i|
      # Copy killbill.config

      upload_with_retry(i, "#{@killbill_config}", EC2_INSTALL_CONFIG_DEST)
      # Copy the config files for Killbill and its declared plugins
      Dir["#{@input_config_dir}/*.{properties,yml}"].each do |e|
        e_with_rds_config = create_tmp_config_with_rds(e)
        upload_with_retry(i, e_with_rds_config, EC2_INSTALL_CONFIG_DEST)
      end
    end
  end


  def upload_with_retry(cur_instance, src, dest)
    max_retry = 10;
    nb_retry = 1;
    while nb_retry < max_retry
      begin
        puts "Uploading #{src} to instance #{cur_instance.public_dns_name}:#{dest} [attempt #{nb_retry}]"
        res = @ec2.upload_file(cur_instance.public_dns_name, src, dest)
        return
      rescue SystemCallError => e
        nb_retry = nb_retry + 1
        sleep 3.0
      end
    end
  end

  def initialize_ami
    @instances.each do |cur_instance|
      puts "Installing instance #{cur_instance.id} -> #{cur_instance.public_dns_name}.
Follow along: ssh -l ubuntu -i #{@ec2.ssh_private_key} #{cur_instance.public_dns_name} tail -f /home/ubuntu/killbill_install/ami_install.log"
      @ec2.execute_remote(cur_instance.public_dns_name, "chmod a+x /tmp/#{AMI_INSTALL_SCRIPT}")
      @ec2.execute_remote(cur_instance.public_dns_name, "/tmp/#{AMI_INSTALL_SCRIPT}")
    end
  end

  def install_killbill
    @instances.each do |cur_instance|
      puts "Installing Killbill on instance #{cur_instance.id} -> #{cur_instance.public_dns_name}"
      @ec2.execute_remote(cur_instance.public_dns_name, "chmod a+x #{EC2_INSTALL_DEST}/#{KILLBILL_INSTALL_SCRIPT}")
      @ec2.execute_remote(cur_instance.public_dns_name, "#{EC2_INSTALL_DEST}/#{KILLBILL_INSTALL_SCRIPT}")
    end
  end

  def generate_terminate_script(output)
    File.delete(output) if File.exists?(output)
    File.open(output, "w") do |f|
      @instances.each do |i|
        f.write("#{i.id}\n")
      end
    end
    puts "Generated terminate file: #{output}"
  end

end

class CommandArgument

  attr_reader :options, :args

  attr_accessor :aws_config, :input_config_dir, :killbill_config, :terminate

  def initialize(args)
    @options = {}
    @args = args
    parse
  end


  private

  def parse()
    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: launcher.rb [options]"

      opts.separator ""

      opts.on("-t", "--terminate TERMINATE_SCRIPT",
              "Mode <start|stop>") do |t|
        @options[:terminate] = t
      end

      opts.on("-a", "--aws_config AWS_CONFIG",
              "AWS config") do |a|
        @options[:aws_config] = a
      end

      opts.on("-i", "--input_config_dir INPUT",
              "Input dir for killbill and plugin properties") do |i|
        @options[:input_config_dir] = i
      end

      opts.on("-k", "--killbill_config KBCONF",
              "Kill Bill config") do |k|
        @options[:killbill_config] = k
      end
    end
    optparse.parse!(@args)

    @options.keys.each do |k|
      send("#{k}=".to_sym, @options[k])
    end
  end

end

arg = CommandArgument.new(ARGV)
launcher = Launcher.new(arg)
launcher.do_it




