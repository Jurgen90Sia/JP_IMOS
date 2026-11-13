# frozen_string_literal: true
module JPImosPro
  module Design
    module PhysicalRecord
      module_function
      def scoped(prefix)
        yield
      rescue ProjectCore::Fault => e
        raise ProjectCore::Fault.new(e.code,prefix+e.json_pointer,e.entity_ref,e.details,e.engine)
      end
      def validate(raw,budget,prefix='')
        data=Materials::Context.copy(raw,budget,prefix)
        if data.instance_of?(Hash) && data.key?('schema') && data['schema']!=PhysicalState::SCHEMA
          raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED',prefix+'/schema')
        end
        Materials::Context.keys(data,%w[schema design catalog part_policies],prefix)
        design=Record.validate_owned(data['design'],budget,prefix+'/design')
        index=scoped(prefix) { Materials::Catalog.normalize(data['catalog'],budget) }
        policies=policies(data['part_policies'],design,budget,prefix+'/part_policies')
        registry,report=scoped(prefix+'/design') { Materials::Catalog.resolve_owned(design,index,budget) }
        state={'schema'=>PhysicalState::SCHEMA.dup,'design'=>design,'catalog'=>registry,'part_policies'=>policies}
        ProjectCore::Document.new(budget).deep_freeze(state)
        # Preserve submitted positions separately from normalized authoring, so
        # transition diagnostics still address the caller's original arrays.
        positions={policies:{},catalog:{}}
        data['part_policies'].each_with_index do |value,i|
          budget.tick(prefix+'/part_policies');positions[:policies][value['id']]=i
        end
        data['catalog']['entries'].each_with_index do |entry,i|
          budget.tick(prefix+'/catalog/entries');positions[:catalog][[entry['id'],entry['version']]]=i
        end
        [state,report,positions]
      end
      def policies(values,design,budget,path)
        raise ProjectCore::Fault.new('E_INPUT_CONTRACT',path) unless values.instance_of?(Array)
        budget.cap(values.size,:occurrences,path)
        chars={}
        design['construction_requests'].each do |request|
          Construction::Request::ROLES.each do |role|
            budget.tick(path)
            chars[[request['article_instance_id'],role]]=request['panels'][role]
          end
        end
        ids={};seen={};validator=ProjectCore::Document.new(budget)
        (0...values.size).sort_by(&:to_s).each do |i|
          value=values[i];p="#{path}/#{i}"
          budget.tick(p)
          Materials::Context.keys(value,%w[id article_instance_id role grain edges],p)
          validator.check(value['id'],:uuid,p+'/id')
          validator.check(value['article_instance_id'],:uuid,p+'/article_instance_id')
          unless Construction::Request::ROLES.include?(value['role'])
            raise ProjectCore::Fault.new('E_INPUT_CONTRACT',p+'/role')
          end
          key=[value['article_instance_id'],value['role']]
          raise ProjectCore::Fault.new('E_DUPLICATE_ID',p+'/id') if ids.key?(value['id'])
          raise ProjectCore::Fault.new('E_DUPLICATE_ID',p) if seen.key?(key)
          raise ProjectCore::Fault.new('E_REFERENCE_MISSING',p+'/article_instance_id') unless chars.key?(key)
          begin
            Physical::RectangularPart.validate_policies(value,chars[key],budget)
          rescue ProjectCore::Fault => e
            raise ProjectCore::Fault.new(e.code,p+e.json_pointer.delete_prefix('/intent'),e.entity_ref,e.details,e.engine)
          end
          ids[value['id']]=true;seen[key]=value
        end
        unless (chars.keys-seen.keys).empty?
          raise ProjectCore::Fault.new('E_REFERENCE_MISSING',path)
        end
        seen.keys.sort_by { |article,role| [article,Construction::Request::ROLES.index(role)] }.map { |key| seen[key] }
      end
      def check_transition(before,after,budget,positions)
        by_pair={};by_id={}
        before['part_policies'].each do |value|
          budget.tick('/current/part_policies')
          key=[value['article_instance_id'],value['role']]
          by_pair[key]=value['id'];by_id[value['id']]=key
        end
        after['part_policies'].each_with_index do |value,i|
          budget.tick('/replacement/part_policies')
          key=[value['article_instance_id'],value['role']];id=value['id']
          if (by_pair.key?(key) && by_pair[key]!=id) || (by_id.key?(id) && by_id[id]!=key)
            source_index=positions[:policies].fetch(id)
            raise ProjectCore::Fault.new('E_PART_IDENTITY_CONFLICT',"/replacement/part_policies/#{source_index}/id")
          end
        end
        entries={}
        before['catalog']['entries'].each do |entry|
          budget.tick('/current/catalog/entries');entries[[entry['id'],entry['version']]]=entry
        end
        after['catalog']['entries'].each_with_index do |entry,i|
          budget.tick('/replacement/catalog/entries')
          previous=entries[[entry['id'],entry['version']]]
          if previous && !ProjectCore::Revision.semantic_equal?(previous,entry,budget)
            source_index=positions[:catalog].fetch([entry['id'],entry['version']])
            raise ProjectCore::Fault.new('E_MATERIAL_VERSION_CONFLICT',"/replacement/catalog/entries/#{source_index}")
          end
        end
      end
    end
  end
end
