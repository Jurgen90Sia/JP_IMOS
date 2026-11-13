module CoreFixtures
  def uuid(n)
    '00000000-0000-0000-0000-%012d' % n
  end
  def length(n, denominator = 1, exact = true)
    {'type'=>'Length','unit'=>'mm','numeric'=>{'numerator'=>n.to_s,'denominator'=>denominator.to_s,'exact'=>exact}}
  end
  def scalar(n)
    {'type'=>'Scalar','numeric'=>{'numerator'=>n.to_s,'denominator'=>'1','exact'=>true}}
  end
  def boolean(n)
    {'type'=>'Boolean','value'=>n}
  end
  def valid_document
    {'schema'=>'jpimos.project-core/1','project_id'=>uuid(1),'revision'=>7,'locale'=>'sq','units'=>'mm',
      'definitions'=>[{'id'=>uuid(2),'version'=>1,'label'=>'Kuzhinë çeliku',
        'parameters'=>%w[W H D].map { |name| {'name'=>name,'expected_type'=>'Length','default_value'=>nil,'required'=>true} },
        'root_zone_id'=>uuid(3),'zones'=>[leaf(3)],'source_refs'=>[]}],
      'articles'=>[{'id'=>uuid(4),'definition_ref'=>{'id'=>uuid(2),'version'=>1},
        'parameter_values'=>{'W'=>length(600),'H'=>length(720),'D'=>length(560)},
        'origin'=>[length(0),length(0),length(0)]}]}
  end
  def leaf(n)
    {'id'=>uuid(n),'orientation'=>'plan','layout'=>{'kind'=>'leaf'},'children'=>[],'source_refs'=>[]}
  end
end
