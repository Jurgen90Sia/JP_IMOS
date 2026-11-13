require_relative '../zones/fixtures'
module CarcassFixtures
  include ZoneFixtures
  def characteristic(substrate=18,nominal=19)
    {'policy'=>'additive_finished_stack-v1','material_ref'=>{'id'=>uuid(900),'version'=>1},
      'nominal_purchase_thickness'=>length(nominal),'finished_substrate_thickness'=>length(substrate),'dimensional_surfaces'=>[]}
  end
  def surface(side,n,d=1)
    {'side'=>side,'material_ref'=>{'id'=>uuid(901),'version'=>1},'finished_thickness'=>length(n,d)}
  end
  def request
    {'schema'=>'jpimos.carcass-request/1','article_instance_id'=>uuid(4),'principle'=>'top_bottom_between_sides-v1',
      'panels'=>%w[left right top bottom].each_with_object({}) { |role,h| h[role]=characteristic }}
  end
end
