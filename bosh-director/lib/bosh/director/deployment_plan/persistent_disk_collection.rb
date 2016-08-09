module Bosh::Director
  module DeploymentPlan
    class PersistentDiskCollection

      def initialize(options={})
        #TODO: maybe change the way this boolean works
        @multiple_disks = options.fetch(:multiple_disks, false)
        @collection = []
      end

      def add_by_disk_size(disk_size)
        @collection << LegacyPersistentDisk.new(DiskType.new(SecureRandom.uuid, disk_size, {}))

        raise Exception if @collection.size > 1
      end

      def add_by_disk_type(disk_type)
        @collection << LegacyPersistentDisk.new(disk_type)

        raise Exception if @collection.size > 1
      end

      def add_by_disk_name_and_type(disk_name, disk_type)
        @collection << NewPersistentDisk.new(disk_name, disk_type)
      end

      def needs_disk?
        if @multiple_disks

        else
          if @collection.size > 0
            return @collection.first.size > 0
          end
        end
      end

      def diff_with(persistent_disk_models)
        if @multiple_disks
          diff_new_persistent_disks(persistent_disk_models)
        else
          diff_legacy_persistent_disks(persistent_disk_models)
        end
      end

      def create_disks(disk_creator, instance_id)
        if @multiple_disks
          []
        else
          disk_size = @collection.first.size
          cloud_properties = @collection.first.cloud_properties

          disk_cid = disk_creator.create(disk_size, cloud_properties)

          disk = Models::PersistentDisk.create(
            disk_cid: disk_cid,
            active: false,
            instance_id: instance_id,
            size: disk_size,
            cloud_properties: cloud_properties,
          )

          disk_creator.attach(disk_cid)

          [disk]
        end
      end

      def generate_spec
        if @multiple_disks
        else
          spec = {}
          if @collection.size > 0
            # supply both for reverse compatibility with old agent
            spec['persistent_disk'] = @collection.first.size
            # old agents will ignore this pool
            # keep disk pool for backwards compatibility
            spec['persistent_disk_pool'] = @collection.first.spec
            spec['persistent_disk_type'] = @collection.first.spec
          else
            spec['persistent_disk'] = 0
          end
        end

        spec
      end

      private

      def diff_new_persistent_disks(persistent_disk_models)

      end

      def diff_legacy_persistent_disks(persistent_disk_models)
        #TODO: what about moving from multiple disks to a single disk?
        old_persistent_disk_size = persistent_disk_models.empty? ? 0 : persistent_disk_models.first.size
        old_persistent_disk_cloud_properties = persistent_disk_models.empty? ? 0 : persistent_disk_models.first.cloud_properties
        new_disk_size = @collection.empty? ? 0 : @collection.first.size
        new_disk_cloud_properties = @collection.empty? ? {} : @collection.first.cloud_properties

        changed = new_disk_size != old_persistent_disk_size
        return true if changed

        new_disk_size != 0 && new_disk_cloud_properties != old_persistent_disk_cloud_properties
      end

      class PersistentDisk
        attr_reader :type

        def initialize(type)
          @type = type
        end

        def type_name
          @type.name
        end

        def cloud_properties
          @type.cloud_properties
        end

        def size
          @type.disk_size
        end

        def spec
          @type.spec
        end

        def is_legacy?
          raise NotImplementedError
        end
      end

      class NewPersistentDisk < PersistentDisk
        attr_reader :name

        def initialize(name, type)
          @name = name
          super(type)
        end

        def is_legacy?
          false
        end
      end

      class LegacyPersistentDisk < PersistentDisk
        def is_legacy?
          true
        end
      end
    end
  end
end
