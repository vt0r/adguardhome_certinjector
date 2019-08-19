#!/usr/bin/env ruby
# ------------------
# adguard_letsencrypt.rb
# ------------------
# Copyright (c) 2019, Salvatore LaMendola <salvatore@lamendola.me>
#
# Usage: ./adguard_letsencrypt.rb -c /path/to/AdGuardHome.yaml -d yoursite.com
#
# It's a ruby script that patches AdGuardHome.yaml with your LetsEncrypt
# certificate and private key contents, mainly intended for use with
# cron jobs and similar scheduled tasks when automatically renewing certs.
#
require 'yaml'
require 'optparse'
require 'fileutils'

# Command line arguments
options = {}
args = OptionParser.new do |opts|
  opts.banner = 'Usage: ./adguard_letsencrypt.rb [options]'

  # Get the path to the AdGuardHome yaml config file
  opts.on('-c', '--config CONFIGFILE',
          'Path to the AdGuardHome config file') do |c|
    options['configfile'] = c
  end

  # Domain name for the cert/key
  opts.on('-d', '--domain DOMAIN', 'Domain name for cert/key') do |d|
    options['domain'] = d
  end

  opts.on('-k', '--privkey PATH', 'Path to the private key') do |k|
    options['keypath'] = k
  end
  opts.on('-f', '--fullchain PATH', 'Path to the fullchain file') do |f|
    options['fullchainpath'] = f
  end
  options['help_summary'] = opts
end
args.parse!

# Validate our argument input
if options['configfile'].nil? || (options['domain'].nil?) && (options['keypath'].nil? || options['fullchainpath'].nil?)
  puts options['help_summary']
  raise OptionParser::MissingArgument
end

# Use our input to set some variables
configfile = options['configfile']
domain = options['domain']
if !(options['keypath'].nil? || options['fullchainpath'].nil?)
  keypath = options['keypath']
  fullchainpath = options['fullchainpath']
end

# Load the configuration file data
config = YAML.load_file(configfile)

# Read current key/cert contents from config file
current_key = config['tls']['private_key']
current_cert = config['tls']['certificate_chain']

# Path to the live LetsEncrypt certs/key
le_cert_path = "/etc/letsencrypt/live/#{domain}"

# Read the new key/cert contents from the cert path
if options['keypath'].nil? || options['fullchainpath'].nil?
  new_key = File.open("#{le_cert_path}/privkey.pem").read.chop
  new_cert = File.open("#{le_cert_path}/fullchain.pem").read.chop
else
  new_key = File.open("#{keypath}").read.chop
  new_cert = File.open("#{fullchainpath}"}.read.chop
end

# First, let's verify the new cert/key are actually different
if current_cert == new_cert
  puts 'INFO: Cert is unchanged'
  nocert = true
end
if current_key == new_key
  puts 'INFO: Key is unchanged'
  nokey = true
end

# Do nothing if both are unchanged
if nocert && nokey
  puts 'INFO: Both key and cert are unchanged. Exiting without modifications.'
  exit 0
end

# Backup the original file for safety(TM)
bakfile = "#{configfile}.bak"
puts "INFO: Creating backup file #{bakfile}"
FileUtils.cp(configfile, bakfile)

# Overwrite key and cert with new contents
nokey == true || config['tls']['private_key'] = new_key
nocert == true || config['tls']['certificate_chain'] = new_cert

# Write result back to the config file
puts "INFO: Writing new key and/or cert to #{configfile}"
File.write(configfile, config.to_yaml)

# Cleanly exit
exit 0
