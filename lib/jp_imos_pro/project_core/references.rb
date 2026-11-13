# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    module References
      module_function
      def reject_errors(errors)
        raise errors.min_by(&:json_pointer) unless errors.empty?
      end
      def validate(document,budget)
        index, ids, errors, graphs = {}, {}, [], []
        document['definitions'].each_with_index do |definition,i|
          path="/definitions/#{i}"
          budget.tick(path)
          key=[definition['id'],definition['version']]
          errors << Fault.new('E_DEFINITION_DUPLICATE',path) if index.key?(key)
          index[key] ||= definition
          zones, slots = {}, {}
          definition['zones'].each_with_index do |zone,j|
            zp="#{path}/zones/#{j}"
            budget.tick(zp)
            errors << Fault.new('E_DUPLICATE_ID',zp+'/id') if zones.key?(zone['id'])
            zones[zone['id']] ||= [zone,zp]
            layout=zone['layout']
            collection = layout['kind']=='partition' ? 'slots' : 'placements'
            (layout[collection] || []).each_with_index do |slot,k|
              sp="#{zp}/layout/#{collection}/#{k}"
              budget.tick(sp)
              errors << Fault.new('E_DUPLICATE_ID',sp+'/id') if slots.key?(slot['id'])
              slots[slot['id']] ||= [zone['id'],slot,sp]
            end
          end
          graphs << [definition,path,zones,slots]
        end
        document['articles'].each_with_index do |article,i|
          budget.tick("/articles/#{i}")
          errors << Fault.new('E_DUPLICATE_ID',"/articles/#{i}/id") if ids.key?(article['id'])
          ids[article['id']]=true
        end
        reject_errors(errors)
        occurrences=0
        document['articles'].each_with_index do |article,i|
          ref=article['definition_ref']
          definition=index[[ref['id'],ref['version']]]
          if definition
            occurrences += definition['zones'].size
          else
            errors << Fault.new('E_REFERENCE_MISSING',"/articles/#{i}/definition_ref")
          end
        end
        graphs.each do |definition,path,zones,slots|
          unless zones.key?(definition['root_zone_id'])
            errors << Fault.new('E_REFERENCE_MISSING',path+'/root_zone_id')
          end
          zones.each_value do |zone,zp|
            layout=zone['layout']
            counts=Hash.new(0)
            zone['children'].each_with_index do |child,k|
              budget.tick(zp)
              cp="#{zp}/children/#{k}"
              errors << Fault.new('E_REFERENCE_MISSING',cp+'/zone_id') unless zones.key?(child['zone_id'])
              slot=slots[child['slot_id']]
              if !slot || slot[0] != zone['id']
                errors << Fault.new('E_REFERENCE_MISSING',cp+'/slot_id')
              else
                counts[child['slot_id']] += 1
                if layout['kind']=='partition' && slot[1]['role'] != 'zone'
                  errors << Fault.new('E_INPUT_CONTRACT',cp+'/slot_id')
                end
              end
            end
            if layout['kind']=='leaf' && !zone['children'].empty?
              errors << Fault.new('E_INPUT_CONTRACT',zp+'/children')
            end
            collection=layout['kind']=='partition' ? 'slots' : 'placements'
            (layout[collection] || []).each do |slot|
              needed=layout['kind']!='partition' || slot['role']=='zone'
              if needed && counts[slot['id']]==0
                errors << Fault.new('E_REFERENCE_MISSING',zp+'/children')
              elsif needed && counts[slot['id']] > 1
                errors << Fault.new('E_INPUT_CONTRACT',zp+'/children')
              end
            end
          end
        end
        reject_errors(errors)
        budget.cap(occurrences,:occurrences,'/articles')
        graphs.each { |definition,path,zones,_slots| topology(definition,path,zones,budget) }
        index
      end
      def topology(definition,path,zones,budget)
        parents=Hash.new { |h,key| h[key]=[] }
        zones.each_value do |zone,zp|
          zone['children'].each_with_index do |child,i|
            budget.tick(zp)
            parents[child['zone_id']] << "#{zp}/children/#{i}/zone_id"
          end
        end
        multiple=parents.values.select { |p| p.size>1 }.map { |p| Fault.new('E_ZONE_MULTIPLE_PARENTS',p.sort[1]) }
        reject_errors(multiple)
        states={}
        zones.keys.sort.each do |start|
          next if states[start]==2
          stack=[[:enter,start]]
          until stack.empty?
            action,id=stack.pop
            zone,zp=zones.fetch(id)
            budget.tick(zp)
            if action==:leave
              states[id]=2
            elsif states[id]==1
              raise Fault.new('E_ZONE_CYCLE',zp,{'zone_id'=>id})
            elsif states[id]!=2
              states[id]=1
              stack << [:leave,id]
              zone['children'].reverse_each { |child| stack << [:enter,child['zone_id']] }
            end
          end
        end
        root=definition['root_zone_id']
        unless parents[root].empty?
          raise Fault.new('E_INPUT_CONTRACT',path+'/root_zone_id')
        end
        visited={}
        stack=[[root,1]]
        until stack.empty?
          id,depth=stack.pop
          zone,zp=zones.fetch(id)
          budget.tick(zp)
          budget.cap(depth,:zone_depth,zp)
          visited[id]=true
          zone['children'].reverse_each { |child| stack << [child['zone_id'],depth+1] }
        end
        unreachable=(zones.keys-visited.keys).map { |id| Fault.new('E_ZONE_UNREACHABLE',zones[id][1]) }
        reject_errors(unreachable)
      end
    end
  end
end
