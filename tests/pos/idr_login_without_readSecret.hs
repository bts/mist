-- https://github.com/idris-lang/Idris-dev/blob/master/samples/ST/Intro.idr

undefined as rforall a. a
undefined = 0

assert :: {v:Bool | v} -> Unit
assert = \tru -> Unit
-----------------------------------------------------------------------------
-- | Library ----------------------------------------------------------------
-----------------------------------------------------------------------------
bind :: rforall a, b, p, q, r.
  ST <p >q >a ->
  (x:a -> ST <q >r >b) ->
  ST <p >r >b
bind = undefined

thenn :: rforall a, b, p, q, r.
  ST <p >q >a
  -> ST <q >r >b
  -> ST <p >r >b
thenn = undefined

pure :: rforall a, p, q.  x:a -> ST <p >q >a
pure = undefined

getStr :: rforall p, q. ST <p >q >Int
getStr = undefined

-- | Some opaque implementation of pointers to `Int` ------------------------

-- | Allocating a fresh `Int` with value `0`
new :: rforall a. ST <a >a >Int
new = undefined

read :: hg:(Map <Int >Int) ~> p:Int -> ST <{h:Map <Int >Int | h == hg} >{h:Map <Int >Int | h == hg} >{v:Int| v == select hg p}
read = undefined

write :: h:(Map <Int >Int) ~> p:Int -> v:Int -> ST <{hg:Map <Int >Int | h == hg} >{hg:Map <Int >Int | store h p v == hg} >Unit
write = undefined

-----------------------------------------------------------------------------
-- Interface to the server
-- data Int = LoggedOut | LoggedIn
loggedOut as Int
loggedOut = 0
loggedIn as Int
loggedIn = 1

-- data LoginResult = OK | BadPassword
oK as LoginResult
oK = 0
badPassword as LoginResult
badPassword = 1

{-
login :: (store : Var) ->
        ST m LoginResult [store ::: Store LoggedOut :->
                           (\res => Store (case res of
                                                OK => LoggedIn
                                                BadPassword => LoggedOut))]
login store = do putStr "Enter password: "
                 p <- getStr
                 if p == "Mornington Crescent"
                    then pure OK
                    else pure BadPassword
                    -}

-- TODO make this spec return oK/badPassword, not loggedIn/loggedOut
login as rforall p, q, r.
         server:Int
         -> (st:Int ~>
              (ST
              <{v:Map <Int >Int | select v server = loggedOut}
              >{v:Map <Int >Int | select v server = st}
              >{v:Int | v == st})
           -> ST <p >q >r)
        -> ST <p >q >r
login = \store -> bind getStr (\pw -> if pw == 42 then pure oK else pure badPassword)

{-
logout :: (store : Var) ->
         ST m () [store ::: Store LoggedIn :-> Store LoggedOut]
logout store = pure ()
-}

logout as map:(Map <Int >Int) ~> server:Int -> ST <{v:Map <Int >Int | v == map} >{v:Map <Int >Int | v == store map server loggedOut} >Unit
logout = Unit
-----------------------------------------------------------------------------


{-
disconnect :: (store : Int) -> ST m () [remove store (Store LoggedOut)]
disconnect store = delete store
-}

withConnection :: rforall p, q, a. init:(Map <Int >Int) ~> (server:Int ~> (ST <{v:Map <Int >Int | v = init } >{v:Map <Int >Int | select v server = loggedOut} >{v:Int | v = server}) -> ST <p >q >a) -> ST <p >q >a
withConnection = \f -> (bind new (\v -> f (thenn (write v loggedOut) (pure v))))

{- readSecret : (store : Var) -> ST m String [store ::: Store LoggedIn] -}
readSecret :: -- rforall p,q,a.
  m : (Map <Int >Int) ~>
  stor : {v: Int | select m v = loggedIn} ->
  ST <{v:Map <Int >Int | v = m} >{v:Map <Int >Int | v = m} >Int
readSecret = \stor -> (read stor)

{-
getData :: (ConsoleIO m, DataStore m) => ST m () []
getData = do st <- connect
             OK <- login st
                | BadPassword => do putStrLn "Failure"
                                    disconnect st
             secret <- readSecret st
             putStrLn ("Secret is: " ++ show secret)
             logout st
             disconnect st

-}

-- mm gets m, but somehow neither get st. the constraint under mm relating
-- to st involves kvar \<kvar##283\> (hmm, how did I find that kvar again?)
-- rs :: st:(Map <Int >Int) ~> server: { server : Int  | select st server = loggedIn } -> ST <{v:Map <Int >Int | v = st } >(Map >Int >Int) >Int
-- rs = \server -> readSecret server

getData :: it:(Map <Int >Int) ~> ST <{v:Map <Int >Int | v = it} >(Map <Int >Int) >Int
-- getData =  withConnection (\conn -> thenn conn (pure 0))
getData = withConnection (\conn ->
          bind conn (\server ->
          login server (\session ->
          bind session (\status ->
          if status == loggedIn
              then pure 0 -- thenn (readSecret server) (pure 0) -- (logout server)
              else pure 0))))
