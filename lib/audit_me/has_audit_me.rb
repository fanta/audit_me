module AuditMe
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end


    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.
      #
      # Options:
      # :on the events to track (optional; defaults to all of them). Set to an array of
      # `:create`, `:update`, `:destroy` as desired.
      # :class_name the name of a custom AuditLog class. This class should inherit from AuditLog.
      # :ignore an array of attributes for which a new `AuditLog` will not be created if only they change.
      # :if, :unless Procs that allow to specify conditions when to save audit logs for an object
      # :only inverse of `ignore` - a new `AuditLog` will be created only for these attributes if supplied
      # :skip fields to ignore completely. As with `ignore`, updates to these fields will not create
      # a new `AuditLog`. In addition, these fields will not be included in the serialized versions
      # of the object whenever a new `AuditLog` is created.
      # :meta a hash of extra data to store. You must add a column to the `audit_logs` table for each key.
      # Values are objects or procs (which are called with `self`, i.e. the model with the audit
      # me). See `AuditMe::Controller.info_for_audit_me` for how to store data from
      # the controller.
      # :audit_logs the name to use for the audit logs association. Default is `:audit_logs`.
      def has_audit_me(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        class_attribute :audit_log_class_name
        self.audit_log_class_name = options[:class_name] || 'AuditLog'

        class_attribute :ignore
        self.ignore = ([options[:ignore]].flatten.compact || []).map &:to_s

        class_attribute :if_condition
        self.if_condition = options[:if]

        class_attribute :unless_condition
        self.unless_condition = options[:unless]

        class_attribute :skip
        self.skip = ([options[:skip]].flatten.compact || []).map &:to_s

        class_attribute :only
        self.only = ([options[:only]].flatten.compact || []).map &:to_s

        class_attribute :meta
        self.meta = options[:meta] || {}

        class_attribute :audit_me_enabled_for_model
        self.audit_me_enabled_for_model = true

        class_attribute :audit_logs_association_name
        self.audit_logs_association_name = options[:audit_logs] || :audit_logs

        has_many self.audit_logs_association_name,
                 :class_name => audit_log_class_name,
                 :as => :item,
                 :order => "created_at ASC, #{self.audit_log_class_name.constantize.primary_key} ASC"

        after_create :record_create, :if => :save_audit_log? if !options[:on] || options[:on].include?(:create)
        before_update :record_update, :if => :save_audit_log? if !options[:on] || options[:on].include?(:update)
        after_destroy :record_destroy if !options[:on] || options[:on].include?(:destroy)
      end

      # Switches AuditMe off for this class.
      def audit_me_off
        self.audit_me_enabled_for_model = false
      end

      # Switches AuditMe on for this class.
      def audit_me_on
        self.audit_me_enabled_for_model = true
      end
    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_audit_me`.
    module InstanceMethods

      attr_accessor :custom_event

      # Executes the given method or block without creating a new audit log.
      def without_auditing(method = nil)
        audit_me_was_enabled = self.audit_me_enabled_for_model
        self.class.audit_me_off
        method ? method.to_proc.call(self) : yield
      ensure
        self.class.audit_me_on if audit_me_was_enabled
      end

      private

      def audit_log_class
        audit_log_class_name.constantize
      end

      def record_create
        if switched_on?
          send(self.class.audit_logs_association_name).create merge_metadata(:event => 'create', :whodunnit => AuditMe.whodunnit)
        end
      end

      def record_update
        if switched_on? && changed_notably?
          data = {
            :event => custom_event || 'update',
            :whodunnit => AuditMe.whodunnit
          }

          data[:object_changes] = what_changed if(audit_log_class.column_names.include? 'object_changes')
          send(self.class.audit_logs_association_name).build merge_metadata(data)
        end
      end

      def record_destroy
        if switched_on? and not new_record?
          audit_log_class.create merge_metadata(:item_id => self.id,
                                              :item_type => self.class.base_class.name,
                                              :event => 'destroy',
                                              :object_changes => what_changed,
                                              :whodunnit => AuditMe.whodunnit)
        end
      end

      def merge_metadata(data)
        # First we merge the model-level metadata in `meta`.
        meta.each do |k,v|
          data[k] =
            if v.respond_to?(:call)
              v.call(self)
            elsif v.is_a?(Symbol) && respond_to?(v)
              send(v)
            else
              v
            end
        end
        # Second we merge any extra data from the controller (if available).
        data.merge(AuditMe.controller_info || {})
      end

      def what_changed
        # The double negative (reject, !include?) preserves the hash structure of self.changes.
        self.changes.reject do |key, value|
          !notably_changed.include?(key)
        end.to_yaml
      end

      def changed_notably?
        notably_changed.any?
      end

      def notably_changed
        self.class.only.empty? ? changed_and_not_ignored : (changed_and_not_ignored & self.class.only)
      end

      def changed_and_not_ignored
        changed - self.class.ignore - self.class.skip
      end

      def switched_on?
        AuditMe.enabled? && AuditMe.enabled_for_controller? && self.class.audit_me_enabled_for_model
      end

      def save_audit_log?
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end