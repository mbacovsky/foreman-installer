class Foreman
  RESOURCES = {
      :subnet => 'Subnet',
      :domain => 'Domain',
      :smart_proxy => 'SmartProxy',
      :host => 'Host',
      :config_template => 'ConfigTemplate',
      :operating_system => 'OperatingSystem',
      :medium => 'Medium',
      :template_kind => 'TemplateKind',
      :os_default_template => 'OsDefaultTemplate',
      :partition_table => 'Ptable',
      :parameter => 'Parameter',
      :hostgroup => 'Hostgroup',
      :environment => 'Environment',
      :setting => 'Setting',
      :template_combination => 'TemplateCombination',
  }

  def initialize(api)
    @api = api
    # @resource = Hash.new { |h, k| h[k] = Resource.new(ForemanApi::Resources.const_get(RESOURCES[k]).new(@options), k) }
  end

  def method_missing(name, *args, &block)
    name = name.to_sym
    if @api.resources.include?(name)
      Resource.new(@api.resource(name))
    else
      super
    end
  end

  def respond_to?(name)
    name = name.to_sym
    if @api.resources.include?(name)
      true
    else
      super
    end
  end

  def version
    version = @api.resource(:home).action(:status).call
    version['version']
  end

  class Resource
    def initialize(api_resource)
      @api_resource = api_resource
    end

    def method_missing(name, *args, &block)
      if @api_resource.actions.include?(name)
        @api_resource.call(name, *args, &block)
      else
        super
      end
    end

    def respond_to?(name)
      @api_resource.actions.include?(name) || super
    end

    def show_or_ensure(identifier, attributes)
      begin
        object = @api_resource.action(:show).call(identifier)
        if should_update?(object, attributes)
          object = @api_resource.action(:update).call(identifier.merge({@api_resource.name.to_s => attributes}))
          object = @api_resource.action(:show).call(identifier)
        end
      rescue RestClient::ResourceNotFound
        object = @api_resource.action(:create).call({@api_resource.name.to_s => attributes}.merge(identifier.tap {|h| h.delete('id')}))
      end
      object
    end

    def show!(*args)
      error_message = args.delete(:error_message) || 'unknown error'
      begin
        object = @api_resource.action(:show).call(*args)
      rescue RestClient::ResourceNotFound
        raise StandardError, error_message
      end
      object
    end

    def index(*args)
      object = @api_resource.action(:index).call(*args)
      object['results']
    end

    def search(condition)
      index('search' => condition)
    end

    def first(condition)
      search(condition).first
    end

    def first!(condition)
      first(condition) or raise StandardError, "no #{@name} found by searching '#{condition}'"
    end

    private

    def should_update?(original, desired)
      desired.any? { |attribute, value| original[attribute] != value }
    end
  end
end
