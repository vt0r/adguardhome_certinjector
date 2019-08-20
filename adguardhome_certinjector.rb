#!/usr/bin/env ruby
# ------------------
# adguardhome_certinjector.rb
# ------------------
# Copyright (c) 2019, Salvatore LaMendola <salvatore@lamendola.me>
#
# It's a ruby script that patches AdGuardHome.yaml with your SSL
# certificate and private key contents, mainly intended for use with
# cron jobs and similar scheduled tasks when automatically renewing certs.
#
require 'yaml'
require 'optparse'
require 'fileutils'

# Command line arguments
options = {}
args = OptionParser.new do |opts|
  opts.banner = 'Usage: ./adguardhome_certinjector.rb [options]'

  # Get the path to the AdGuardHome yaml config file
  opts.on('-c', '--config CONFIGFILE',
          'Path to the AdGuardHome config file') do |c|
    options['configfile'] = c
  end

  # Domain name for the cert/key - LetsEncrypt only
  opts.on('-d', '--domain yoursite.com', 'Domain name for cert/key -' \
          ' LetsEncrypt (certbot) mode only') do |d|
    options['domain'] = d
  end

  # Path to private key and certificate chain - Manual mode
  opts.on('-p', '--privatekey privkey.pem', 'Path to your private' \
          ' key - Manual mode') do |pk|
    options['privkey'] = pk
  end
  opts.on('-i', '--certchain fullchain.pem', 'Path to your public' \
          ' certificate chain - Manual mode') do |cert|
    options['certchain'] = cert
  end

  options['help_summary'] = opts
end
args.parse!

# Summary
summary = options['help_summary']

# Show the help summary
def showhelp(helptext, message = nil)
  puts message unless message.nil?
  puts helptext
end

# Validate our argument inputs
if options['configfile'].nil?
  showhelp(summary, 'ERROR: Missing AdGuardHome Config File')
  raise OptionParser::MissingArgument
end
if options['domain'].nil? && (options['privkey'].nil? ||
                              options['certchain'].nil?)
  showhelp(summary, 'ERROR: Must specify domain or key+cert path')
  raise OptionParser::MissingArgument
end
if options['domain'] && (options['privkey'] || options['certchain'])
  showhelp(summary, 'ERROR: Must specify only one of domain or key+cert')
  raise OptionParser::InvalidArgument
end

# Are we in manual mode?
manual = true if options['privkey'] && options['certchain']

# Use our inputs to set some variables
configfile = options['configfile']
domain = options['domain'] unless manual

# Load the configuration file data
config = YAML.load_file(configfile)

# Read current key/cert contents from config file
current_key = config['tls']['private_key']
current_cert = config['tls']['certificate_chain']

# If we're in manual mode, just do as we're told
if manual
  puts 'INFO: Key+cert specified. Proceeding in manual mode.'
  key_path = options['privkey']
  cert_path = options['certchain']
else
  # Path to the live LetsEncrypt certs/key
  puts 'INFO: Domain specified. Proceeding in LetsEncrypt mode.'
  key_path = "/etc/letsencrypt/live/#{domain}/privkey.pem"
  cert_path = "/etc/letsencrypt/live/#{domain}/fullchain.pem"
end

# Read the new key/cert contents from the cert path
new_key = File.read(key_path).chop
new_cert = File.read(cert_path).chop

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
nokey || config['tls']['private_key'] = new_key
nocert || config['tls']['certificate_chain'] = new_cert

# Write result back to the config file
puts "INFO: Writing new key and/or cert to #{configfile}"
File.write(configfile, config.to_yaml)

# Cleanly exit
exit 0
