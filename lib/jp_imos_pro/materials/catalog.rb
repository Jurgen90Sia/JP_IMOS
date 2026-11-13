# frozen_string_literal: true
require_relative '../design'
module JPImosPro
  module Materials
    module Catalog
      SCHEMA='jpimos.material-catalog/1'
      module_function
      def normalize(raw,budget)
        data=Context.copy(raw,budget,'/catalog')
        Context.keys(data,%w[schema entries],'/catalog')
        raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED','/catalog/schema') unless data['schema']==SCHEMA
        unless data['entries'].instance_of?(Array)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/catalog/entries')
        end
        budget.cap(data['entries'].size,:occurrences,'/catalog/entries')
        validator=ProjectCore::Document.new(budget)
        index={}
        data['entries'].each_with_index do |entry,i|
          p="/catalog/entries/#{i}"
          budget.tick(p)
          Context.keys(entry,%w[id version label category provenance],p)
          ref=Context.material({'id'=>entry['id'],'version'=>entry['version']},budget,p)
          label=validator.check(entry['label'],:label,p+'/label')
          unless %w[panel surface].include?(entry['category'])
            raise ProjectCore::Fault.new('E_INPUT_CONTRACT',p+'/category')
          end
          Context.keys(entry['provenance'],%w[kind note],p+'/provenance')
          unless entry['provenance']['kind']=='user_declared'
            raise ProjectCore::Fault.new('E_INPUT_CONTRACT',p+'/provenance/kind')
          end
          note=validator.check(entry['provenance']['note'],:label,p+'/provenance/note')
          key=[ref['id'],ref['version']]
          raise ProjectCore::Fault.new('E_DUPLICATE_ID',p) if index.key?(key)
          index[key]={'id'=>ref['id'],'version'=>ref['version'],'label'=>label,'category'=>entry['category'],
            'provenance'=>{'kind'=>'user_declared','note'=>note}}
        end
        index
      end
      # Trusted owned records only. Public boundaries validate and share their
      # budget before invoking this helper; imported reports never select it.
      def resolve_owned(owned,index,budget)
          bindings=[]
          owned['construction_requests'].each_with_index do |request,i|
            Construction::Request::ROLES.each do |role|
              characteristic=request['panels'][role]
              path="/construction_requests/#{i}/panels/#{role}"
              refs=[[characteristic['material_ref'],'panel',path+'/material_ref']]
              characteristic['dimensional_surfaces'].each_with_index do |layer,j|
                refs << [layer['material_ref'],'surface',"#{path}/dimensional_surfaces/#{j}/material_ref"]
              end
              refs.each do |ref,category,pointer|
                budget.tick(pointer)
                entry=index[[ref['id'],ref['version']]]
                raise ProjectCore::Fault.new('E_MATERIAL_REFERENCE_UNRESOLVED',pointer) unless entry
                unless entry['category']==category
                  raise ProjectCore::Fault.new('E_MATERIAL_CATEGORY_MISMATCH',pointer)
                end
                bindings << {'article_instance_id'=>request['article_instance_id'],'role'=>role,'json_pointer'=>pointer,'material'=>entry}
              end
            end
          end
          # Bind the complete state and registry; this report is not accepted
          # geometry and must not upgrade an existing preview's status.
          normalized={'schema'=>SCHEMA.dup,'entries'=>index.values.sort_by { |e| [e['id'],e['version']] }}
          report={'schema'=>'jpimos.material-reference-report/1','status'=>'registry_resolved_user_declared',
            'project_id'=>owned['project']['project_id'],'source_revision'=>owned['project']['revision'],
            'state_sha256'=>Digest::SHA256.hexdigest(ProjectCore::Codec.encode(owned,budget)),
            'catalog_sha256'=>Digest::SHA256.hexdigest(ProjectCore::Codec.encode(normalized,budget)),
            'bindings'=>bindings,'diagnostics'=>[]}
          validator=ProjectCore::Document.new(budget)
          validator.deep_freeze(normalized)
          validator.deep_freeze(report)
          [normalized,report]
      end
      def verify_references(state:,catalog:,limits: {})
        result=ProjectCore.boundary(limits) do |budget|
          owned=Design::Record.validate(state,budget)
          index=normalize(catalog,budget)
          resolve_owned(owned,index,budget)[1]
        end
        result[:metadata]={schema:'jpimos.material-reference-report/1',profile_version:'jp-user-material-registry-v1'}
        result
      end
    end
  end
end
