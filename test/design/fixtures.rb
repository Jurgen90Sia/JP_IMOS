require_relative '../construction/fixtures'
module DesignFixtures
  include CarcassFixtures
  def design_state
    {'schema'=>'jpimos.carcass-design/1','project'=>valid_document,'construction_requests'=>[request]}
  end
end
