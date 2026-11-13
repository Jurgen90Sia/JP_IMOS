# frozen_string_literal: true
require 'digest'
require_relative 'project_core'
require_relative 'materials/context'
require_relative 'construction/request'
require_relative 'construction/carcass_rule'
require_relative 'geometry/rectangular_panel'
module JPImosPro
  module Construction
    module_function
    def document(raw,budget)
      ProjectCore::Document.validate(raw,budget)
    rescue ProjectCore::Fault => e
      raise ProjectCore::Fault.new(e.code,'/document'+e.json_pointer,e.entity_ref,e.details,e.engine)
    end
    def zone_snapshot(validated,policy,budget)
      Zones::Resolver.resolve(validated_document:validated,policy:policy,budget:budget)
    rescue ProjectCore::Fault => e
      raise ProjectCore::Fault.new(e.code,'/document'+e.json_pointer,e.entity_ref,e.details,e.engine)
    end
    def build_carcass(document:,request:,numeric_policy:,limits: {})
      policy=nil
      result=ProjectCore.boundary(limits) do |budget|
        authored=self.document(document,budget)
        normalized=Request.validate(request,budget)
        unless authored['articles'].any? { |a| a['id']==normalized['article_instance_id'] }
          raise ProjectCore::Fault.new('E_REFERENCE_MISSING','/request/article_instance_id')
        end
        contexts=Request::ROLES.each_with_object({}) do |role,h|
          h[role]=Materials::Context.resolve(characteristic:normalized['panels'][role],budget:budget,pointer:'/request/panels/'+role)
        end
        policy=ProjectCore.validated_policy(numeric_policy,budget)
        snapshot=zone_snapshot(authored,policy,budget)
        article=snapshot['articles'].find { |a| a['article_instance_id']==normalized['article_instance_id'] }
        rule=CarcassRule.build(article:article,contexts:contexts,budget:budget)
        panels=rule['recipes'].map do |recipe|
          begin
            geometry=Geometry::RectangularPanel.from_recipe(recipe:recipe,budget:budget)
          rescue ProjectCore::Fault => e
            raise ProjectCore::Fault.new(e.code,'/request/panels/'+recipe['role']+e.json_pointer,recipe['occurrence_ref'],e.details,e.engine)
          end
          recipe.merge('geometry'=>geometry)
        end
        audit(panels,rule['reference_envelope'],budget)
        context={'project_id'=>authored['project_id'],'project_revision'=>authored['revision'],
          'project_document_sha256'=>Digest::SHA256.hexdigest(ProjectCore::Codec.encode(authored,budget)),
          'article_instance_id'=>normalized['article_instance_id'],
          'request_sha256'=>Digest::SHA256.hexdigest(ProjectCore::Codec.encode(normalized,budget)),
          'rule_version'=>Request::PRINCIPLE.dup}
        preview={'schema'=>'jpimos.carcass-preview/1','source_context'=>context,'construction_request'=>normalized,
          'article_origin'=>article['origin'],'reference_envelope'=>rule['reference_envelope'],
          'reference_opening'=>rule['reference_opening'],'panels'=>panels,'diagnostics'=>[]}
        ProjectCore::Document.new(budget).deep_freeze(preview)
      end
      result[:metadata]={schema:'jpimos.carcass-preview/1',profile_version:'jp-carcass-preview-v1',rule_version:Request::PRINCIPLE}
      result[:metadata]=result[:metadata].merge(policy) if policy
      result
    end
    def audit(panels,envelope,budget)
      extents=envelope['extents'].map { |v| Zones::EngineBridge.rational(v) }
      boxes=panels.map do |panel|
        budget.tick('/panels')
        geometry=panel['geometry']
        geometry['article_vertices'].each do |point|
          point.each_with_index do |v,i|
            budget.tick('/panels')
            n=Zones::EngineBridge.rational(v)
            unless n>=0 && n<=extents[i]
              raise ProjectCore::Fault.new('E_INVALID_GEOMETRY','/panels',panel['occurrence_ref'])
            end
          end
        end
        [geometry['bbox_min'],geometry['bbox_max']].map { |point| point.map { |v| Zones::EngineBridge.rational(v) } }
      end
      boxes.combination(2) do |a,b|
        overlaps=3.times.map do |i|
          budget.tick('/panels')
          Zones::Frame.safe([[a[1][i],b[1][i]].min-[a[0][i],b[0][i]].max,0].max,budget)
        end
        unless overlaps.any?(&:zero?)
          raise ProjectCore::Fault.new('E_INVALID_GEOMETRY','/panels')
        end
      end
    end
  end
end
