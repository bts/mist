incr :: x:Int -> {v:Int | v == x + 1}
incr = ( \x -> x + 1 )

moo :: {v:Int | v == 8}
moo = ( incr 7 )

id :: forall a. (a -> a)
id = ( \x -> x )

bar :: {v:Int | v == 8}
bar = ( incr (id 7) )