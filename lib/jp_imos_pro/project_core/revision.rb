# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    module Revision
      module_function
      def validate(document,prefix,budget)
        Document.validate(document,budget)
      rescue Fault => e
        raise Fault.new(e.code,prefix+e.json_pointer,e.entity_ref,e.details,e.engine)
      end
      def current(document,expected,budget)
        result=validate(document,'/current',budget)
        unless expected.instance_of?(Integer) && expected.between?(0,Document::SAFE_INTEGER)
          raise Fault.new('E_INPUT_CONTRACT','/expected_revision')
        end
        unless expected==result['revision']
          raise Fault.new('E_REVISION_CONFLICT','/expected_revision',nil,{current_revision:result['revision'],expected_revision:expected})
        end
        if result['revision']==Document::SAFE_INTEGER
          raise Fault.new('E_REVISION_EXHAUSTED','/current/revision')
        end
        result
      end
      def replacement(current,document,budget)
        result=validate(document,'/replacement',budget)
        %w[project_id revision].each do |key|
          raise Fault.new('E_REVISION_CONFLICT','/replacement/'+key) unless result[key]==current[key]
        end
        definitions={}
        current['definitions'].each do |definition|
          budget.tick('/current/definitions')
          definitions[[definition['id'],definition['version']]]=definition
        end
        (0...result['definitions'].size).sort_by { |i| i.to_s }.each do |i|
          definition=result['definitions'][i]
          key=[definition['id'],definition['version']]
          if definitions.key?(key) && !semantic_equal?(definitions[key],definition,budget)
            raise Fault.new('E_DEFINITION_DUPLICATE',"/replacement/definitions/#{i}",nil,{id:key[0],version:key[1]})
          end
        end
        raise Fault.new('E_NO_CHANGE','/replacement') if semantic_equal?(current,result,budget)
        result
      end
      # Called only after both trees have been copied/closed-schema validated.
      # Hash order is not semantic; array order is. No JSON or host callbacks.
      def semantic_equal?(left,right,budget)
        stack=[[left,right]]
        until stack.empty?
          a,b=stack.pop
          budget.tick('/replacement')
          return false unless a.class==b.class
          if a.instance_of?(Hash)
            return false unless a.size==b.size && (a.keys-b.keys).empty?
            budget.tick('/replacement',a.size)
            a.each { |key,value| stack << [value,b.fetch(key)] }
          elsif a.instance_of?(Array)
            return false unless a.size==b.size
            budget.tick('/replacement',a.size)
            a.each_with_index { |value,i| stack << [value,b[i]] }
          else
            return false unless a==b
          end
        end
        true
      end
      def candidate_snapshot(candidate,policy,budget)
        Zones::Resolver.resolve(validated_document:candidate,policy:policy,budget:budget)
      rescue Fault => e
        raise Fault.new(e.code,'/replacement'+e.json_pointer,e.entity_ref,e.details,e.engine)
      end
    end
  end
end
