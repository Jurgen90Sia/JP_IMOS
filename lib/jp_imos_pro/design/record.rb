# frozen_string_literal: true
module JPImosPro
  module Design
    module Record
      module_function
      def validate(raw,budget,prefix='')
        owned=Materials::Context.copy(raw,budget,prefix)
        validate_owned(owned,budget,prefix)
      end
      def validate_owned(owned,budget,prefix='')
        if owned.instance_of?(Hash) && owned.key?('schema') && owned['schema']!=SCHEMA
          raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED',prefix+'/schema')
        end
        Materials::Context.keys(owned,%w[schema project construction_requests],prefix)
        unless owned['schema']==SCHEMA
          raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED',prefix+'/schema')
        end
        begin
          project=ProjectCore::Document.validate_owned(owned['project'],budget)
        rescue ProjectCore::Fault => e
          raise ProjectCore::Fault.new(e.code,prefix+'/project'+e.json_pointer,e.entity_ref,e.details,e.engine)
        end
        values=owned['construction_requests']
        unless values.instance_of?(Array)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',prefix+'/construction_requests')
        end
        budget.cap(values.size,:articles,prefix+'/construction_requests')
        requests=Array.new(values.size)
        (0...values.size).sort_by { |i| i.to_s }.each do |i|
          budget.tick(prefix+'/construction_requests')
          begin
            requests[i]=Construction::Request.validate_owned(values[i],budget)
          rescue ProjectCore::Fault => e
            tail=e.json_pointer.delete_prefix('/request')
            raise ProjectCore::Fault.new(e.code,"#{prefix}/construction_requests/#{i}"+tail,e.entity_ref,e.details,e.engine)
          end
        end
        article_ids=project['articles'].each_with_object({}) do |a,h|
          budget.tick(prefix+'/project/articles')
          h[a['id']]=true
        end
        seen={}
        errors=[]
        requests.each_with_index do |request,i|
          budget.tick(prefix+'/construction_requests')
          id=request['article_instance_id']
          p="#{prefix}/construction_requests/#{i}/article_instance_id"
          errors << ProjectCore::Fault.new('E_DUPLICATE_ID',p) if seen.key?(id)
          errors << ProjectCore::Fault.new('E_REFERENCE_MISSING',p) unless article_ids.key?(id)
          seen[id]=true
        end
        raise errors.min_by(&:json_pointer) unless errors.empty?
        missing=article_ids.keys-seen.keys
        unless missing.empty?
          raise ProjectCore::Fault.new('E_REFERENCE_MISSING',prefix+'/construction_requests',nil,{article_instance_ids:missing.sort})
        end
        state={'schema'=>SCHEMA.dup,'project'=>project,'construction_requests'=>requests}
        ProjectCore::Document.new(budget).deep_freeze(state)
      end
    end
  end
end
