require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/host/document_codec'
require_relative '../design/fixtures'
%w[registry lease reader preparation recovery].each do |name|
  path=File.expand_path("../../lib/jp_imos_pro/host/#{name}.rb",__dir__)
  require path if File.exist?(path)
end
require_relative 'tree_port'

module HostSessionSupport
  include PhysicalDesignFixtures
  def setup
    return unless defined?(JPImosPro::Host::Registry)
    @model=HostTreeModel.new;@anchor=JPImosPro::Host::Registry.open(model:@model)
    @port=HostTreePort.new(@model,@anchor)
    @context=JPImosPro::Host::Registry.attach(port:@port)
  end
  def teardown
    JPImosPro::Host::Registry.close(anchor:@anchor) if @anchor
  end
  def read(context=@context,limits={})
    context.port.settle(context)
    JPImosPro::Host::Reader.read(context:context,numeric_policy:policy,limits:limits)
  end
  def lease
    r=read;assert r[:ok],r[:diagnostics].inspect;r[:value]
  end
  def initial(l=lease,state=physical_state,limits={})
    JPImosPro::Host::Preparation.initial(lease:l,state:state,numeric_policy:policy,limits:limits)
  end
  def candidate
    r=initial;assert r[:ok],r[:diagnostics].inspect;r[:value]
  end
  def accepted(state=physical_state)
    @port.install_fixture(state,policy,uuid(2000),uuid(2001));lease
  end
  def revision(l,replacement=physical_state,expected=7,p=policy)
    JPImosPro::Host::Preparation.revision(lease:l,replacement:replacement,expected_revision:expected,numeric_policy:p)
  end
  def resize
    state=physical_state;state['design']['project']['articles'][0]['parameter_values']['W']=length(800);state
  end
end
