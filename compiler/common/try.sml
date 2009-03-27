(* The Intel P to C/Pillar Compiler *)
(* Copyright (C) Intel Corporation *)

signature TRY = 
sig
  type 'a t = 'a option

  val try  : (unit -> 'a) -> 'a t
  val lift : ('a -> 'b) -> ('a -> 'b t)
  val exec : (unit -> unit) -> unit
  val ||   : (unit -> 'a t) List.t -> 'a t
  val or   : ('a -> 'b t) * ('a -> 'b t) -> ('a -> 'b t)
  val success : 'a -> 'a t
  val failure : unit -> 'a t
  val ? : bool -> unit t 
  val otherwise : 'a t * 'a -> 'a
  val bool : 'a t -> bool
  val option : 'a t -> 'a option


  val fail : unit -> 'a
  val <- : 'a t -> 'a
  val when : bool -> (unit -> 'a) -> 'a
  val require : bool -> unit

  structure V : sig
    val sub : 'a Vector.t * int -> 'a
    val singleton : 'a Vector.t -> 'a
    val lenEq : 'a Vector.t * int -> unit
  end

end

structure Try :> TRY = 
struct

                 
  type 'a t = 'a option
  exception Fail

  fun try f = 
      ((SOME (f())) handle Fail => NONE)

  val lift = 
   fn f => fn a => try (fn () => f a)

  fun exec f = ignore (try(f))

  fun || fs =
      (case fs
        of [] => NONE
         | f :: fs => 
           (case f ()
             of SOME a => SOME a
              | NONE => || fs))

  val or = 
   fn (f1, f2) => 
   fn args => 
      (case f1 args
        of NONE => f2 args
         | r => r)

  fun success a = SOME a
  fun failure a = NONE
  fun fail () = raise Fail
  fun <- t = 
      (case t
        of SOME a => a
         | NONE => raise Fail)

  fun otherwise (at, a) = 
      (case at
        of SOME b => b
         | NONE => a)

  fun ? b = if b then SOME () else NONE
  fun bool t = isSome t
  fun option t = t
  val require = <- o ?
  fun when b f = (require b;f())

  structure V = 
  struct
    fun sub (v, i) = 
        let
          val () = require ((i >= 0) andalso (i < Vector.length v))
          val r = Vector.sub (v, i)
        in r
        end

    fun singleton v = 
        let
          val () = require (Vector.length v = 1)
          val r = Vector.sub (v, 0)
        in r
        end

    fun lenEq (v, i) = require (Vector.length v = i)
  end

end
