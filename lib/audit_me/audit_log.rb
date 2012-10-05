class AuditLog < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  validates_presence_of :event
  attr_accessible :item_type, :item_id, :event, :whodunnit, :object_changes

  def self.with_item_keys(item_type, item_id)
    scoped(:conditions => { :item_type => item_type, :item_id => item_id })
  end

  def self.creates
    where :event => 'create'
  end

  def self.updates
    where :event => 'update'
  end

  def self.destroys
    where :event => 'destroy'
  end

  def self.custom_event(event)
    where :event => event
  end

  # Returns what changed in this version of the item. Cf. `ActiveModel::Dirty#changes`.
  # Returns nil if your `versions` table does not have an `object_changes` text column.
  def changeset
    if self.class.column_names.include? 'object_changes'
      if changes = object_changes
        HashWithIndifferentAccess[YAML::load(changes)]
      else
        {}
      end
    end
  end
end