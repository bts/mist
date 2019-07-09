-- Monadic Interface
ret as forall a. wr:Int ~> x:a -> ST <{ri:Int|ri==wr} >{ro:Int|ro==wr} >a
ret = 0

thenn as w1:Int ~> w2:Int ~> w3:Int ~> (ST <{v:Int|v==w1} >{v:Int|v==w2} >Unit)
  -> (ST <{v:Int|v==w2} >{v:Int|v==w3} >Int)
  -> ST <{v:Int|v==w1} >{v:Int|v==w3} >Int
thenn = 0

bind as forall a, b. w1:Int ~> w2:Int ~> w3:Int ~> (ST <{v:Int|v==w1} >{v:Int|v==w2} >a)
  -> (unused:a -> ST <{v:Int|v==w2} >{v:Int|v==w3} >b)
  -> ST <{v:Int|v==w1} >{v:Int|v==w3} >b
bind = 0

get as wg:Int ~> Bool -> ST <{gi:Int|gi==wg} >{go:Int|go==wg} >{gr:Int|gr==wg}
get = True

put as wp:Int -> ST <Int >{p:Int|p==wp} >Unit
put = 0

-- incr
incr :: ST <{i:Int|i==2} >{w:Int|w==3} >Unit
incr = bind (get True) (\x -> put (x+1))
