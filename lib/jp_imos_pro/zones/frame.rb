# frozen_string_literal: true
module JPImosPro
  module Zones
    module Frame
      IDENTITY=[[1,0,0],[0,1,0],[0,0,1]].map(&:freeze).freeze
      module_function
      def fault
        raise ProjectCore::Fault.new('E_FRAME_UNSUPPORTED')
      end
      def safe(value,budget)
        fault unless value.instance_of?(Integer) || value.instance_of?(Rational)
        budget.tick
        r=value.to_r
        if r.numerator.bit_length>4096 || r.denominator.bit_length>4096
          raise ProjectCore::Fault.new('E_RESOURCE_LIMIT')
        end
        r
      end
      def vector(value,budget)
        fault unless value.instance_of?(Array) && value.size==3
        value.map { |r| safe(r,budget) }
      end
      def validate(frame,budget)
        fault unless frame.instance_of?(Hash) && frame.size==3 && [:origin,:basis,:extents].all? { |k| frame.key?(k) }
        vector(frame[:origin],budget)
        extents=vector(frame[:extents],budget)
        fault unless extents.all? { |r| r>0 }
        basis=frame[:basis]
        fault unless basis.instance_of?(Array) && basis.size==3 && basis.all? { |col| col.instance_of?(Array) && col.size==3 && col.all? { |x| x.instance_of?(Integer) && [-1,0,1].include?(x) } && col.count { |x| x!=0 }==1 }
        fault unless 3.times.all? { |i| basis.count { |col| col[i]!=0 }==1 }
        a,b,c=basis
        determinant=a[0]*(b[1]*c[2]-b[2]*c[1])-b[0]*(a[1]*c[2]-a[2]*c[1])+c[0]*(a[1]*b[2]-a[2]*b[1])
        fault unless determinant==1
      end
      def freeze_frame(origin,basis,extents)
        {origin:origin.freeze,basis:basis.map { |col| col.dup.freeze }.freeze,extents:extents.freeze}.freeze
      end
      def plan(extents:,budget:)
        e=vector(extents,budget)
        fault unless e.all? { |x| x>0 }
        freeze_frame([0.to_r,0.to_r,0.to_r],IDENTITY,e)
      end
      def map_point(frame:,point:,budget:)
        validate(frame,budget)
        p=vector(point,budget)
        3.times.map do |i|
          sum=safe(frame[:origin][i],budget)
          3.times { |j| sum=safe(sum+safe(frame[:basis][j][i]*p[j],budget),budget) }
          sum
        end.freeze
      end
      def orient(frame:,orientation:,budget:)
        validate(frame,budget)
        order,signs,offset=case orientation
        when 'plan' then [[0,1,2],[1,1,1],[0,0,0]]
        when 'front' then [[0,2,1],[1,1,-1],[0,frame[:extents][1],0]]
        when 'left_side' then [[1,2,0],[1,1,1],[0,0,0]]
        else fault
        end
        origin=map_point(frame:frame,point:offset,budget:budget)
        basis=order.each_with_index.map { |j,k| frame[:basis][j].map { |x| x*signs[k] } }
        freeze_frame(origin,basis,order.map { |j| safe(frame[:extents][j],budget) })
      end
      def child(parent:,offset:,extents:,orientation:,budget:)
        local=plan(extents:extents,budget:budget)
        local=freeze_frame(vector(offset,budget),local[:basis],local[:extents])
        local=orient(frame:local,orientation:orientation,budget:budget)
        article_origin=map_point(frame:parent,point:local[:origin],budget:budget)
        basis=local[:basis].map do |col|
          3.times.map { |i| 3.times.sum { |j| parent[:basis][j][i]*col[j] } }
        end
        article=freeze_frame(article_origin,basis,local[:extents].dup)
        {local_frame:local,article_frame:article}.freeze
      end
    end
  end
end
