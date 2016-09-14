module Api
  class OrchestrationTemplatesController < BaseController
    def delete_resource(type, id, data = {})
      klass    = collection_class(type)
      resource = resource_search(id, type, klass)
      super
      resource.raw_destroy if resource.is_a?(OrchestrationTemplateVnfd)
    end
  end
end
