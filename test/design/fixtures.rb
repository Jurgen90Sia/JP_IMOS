require_relative '../construction/fixtures'
module DesignFixtures
  include CarcassFixtures
  def design_state
    {'schema'=>'jpimos.carcass-design/1','project'=>valid_document,'construction_requests'=>[request]}
  end
end
module PhysicalDesignFixtures
  include DesignFixtures
  def physical_state
    {'schema'=>'jpimos.physical-design/1','design'=>design_state,
      'catalog'=>{'schema'=>'jpimos.material-catalog/1','entries'=>[
        {'id'=>uuid(900),'version'=>1,'label'=>'Synthetic panel','category'=>'panel','provenance'=>{'kind'=>'user_declared','note'=>''}}]},
      'part_policies'=>%w[left right top bottom].each_with_index.map do |role,i|
        {'id'=>uuid(1000+i),'article_instance_id'=>uuid(4),'role'=>role,
          'grain'=>{'substrate'=>'u','surfaces'=>[]},'edges'=>%w[u_min u_max v_min v_max].to_h { |edge| [edge,{'kind'=>'none'}] }}
      end}
  end
end
