Case Study: AVL Trees {#avltree}
================================

\begin{code}
{- Example of AVL trees by michaelbeaumont -}

{-@ LIQUID "--no-termination" @-}
{-@ LIQUID "--totality" @-}

module AVL (AVL, empty, singleton, insert) where

-- Test
main = do
    mapM_ print [a, b, c, d]
  where
    a = singleton 5 
    b = insert 2 a
    c = insert 3 b
    d = insert 7 c

--------------------------------------------------------------------------------------------
-- | Datatype Definition ------------------------------------------------------------------- 
--------------------------------------------------------------------------------------------

data AVL a = Leaf | Node { key :: a, l::AVL a, r:: AVL a, ah :: Int } deriving Show

{-@ data AVL [ht] a = Leaf | Node { key :: a
                                  , l   :: AVLL a key
                                  , r   :: AVLR a key
                                  , ah  :: {v:Nat | HtBal l r && Ht v l r}
                                  }                                          @-}

-- | Left and Right Tree Ordering --------------------------------------------------------- 

{-@ type AVLL a X = AVL {v:a | v < X}                                        @-}
{-@ type AVLR a X = AVL {v:a | X < v}                                        @-}

-- | Height is actual height --------------------------------------------------------------

{-@ invariant {v:AVL a | 0 <= ht v && ht v = getHeight v} @-}

{-@ inv_proof  :: t:AVL a -> {v:_ | 0 <= ht t && ht t = getHeight t } @-}
inv_proof Leaf           = True 
inv_proof (Node k l r n) = inv_proof l && inv_proof r

-- | Logical Height Definition ------------------------------------------------------------ 

{-@ measure ht @-}
ht                :: AVL a -> Int
ht Leaf            = 0
ht (Node _ l r _) = if ht l > ht r then 1 + ht l else 1 + ht r


-- | Predicate Aliases -------------------------------------------------------------------- 

{-@ predicate HtBal L R      = -1 <= ht L - ht R && ht L - ht R <= 1                  @-}
{-@ predicate Ht N L R       = N = if (ht L) > (ht R) then (1 + ht L) else (1 + ht R) @-}
{-@ predicate HtDiff S T D   = ht S - ht T == D                                       @-}
{-@ predicate EqHt S T       = HtDiff S T 0                                           @-}
{-@ predicate NoHeavy    T   = bFac T == 0                                            @-}
{-@ predicate LeftHeavy  T   = bFac T == 1                                            @-}
{-@ predicate RightHeavy T   = bFac T == -1                                           @-}



--------------------------------------------------------------------------------------------
-- | Constructor & Destructor  -------------------------------------------------------------
--------------------------------------------------------------------------------------------

-- | Smart Constructor (fills in height field) ---------------------------------------------

{-@ tree   :: x:a -> l:AVLL a x -> r:{AVLR a x | HtBal l r} -> {v:AVL a | Ht (ht v) l r} @-}
tree v l r = Node v l r (mkHt l r)

{-@ mkHt   :: l:_ -> r:_ -> {v:Nat | Ht v l r} @-}
mkHt       :: AVL a -> AVL a -> Int
mkHt l r   = if hl > hr then 1 + hl else 1 + hr
  where
    hl     = getHeight l
    hr     = getHeight r


-- | Compute Tree Height -------------------------------------------------------------------
    
{-@ measure getHeight @-}
{-@ getHeight            :: t:_ -> {v:Nat | v = ht t} @-}
getHeight Leaf           = 0
getHeight (Node _ _ _ n) = n


-- | Compute Balance Factor ----------------------------------------------------------------

{-@ measure bFac @-}
{-@ bFac :: t:AVL a -> {v:Int | v = bFac t && 0 <= v + 1 && v <= 1} @-}
bFac Leaf           = 0
bFac (Node _ l r _) = getHeight l - getHeight r 

{-@ htDiff :: s:AVL a -> t: AVL a -> {v: Int | HtDiff s t v} @-}
htDiff     :: AVL a -> AVL a -> Int
htDiff l r = getHeight l - getHeight r


--------------------------------------------------------------------------------------------
-- | API: Empty ---------------------------------------------------------------------------- 
--------------------------------------------------------------------------------------------
             
{-@ empty :: {v: AVL a | ht v == 0} @-}
empty = Leaf

--------------------------------------------------------------------------------------------
-- | API: Singleton ------------------------------------------------------------------------ 
--------------------------------------------------------------------------------------------

{-@ singleton :: a -> {v: AVL a | ht v == 1 } @-}
singleton a = tree a empty empty 

--------------------------------------------------------------------------------------------
-- | API: Insert --------------------------------------------------------------------------- 
--------------------------------------------------------------------------------------------

{-@ insert :: a -> s:AVL a -> {t: AVL a | EqHt t s || HtDiff t s 1 } @-}
insert a Leaf             = singleton a
insert a t@(Node v _ _ _) = case compare a v of
    LT -> insL a t 
    GT -> insR a t
    EQ -> t

{-@ insL :: x:a -> s:{AVL a | x < key s && ht s > 0} -> {t: AVL a | EqHt t s || HtDiff t s 1 } @-}
insL a (Node v l r _)
  | siblDiff > 1 && bl' > 0  = rebalanceLL v l' r
  | siblDiff > 1 && bl' < 0  = rebalanceLR v l' r
  | siblDiff > 1             = rebalanceL0 v l' r
  | siblDiff <= 1            = tree v l' r
  where
    l'                       = insert a l
    siblDiff                 = htDiff l' r
    bl'                      = bFac l'
   
{-@ insR :: x:a -> s:{AVL a | key s < x && ht s > 0} -> {t: AVL a | EqHt t s || HtDiff t s 1 } @-}
insR a (Node v l r _)
  | siblDiff > 1 && br' > 0  = rebalanceRL v l r'
  | siblDiff > 1 && br' < 0  = rebalanceRR v l r'
  | siblDiff > 1             = rebalanceR0 v l r'
  | siblDiff <= 1            = tree v l r'
  where
    siblDiff                 = htDiff r' l
    r'                       = insert a r
    br'                      = bFac r'

{-@ rebalanceL0 :: x:a -> l:{AVLL a x | NoHeavy l} -> r:{AVLR a x | HtDiff l r 2} -> {t:AVL a | ht t = ht l + 1 } @-}
rebalanceL0 v (Node lv ll lr _) r                   = tree lv ll (tree v lr r)

{-@ rebalanceLL :: x:a -> l:{AVLL a x | LeftHeavy l } -> r:{AVLR a x | HtDiff l r 2} -> {t:AVL a | EqHt t l} @-}
rebalanceLL v (Node lv ll lr _) r                   = tree lv ll (tree v lr r)

{-@ rebalanceLR :: x:a -> l:{AVLL a x | RightHeavy l } -> r:{AVLR a x | HtDiff l r 2} -> {t: AVL a | EqHt t l } @-}
rebalanceLR v (Node lv ll (Node lrv lrl lrr _) _) r = tree lrv (tree lv ll lrl) (tree v lrr r)

{-@ rebalanceR0 :: x:a -> l: AVLL a x -> r: {AVLR a x | NoHeavy r && HtDiff r l 2 } -> {t: AVL a | ht t = ht r + 1} @-}
rebalanceR0 v l (Node rv rl rr _)                   = tree rv (tree v l rl) rr

{-@ rebalanceRR :: x:a -> l: AVLL a x -> r:{AVLR a x | RightHeavy r && HtDiff r l 2 } -> {t: AVL a | EqHt t r } @-}
rebalanceRR v l (Node rv rl rr _)                   = tree rv (tree v l rl) rr

{-@ rebalanceRL :: x:a -> l: AVLL a x -> r:{AVLR a x | LeftHeavy r && HtDiff r l 2} -> {t: AVL a | EqHt t r } @-}
rebalanceRL v l (Node rv (Node rlv rll rlr _) rr _) = tree rlv (tree v l rll) (tree rv rlr rr) 
\end{code}
