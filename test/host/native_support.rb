# Original standalone SDK double. Never load in an actual SketchUp process.
raise 'SDK double is standalone-only' if defined?(Sketchup::Model)
require 'tmpdir'
require 'fileutils'
module NativeSDKDouble
  IDENTITY=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1].freeze
  class Point
    def initialize(values);@a=values.map(&:to_f);end
    def to_a;@a.dup;end
  end
  class Transform
    attr_accessor :values
    def initialize;@values=IDENTITY.dup;end
    def to_a;@values.dup;end
  end
  class Entity
    attr_accessor :locked,:deleted
    attr_reader :entityID,:transformation
    @@id=0
    def initialize
      @@id+=1;@entityID=@@id;@dictionaries={};@deleted=false;@locked=false;@transformation=Transform.new
    end
    def persistent_id;@entityID;end
    def valid?;!@deleted;end
    def locked?;@locked;end
    def attribute_dictionary(name,create=false);@dictionaries[name]||=(create ? {} : nil);end
    def set_attribute(name,key,value);attribute_dictionary(name,true)[key]=value;value;end
    def get_attribute(name,key,default=nil);(@dictionaries[name]||{}).fetch(key,default);end
  end
  class Vertex < Entity
    attr_accessor :position
    def initialize(coords);super();@position=Point.new(coords);end
  end
  class Edge < Entity
    attr_reader :start,:end,:faces
    def initialize(a,b);super();@start,@end=a,b;@faces=[];end
  end
  class Loop
    attr_reader :vertices
    def initialize(v);@vertices=v;end
  end
  class Face < Entity
    attr_reader :outer_loop
    def initialize(vertices);super();@outer_loop=Loop.new(vertices);end
    def loops;[@outer_loop];end
    def reverse!;@outer_loop=Loop.new(@outer_loop.vertices.reverse);self;end
    def normal
      a,b,c=@outer_loop.vertices.first(3).map { |v| v.position.to_a }
      u=3.times.map { |i| b[i]-a[i] };v=3.times.map { |i| c[i]-a[i] }
      n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
      size=Math.sqrt(n.sum { |x| x*x });Point.new(n.map { |x| x/size })
    end
  end
  class Entities
    include Enumerable
    class << self;attr_accessor :face_limit;end
    attr_reader :items
    def initialize;@items=[];@vertices={};@edges={};end
    def each(&block);return enum_for(:each) unless block;@items.each(&block);end
    def add_group;g=Group.new;@items << g;g;end
    def add_face(points)
      unless Entities.face_limit.nil?
        raise 'synthetic SDK face failure' if Entities.face_limit==0
        Entities.face_limit-=1
      end
      vertices=points.map { |p| a=p.to_a;@vertices[a]||=Vertex.new(a) }
      face=Face.new(vertices)
      # Mimic SDK's special handling of faces created on the ground plane.
      face.reverse! if points.all? { |p| p.to_a[2]==0 } && face.normal.to_a[2]>0
      vertices.each_with_index do |v,i|
        w=vertices[(i+1)%vertices.size];key=[v.entityID,w.entityID].sort
        edge=@edges[key]
        unless edge;edge=Edge.new(v,w);@edges[key]=edge;@items << edge;end
        edge.faces << face
      end
      @items << face;face
    end
    def erase_entities(entity);@items.delete_if { |e| e.equal?(entity) };entity.deleted=true;nil;end
  end
  class LazyEntities < Entities
    attr_reader :yield_count
    def initialize;super;@yield_count=0;end
    def each
      return enum_for(:each) unless block_given?
      loop { @yield_count+=1;yield Entity.new }
    end
  end
  class Definition < Entity
    attr_accessor :instances_count
    attr_reader :entities
    def initialize;super();@entities=Entities.new;@instances_count=1;end
    def count_instances;@instances_count;end
    def behavior;self;end
    def is2d?;false;end
  end
  class Group < Entity
    attr_reader :definition
    def initialize;super();@definition=Definition.new;end
    def entities;@definition.entities;end
    def glued_to;nil;end
    def manifold?
      edges=entities.select { |e| e.is_a?(Edge) };!edges.empty? && edges.all? { |e| e.faces.size==2 }
    end
    def volume
      entities.select { |e| e.is_a?(Face) }.sum do |f|
        p=f.outer_loop.vertices.map { |v| v.position.to_a };a=p[0]
        (1...p.size-1).sum do |i|
          b,c=p[i],p[i+1]
          (a[0]*(b[1]*c[2]-b[2]*c[1])+a[1]*(b[2]*c[0]-b[0]*c[2])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6.0
        end
      end.abs
    end
  end
  class ComponentInstance < Entity
    attr_accessor :definition
    def initialize(definition);super();@definition=definition;end
  end
  class Model < Entity
    attr_reader :entities,:observers,:calls,:path
    attr_accessor :active_path,:commit_hook,:observer_failure
    def initialize;super();@entities=Entities.new;@observers=[];@calls=Hash.new(0);@path='';end
    def modified?;false;end
    def save(path);@path=path;File.binwrite(path,'standalone SDK double, not SKP data');true;end
    def add_observer(o);return false if @observer_failure;@observers << o;true;end
    def remove_observer(o);@observers.delete(o);true;end
    def notify(name)
      @observers.dup.each { |o| o.public_send(name,self) if o.respond_to?(name) }
      @observers.clear if name==:onDeleteModel
    end
    def start_operation(name,disable_ui)
      raise 'nested operation' if @backup
      @calls[:begin]+=1;@backup=Marshal.dump([@entities,@dictionaries]);true
    end
    def commit_operation
      @calls[:commit]+=1;@backup=nil
      notify(:onTransactionStart);notify(:onTransactionCommit);@commit_hook.call if @commit_hook;true
    end
    def abort_operation
      @calls[:abort]+=1;@entities,@dictionaries=Marshal.load(@backup);@backup=nil
      notify(:onTransactionAbort);true
    end
  end
end
module Sketchup
  Model=NativeSDKDouble::Model
  Group=NativeSDKDouble::Group
  ComponentInstance=NativeSDKDouble::ComponentInstance
  Face=NativeSDKDouble::Face
  Edge=NativeSDKDouble::Edge
  class ModelObserver;end
  class AppObserver;end
  class << self
    attr_accessor :active_model
    def version;'21.0.339';end
    def add_observer(o);(@observers||=[]) << o;true;end
    def remove_observer(o);(@observers||=[]).delete(o);true;end
    def app_notice(name,model);(@observers||=[]).dup.each { |o| o.public_send(name,model) if o.respond_to?(name) };end
  end
end
module Geom
  Point3d=NativeSDKDouble::Point
end
