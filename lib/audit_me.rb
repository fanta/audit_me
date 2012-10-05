require 'singleton'
require 'yaml'

require 'audit_me/config'
require 'audit_me/controller'
require 'audit_me/has_audit_me'
require 'audit_me/version'
require 'audit_me/audit_log'

# AuditMe's module methods can be called in both models and controllers.
module AuditMe

  # Switches AuditMe on or off.
  def self.enabled=(value)
    AuditMe.config.enabled = value
  end

  # Returns `true` if AuditMe is on, `false` otherwise.
  # AuditMe is enabled by default.
  def self.enabled?
    !!AuditMe.config.enabled
  end

  # Returns `true` if AuditMe is enabled for the request, `false` otherwise.
  #
  # See `AuditMe::Controller#audit_me_enabled_for_controller`.
  def self.enabled_for_controller?
    !!audit_me_store[:request_enabled_for_controller]
  end

  # Sets whether AuditMe is enabled or disabled for the current request.
  def self.enabled_for_controller=(value)
    audit_me_store[:request_enabled_for_controller] = value
  end

  # Returns who is reponsible for any changes that occur.
  def self.whodunnit
    audit_me_store[:whodunnit]
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly. In a controller it is set
  # automatically to the `current_user`.
  def self.whodunnit=(value)
    audit_me_store[:whodunnit] = value
  end

  # Returns any information from the controller that you want
  # AuditMe to store.
  #
  # See `AuditMe::Controller#info_for_audit_me`.
  def self.controller_info
    audit_me_store[:controller_info]
  end

  # Sets any information from the controller that you want AuditMe
  # to store. By default this is set automatically by a before filter.
  def self.controller_info=(value)
    audit_me_store[:controller_info] = value
  end


  private
  
  def self.audit_me_store
    Thread.current[:audit_me] ||= { 
      :request_enabled_for_controller => true
    }
  end

  # Returns AuditMe's configuration object.
  def self.config
    @@config ||= AuditMe::Config.instance
  end

end


ActiveSupport.on_load(:active_record) do
  include AuditMe::Model
end

ActiveSupport.on_load(:action_controller) do
  include AuditMe::Controller
end