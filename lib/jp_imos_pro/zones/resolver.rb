# frozen_string_literal: true
module JPImosPro
  module Zones
    class Resolver
      ALGORITHM='jp-rectangular-zones-v1'
      def self.resolve(validated_document:,policy:,budget:)
        new(validated_document,policy,budget).resolve
      end
      def initialize(document,policy,budget)
        @document,@policy,@budget=document,policy,budget
        @zones,@articles,@errors=[],[],[]
      end
      def ref(article,zone)
        {'article_instance_id'=>article['id'],'authored_zone_id'=>zone['id']}
      end
      def lengths(values)
        values.map { |r| EngineBridge.length(r) }
      end
      def resolve
        definitions={}
        @document['definitions'].each_with_index { |d,i| @budget.tick; definitions[[d['id'],d['version']]]=[d,i] }
        @document['articles'].each_with_index do |article,i|
          @budget.tick("/articles/#{i}")
          definition,di=definitions.fetch([article['definition_ref']['id'],article['definition_ref']['version']])
          bindings=ProjectCore::Parameters.bind(article,definition,"/articles/#{i}",@budget)
          base_symbols=bindings.each_with_object({}) { |(k,v),h| h[k]=EngineBridge.engine_dto(v,@budget) }
          extents=%w[W D H].map { |name| EngineBridge.rational(bindings[name]) }
          plan=Frame.plan(extents:extents,budget:@budget)
          zones=definition['zones'].each_with_index.each_with_object({}) { |(z,j),h| h[z['id']]=[z,j] }
          root=zones.fetch(definition['root_zone_id'])[0]
          @articles << {'article_instance_id'=>article['id'],'definition_ref'=>article['definition_ref'],
            'origin'=>article['origin'],'reference_extents'=>lengths(extents),'root_occurrence_ref'=>ref(article,root)}
          stack=[[root['id'],nil,plan,[0,0,0],extents,1]]
          until stack.empty?
            id,parent_ref,parent_frame,offset,child_extents,depth=stack.pop
            zone,zi=zones.fetch(id)
            pointer="/definitions/#{di}/zones/#{zi}"
            occurrence=ref(article,zone)
            begin
              @budget.tick(pointer)
              @budget.cap(depth,:zone_depth,pointer)
              @budget.cap(@zones.size+1,:occurrences,pointer)
              frames=Frame.child(parent:parent_frame,offset:offset,extents:child_extents,orientation:zone['orientation'],budget:@budget)
              frame=frames[:article_frame]
              symbols=base_symbols.dup
              %w[ZONE_U ZONE_V ZONE_W].each_with_index { |name,k| symbols[name]=EngineBridge.engine_dto(EngineBridge.length(frame[:extents][k]),@budget) }
              occupied,child_boxes=layout(zone,frame,symbols,pointer,occurrence)
              @zones << {'occurrence_ref'=>occurrence,'parent_occurrence_ref'=>parent_ref,'source_definition_ref'=>article['definition_ref'],
                'authored_zone_id'=>zone['id'],'local_origin_in_parent'=>lengths(frames[:local_frame][:origin]),
                'local_basis_in_parent'=>frames[:local_frame][:basis],'local_extents'=>lengths(frame[:extents]),
                'article_origin'=>lengths(frame[:origin]),'article_basis'=>frame[:basis],
                'occupied_slots'=>occupied,'child_occurrence_refs'=>zone['children'].map { |link| ref(article,zones.fetch(link['zone_id'])[0]) }}
              zone['children'].reverse_each do |link|
                box=child_boxes.fetch(link['slot_id'])
                stack << [link['zone_id'],occurrence,frame,box[:offset],box[:extents],depth+1]
              end
            rescue ProjectCore::Fault => e
              error=ProjectCore::Fault.new(e.code,e.json_pointer.empty? ? pointer : e.json_pointer,e.entity_ref || occurrence,e.details,e.engine)
              raise error if error.code=='E_RESOURCE_LIMIT'
              @errors << error
            end
          end
        end
        unless @errors.empty?
          raise @errors.min_by { |e| [e.json_pointer,e.entity_ref['article_instance_id'],e.entity_ref['authored_zone_id']] }
        end
        snapshot={'schema'=>'jpimos.zone-snapshot/1','project_id'=>@document['project_id'],'source_revision'=>@document['revision'],
          'algorithm_version'=>ALGORITHM,'policy_id'=>@policy[:policy_id].dup,'backend_id'=>@policy[:backend_id].dup,
          'articles'=>@articles,'zones'=>@zones,'diagnostics'=>[]}
        ProjectCore::Document.new(@budget).deep_freeze(snapshot)
      end
      def layout(zone,frame,symbols,pointer,occurrence)
        layout=zone['layout']
        return [[],{}] if layout['kind']=='leaf'
        unless layout['kind']=='partition'
          raise ProjectCore::Fault.new('E_UNSUPPORTED_GRAMMAR',pointer+'/layout',occurrence)
        end
        axis=%w[u v w].index(layout['axis'])
        result=EngineBridge.division(spec:layout['expression'],length:frame[:extents][axis],symbols:symbols,
          pointer:pointer+'/layout/expression/source',occurrence_ref:occurrence,policy:@policy,budget:@budget)
        terms=result[:expanded_terms]
        if terms.size!=layout['slots'].size
          raise ProjectCore::Fault.new('E_ZONE_TOPOLOGY_CHANGED',pointer+'/layout/slots',occurrence)
        end
        position=0.to_r
        occupied,boxes=[],{}
        layout['slots'].each_with_index do |slot,k|
          @budget.tick(pointer)
          length=EngineBridge.rational(EngineBridge.string_dto(terms[k][:length]))
          ending=Frame.safe(position+length,@budget)
          occupied << {'slot_id'=>slot['id'],'role'=>slot['role'],'axis'=>layout['axis'],
            'start'=>EngineBridge.length(position),'end'=>EngineBridge.length(ending),'length'=>EngineBridge.length(length)}
          if slot['role']=='zone'
            offset=[0.to_r,0.to_r,0.to_r]; offset[axis]=position
            extents=frame[:extents].dup; extents[axis]=length
            boxes[slot['id']]={offset:offset,extents:extents}
          end
          position=ending
        end
        [occupied,boxes]
      end
    end
  end
end
