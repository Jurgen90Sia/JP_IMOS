# frozen_string_literal: true
require_relative 'application'
module JPImosPro
  module Host
    module NativeGeometry
      DICTIONARY='JP_IMOS_PRO_HOST_V1_EXPERIMENTAL'
      TAG_SCHEMA='jpimos.host-entity/1'
      IDENTITY=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1].freeze
      EPS=0.001
      module_function
      def fail!(path='/host/entities',geometry=false)
        raise ProjectCore::Fault.new(geometry ? 'E_HOST_GEOMETRY_CONFLICT' : 'E_HOST_OWNERSHIP_CONFLICT',path)
      end
      def core(budget)
        value=budget.core_budget
        raise ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/budget') unless value.instance_of?(ProjectCore::CoreBudget)
        value
      end
      def tag(entity,budget)
        dictionary=entity.attribute_dictionary(DICTIONARY,false)
        return nil unless dictionary
        raw=nil;count=0
        dictionary.each_pair do |key,value|
          budget.tick;count+=1
          fail! unless count==1 && key=='binding_json' && value.instance_of?(String) && value.bytesize<=1024
          raw=value
        end
        fail! unless raw
        begin
          value=ProjectCore::Codec.parse(raw,core(budget))
          value=ProjectCore::Document.new(core(budget)).copy(value)
        rescue ProjectCore::Fault => error
          raise if error.code=='E_RESOURCE_LIMIT'
          fail!
        end
        fail! unless value.instance_of?(Hash) && value['schema']==TAG_SCHEMA
        value
      end
      def root_tag(root_id,project_id);{'schema'=>TAG_SCHEMA,'kind'=>'root','root_id'=>root_id,'project_id'=>project_id};end
      def part_tag(root_id,part_id);{'schema'=>TAG_SCHEMA,'kind'=>'part','root_id'=>root_id,'part_id'=>part_id};end
      def solid_tag(root_id,part_id,solid)
        {'schema'=>TAG_SCHEMA,'kind'=>'solid','root_id'=>root_id,'part_id'=>part_id,'component'=>solid['component'],'source_index'=>solid['source_index']}
      end
      def write_tag(entity,value,budget)
        owned=ProjectCore::Document.new(core(budget)).copy(value)
        entity.set_attribute(DICTIONARY,'binding_json',ProjectCore::Codec.encode(owned,core(budget)))
      end
      # Enumerator frames and one active-definition set keep allocations linear
      # in visits/depth. Never materialize an arbitrary Entities collection.
      def scan(model,budget,excluded=nil)
        entries={}.compare_by_identity;active={}
        stack=[[model.entities.enum_for(:each),nil,nil]]
        until stack.empty?
          begin
            entity=stack[-1][0].next
          rescue StopIteration
            _,_,definition=stack.pop;active.delete(definition) if definition
            next
          end
          budget.tick
          fail! unless entity.valid?
          next if entity.equal?(excluded)
          value=tag(entity,budget)
          entries[entity]=[value,stack[-1][1]] if value
          if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            definition=entity.definition
            identity=definition.entityID
            fail! if active.key?(identity)
            active[identity]=true
            children=entity.is_a?(Sketchup::Group) ? entity.entities : definition.entities
            stack << [children.enum_for(:each),entity,identity]
          end
        end
        entries
      end
      def group(entity,budget)
        budget.tick
        fail! unless entity.is_a?(Sketchup::Group) && entity.valid? && !entity.locked? && entity.definition.count_instances==1
        fail! if entity.definition.behavior.is2d?
        fail! if entity.respond_to?(:glued_to) && !entity.glued_to.nil?
        fail!('/host/transform',true) unless entity.transformation.to_a==IDENTITY
      end
      def children(entity,expected,budget)
        values=[]
        entity.entities.each do |child|
          budget.tick
          fail! unless child.is_a?(Sketchup::Group) && values.size<expected
          values << child
        end
        fail! unless values.size==expected
        values
      end
      def dot(a,b);3.times.sum { |i| a[i]*b[i] };end
      def normal(points)
        a,b,c=points.first(3);u=3.times.map { |i| b[i]-a[i] };v=3.times.map { |i| c[i]-a[i] }
        [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
      end
      def points(solid)
        solid['world_vertices'].map { |p| p.map { |v| Zones::EngineBridge.rational(v).to_f } }
      end
      def inspect_solid(entity,solid,budget)
        faces=[];edges=[]
        entity.entities.each do |item|
          budget.tick
          if item.is_a?(Sketchup::Face)
            fail!('/host/topology',true) if faces.size>=6
            faces << item
          elsif item.is_a?(Sketchup::Edge)
            fail!('/host/topology',true) if edges.size>=12
            edges << item
          else
            fail!
          end
        end
        fail!('/host/topology',true) unless faces.size==6 && edges.size==12 && entity.manifold?
        expected=points(solid);vertices={};mapping={};used={}
        edges.each do |edge|
          fail!('/host/topology',true) unless edge.faces.size==2
          [edge.start,edge.end].each do |vertex|
            budget.tick
            next if vertices.key?(vertex.entityID)
            fail!('/host/topology',true) if vertices.size>=8
            p=vertex.position.to_a.map { |n| n.to_f*25.4 }
            fail!('/host/vertices',true) unless p.size==3 && p.all?(&:finite?)
            matches=(0...8).select { |i| 3.times.all? { |j| (p[j]-expected[i][j]).abs<=EPS } }
            fail!('/host/vertices',true) unless matches.size==1 && !used[matches[0]]
            used[matches[0]]=true;vertices[vertex.entityID]=vertex;mapping[vertex.entityID]=matches[0]
          end
        end
        fail!('/host/vertices',true) unless vertices.size==8
        wanted=solid['face_loops'].values;seen=[]
        faces.each do |face|
          budget.tick
          fail!('/host/faces',true) unless face.loops.size==1 && face.outer_loop.vertices.size==4
          loop_indices=face.outer_loop.vertices.map { |vertex| mapping[vertex.entityID] }
          hits=wanted.each_index.select { |i| 4.times.any? { |r| loop_indices.rotate(r)==wanted[i] } }
          fail!('/host/faces',true) unless hits.size==1 && !seen.include?(hits[0])
          seen << hits[0]
          n=face.normal.to_a
          fail!('/host/normals',true) unless n.size==3 && n.all?(&:finite?) && dot(n,normal(wanted[hits[0]].map { |i| expected[i] }))>0
        end
        wanted_edges=wanted.flat_map { |f| f.each_index.map { |i| [f[i],f[(i+1)%4]].sort } }.uniq.sort
        actual_edges=edges.map { |edge| [mapping[edge.start.entityID],mapping[edge.end.entityID]].sort }.sort
        fail!('/host/edges',true) unless actual_edges==wanted_edges
        volume=entity.volume.to_f*(25.4**3)
        target=Zones::EngineBridge.rational(solid['expected_volume']).to_f
        fail!('/host/volume',true) unless volume.finite? && volume>0 && (volume-target).abs<=[1e-6,target*1e-8].max
      end
      def inspect(model,plan,root_id,manifest,budget,staging=nil)
        excluded=staging && staging[:old_root]
        entries=scan(model,budget,excluded)
        if plan.nil? || plan['parts'].empty?
          fail! unless entries.empty?
          return Inspection.from_port(root_handle:nil,manifest:nil)
        end
        roots=entries.select { |_,entry| entry==[root_tag(root_id,plan['project_id']),nil] }.keys
        fail! unless roots.size==1
        root=roots[0];fail! if staging && !root.equal?(staging[:new_root])
        group(root,budget);used=[root]
        part_children=children(root,plan['parts'].size,budget)
        mapped=plan['parts'].map do |part|
          begin
            found=part_children.select { |child| entries[child]==[part_tag(root_id,part['part_id']),root] }
            fail! unless found.size==1
            container=found[0];group(container,budget);used << container
            solid_children=children(container,part['solids'].size,budget)
            solids=part['solids'].map do |solid|
              found=solid_children.select { |child| entries[child]==[solid_tag(root_id,part['part_id'],solid),container] }
              fail! unless found.size==1
              item=found[0];group(item,budget);used << item
              inspect_solid(item,solid,budget)
              {'component'=>solid['component'],'source_index'=>solid['source_index'],'pid_hint'=>item.persistent_id.to_s}
            end
            {'part_id'=>part['part_id'],'container_pid_hint'=>container.persistent_id.to_s,'solids'=>solids}
          rescue ProjectCore::Fault => error
            reference=error.entity_ref || {'part_id'=>part['part_id']}
            path='/host/parts/'+part['part_id']+error.json_pointer.delete_prefix('/host')
            raise ProjectCore::Fault.new(error.code,path,reference,error.details,error.engine)
          end
        end
        fail! unless entries.size==used.size && used.all? { |entity| entries.key?(entity) }
        observed={'schema'=>DocumentCodec::MANIFEST_SCHEMA.dup,'plan_sha256'=>manifest['plan_sha256'],'root_pid_hint'=>root.persistent_id.to_s,'parts'=>mapped}
        Inspection.from_port(root_handle:root,manifest:observed)
      end
      def add_group(entities,tag_value,budget)
        budget.tick
        value=entities.add_group
        write_tag(value,tag_value,budget)
        value
      end
      def stage(model,projection,root_id,budget)
        return nil if projection.plan['parts'].empty?
        root=add_group(model.entities,root_tag(root_id,projection.plan['project_id']),budget)
        projection.plan['parts'].each do |part|
          container=add_group(root.entities,part_tag(root_id,part['part_id']),budget)
          part['solids'].each do |solid|
            group=add_group(container.entities,solid_tag(root_id,part['part_id'],solid),budget)
            positions=points(solid)
            native=positions.map { |p| budget.tick;Geom::Point3d.new(p.map { |v| v/25.4 }) }
            solid['face_loops'].each_value do |loop_indices|
              budget.tick(5) # Face and possible edge allocations charged first.
              face=group.entities.add_face(loop_indices.map { |i| native[i] })
              fail!('/host/create_face',true) unless face
              face.reverse! if dot(face.normal.to_a,normal(loop_indices.map { |i| positions[i] }))<0
            end
          end
        end
        root
      end
    end
  end
end
