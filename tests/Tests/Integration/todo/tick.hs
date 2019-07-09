{-

data Tick t a = Tick a
type T w a = T {v|v=w} a

pure :: x -> T 0 a
pure x = Tick x

</> :: t1 t2 -> T t1 (a -> b) -> T t2 a -> T (t1 + t2) b
Tick f </> Tick x = Tick (f x)

(++) :: xs:[a] -> ys:[a] -> T (len xs) {v|v=len xs + len ys}
[] ++ ys = pure ys
(x:xs') ++ ys = pure (x:) </> (xs' ++ ys)

(<*>) as forall a, b. t1:Int ~> t2: Int ~>
         Tick {v | v = t1} (a -> b)
      -> Tick {v | v = t2} a
      -> Tick {v | v = t1 + t2} b
Tick f <*> Tick x = Tick (f x)

(>>=) as forall a, b. t1:Int ~> t2: Int ~>
         Tick {v | v = t1} a
      -> (a -> Tick {v | v = t2} b)
      -> Tick {v | v = t1 + t2} b

step as forall a. t1:Int ~>
     -> m: Int
     -> Tick {v | v = t1} a
     -> Tick {v | v = t1 + m} a
step m (Tick x) = Tick x

(</>) as forall a, b. t1:Int ~> t2:Int
      -> Tick {v | v = t1} (a -> b)
      -> Tick {v | v = t2} a
      -> Tick {v | v = t1 + t2 + 1} b
(</>) = (<*>)

(++) :: forall a.
     -> xs: [a]
     -> ys: [a]
     -> Tick {v | v = length xs} {v | v = length xs + length ys}
[] ++ ys = pure ys
(x:xs') ++ ys = pure (x:) </> (xs' ++ ys)

reverse :: xs:[a] -> Tick {v | v = ((length xs * length xs) / 2) + ((length xs + 1) / 2)} [a]
reverse [] = pure []
reverse (x:xs) = reverse xs >>= (++ [x])
-}
