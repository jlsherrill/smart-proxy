require 'fileutils'
require 'pathname'

module Proxy::TFTP
  extend Proxy::Log

  class << self

    # creates TFTP syslinux config file
    # Assumes we want to use pxelinux.cfg for configuration files.
    def create mac, config
      if mac.nil? or config.nil?
        logger.info "invalid parameters recieved"
        return false
      end

      FileUtils.mkdir_p syslinux_dir

      File.open(syslinux_mac(mac), 'w') {|f| f.write(config) }
      logger.info "TFTP entry for #{mac} created successfully"
    rescue StandardError => e
      logger.warn "TFTP Adding entry failed: #{e}"
      false
    end
    
    
    def create_default_menu config
      if config.nil?
        logger.info "invalid parameters recieved"
        return false
      end
      
      FileUtils.mkdir_p syslinux_dir
      File.open(syslinux_default_menu, 'w') {|f| f.write(config) }
    rescue StandardError => e
      logger.warn "TFTP Adding default entry failed: #{e}"
      false
    end


    # removes links created by create method
    # Assumes we want to use pxelinux.cfg for configuration files.
    # parameter is a mac address
    def remove mac
      file = syslinux_mac(mac)
      if File.exists?(file)
        FileUtils.rm_f file
        logger.debug "TFTP entry for #{mac} removed successfully"
      else
        logger.warn "Skipping a request to delete a file which doesn't exists"
      end
    rescue StandardError => e
      logger.warn "TFTP removing entry failed: #{e}"
      false
    end

    def fetch_boot_file dst, src
      filename    = src.split("/")[-1]
      destination = Pathname.new("#{SETTINGS.tftproot}/#{dst}-#{filename}")

      #ensure that our image direcotry exists
      #as the dst might contain another sub directory
      FileUtils.mkdir_p destination.parent

      cmd = "wget --no-check-certificate -c -q #{src} -O \"#{destination}\""
      logger.debug "trying to execute #{cmd}"
      `#{cmd}`
      $? == 0
    end

    private
    # returns the absolute path
    def path(p = nil)
      p ||= SETTINGS.tftproot || File.dirname(__FILE__) + "/tftpboot"
      # are we running in RAILS or as a standalone CGI?
      dir = defined?(RAILS_ROOT) ? RAILS_ROOT : File.dirname(__FILE__)
      return (p =~ /^\//) ? p : "#{dir}/#{p}"
    end

    def syslinux_mac mac
      "#{syslinux_dir}/01-"+mac.gsub(/:/,"-").downcase
    end

    def syslinux_default_menu
      "#{syslinux_dir}/default"
    end

    def syslinux_dir
      "#{path}/pxelinux.cfg"
    end

  end
end
