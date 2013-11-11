#!/usr/bin/env ruby

require "fileutils"
require 'yaml'
require 'net/ssh'
require 'net/scp'
require 'pty'
require 'expect'

def tug_logs( name, config )

  local_folder = "./servers/#{name}/file_store"
  remote_folder = '/var/log'
  today = Date.today.to_s

  # create folder if needs be
  FileUtils.mkdir_p( local_folder ) unless File.exists?( local_folder ) && File.directory?( local_folder )

  puts "Attempting to download logs for #{name} from #{remote_folder} #{local_folder}...\n"

  # scp to files to the local dir
  Net::SCP.start( config[ 'ssh_host' ], config[ 'ssh_username' ], :password => config['ssh_password' ], :port => config[ 'ssh_port' ] ) do |scp|

    # scp to files to the local dir        
    scp.download!( remote_folder, local_folder, :recursive => true )
    puts "Done.\n\n"

    puts "Compressing logs...\n\n"

    # zip them up
    zip_filename = "./servers/#{name}/#{today}.7z"
    exec "7za a -t7z #{zip_filename} #{local_folder}/*"
    puts "Done\n\n"

  end

end

# grab the configs
server_configs = YAML.load( File.read( "servers.yaml" ) )

# if we have some configs loop them
if server_configs
  
  server_configs.each do | name, config |

    begin

      # tug our logs off
      tug_logs( name, config ) 

    rescue Exception => e

       "Failed to tugg logs off #{name}"

    end

  end

end

puts "Invalid servers.yaml file"
exit
