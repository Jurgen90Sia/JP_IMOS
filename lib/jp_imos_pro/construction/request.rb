# frozen_string_literal: true
module JPImosPro
  module Construction
    module Request
      SCHEMA='jpimos.carcass-request/1'
      PRINCIPLE='top_bottom_between_sides-v1'
      ROLES=%w[left right top bottom].freeze
      module_function
      def validate(raw,budget)
        value=Materials::Context.copy(raw,budget,'/request')
        Materials::Context.keys(value,%w[schema article_instance_id principle panels],'/request')
        unless value['schema']==SCHEMA
          raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED','/request/schema')
        end
        unless value['principle']==PRINCIPLE
          raise ProjectCore::Fault.new('E_CONSTRUCTION_UNSUPPORTED','/request/principle')
        end
        Materials::Context.keys(value['panels'],ROLES,'/request/panels')
        panels=ROLES.each_with_object({}) do |role,h|
          h[role]=Materials::Context.validate_input(value['panels'][role],budget,'/request/panels/'+role)
        end
        id=ProjectCore::Document.new(budget).check(value['article_instance_id'],:uuid,'/request/article_instance_id')
        result={'schema'=>SCHEMA.dup,'article_instance_id'=>id,'principle'=>PRINCIPLE.dup,'panels'=>panels}
        ProjectCore::Document.new(budget).deep_freeze(result)
      end
    end
  end
end
