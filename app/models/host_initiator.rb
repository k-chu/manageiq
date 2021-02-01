class HostInitiator < ApplicationRecord
  include ProviderObjectMixin
  include SupportsFeatureMixin
  include CustomActionsMixin

  belongs_to :ext_management_system, :foreign_key => :ems_id
  belongs_to :physical_storage, :inverse_of => :host_initiators

  has_many :san_addresses, :as => :owner, :dependent => :destroy

  virtual_total :v_total_addresses, :san_addresses

  supports :refresh_ems
  supports_not :create
  acts_as_miq_taggable

  def my_zone
    ems = ext_management_system
    ems ? ems.my_zone : MiqServer.my_zone
  end

  def self.class_by_ems(ext_management_system)
    # TODO(lsmola) taken from Orchestration stacks, correct approach should be to have a factory on ExtManagementSystem
    # side, that would return correct class for each provider
    ext_management_system && ext_management_system.class::HostInitiator
  end

  def refresh_ems
    unless ext_management_system
      raise _("No Provider defined")
    end
    unless ext_management_system.has_credentials?
      raise _("No Provider credentials defined")
    end
    unless ext_management_system.authentication_status_ok?
      raise _("Provider failed last authentication check")
    end

    EmsRefresh.queue_refresh(ext_management_system)
  end

  def self.create_host_initiator_queue(userid, ext_management_system, options = {})
    task_opts = {
      :action => "creating HostInitiator for user #{userid}",
      :userid => userid
    }

    queue_opts = {
      :class_name  => 'HostInitiator',
      :method_name => 'create_host_initiator',
      :role        => 'ems_operations',
      :queue_name  => ext_management_system.queue_name_for_ems_operations,
      :zone        => ext_management_system.my_zone,
      :args        => [ext_management_system.id, options]
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def self.create_host_initiator(ems_id, options = {})
    raise ArgumentError, _("ems_id cannot be nil") if ems_id.nil?

    ext_management_system = ExtManagementSystem.find_by(:id => ems_id)
    raise ArgumentError, _("ext_management_system cannot be found") if ext_management_system.nil?

    klass = class_by_ems(ext_management_system)
    klass.raw_create_host_initiator(ext_management_system, options)
  end

  def self.raw_create_host_initiator(_ext_management_system, _options = {})
    raise NotImplementedError, _("raw_create_host_initiator must be implemented in a subclass")
  end
end