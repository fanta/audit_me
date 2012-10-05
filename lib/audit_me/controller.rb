module AuditMe
  module Controller

    def self.included(base)
      base.before_filter :set_audit_me_whodunnit
      base.before_filter :set_audit_me_controller_info
      base.before_filter :set_audit_me_enabled_for_controller
    end

    protected

    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    #
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_audit_me
      current_user rescue nil
    end

    # Returns any information about the controller or request that you
    # want AuditMe to store alongside any changes that occur. By
    # default this returns an empty hash.
    #
    # Override this method in your controller to return a hash of any
    # information you need. The hash's keys must correspond to columns
    # in your `audit_logs` table, so don't forget to add any new columns
    # you need.
    #
    # For example:
    #
    # {:ip => request.remote_ip, :user_agent => request.user_agent}
    #
    # The columns `ip` and `user_agent` must exist in your `audit_logs` # table.
    #
    # Use the `:meta` option to `AuditMe::Model::ClassMethods.has_audit_me`
    # to store any extra model-level data you need.
    def info_for_audit_me
      {}
    end

    # Returns `true` (default) or `false` depending on whether AuditMe should
    # be active for the current request.
    #
    # Override this method in your controller to specify when AuditMe should
    # be off.
    def audit_me_enabled_for_controller
      true
    end

    private

    # Tells AuditMe whether audit logs should be saved in the current request.
    def set_audit_me_enabled_for_controller
      ::AuditMe.enabled_for_controller = audit_me_enabled_for_controller
    end

    # Tells AuditMe who is responsible for any changes that occur.
    def set_audit_me_whodunnit
      ::AuditMe.whodunnit = user_for_audit_me
    end

    # Tells AuditMe any information from the controller you want
    # to store alongside any changes that occur.
    def set_audit_me_controller_info
      ::AuditMe.controller_info = info_for_audit_me
    end

  end
end