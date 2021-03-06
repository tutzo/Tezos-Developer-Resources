[%%version 0.3]

(* KingOfTheTezos - Tezos version of King Of The Ether *)
(* Author - Postables *)
(* Version - 0.4 *)
(*
  //INTRODUCTION//

  The greetings and passings tributes are fixed. The idea behind this is that as time goes on, and tezos becomes more popular;
  it becomes more costly to usurp, which will have the side effect that as time goes on, and if tezos price keeps increasing being
  the current king, or even a king in the past, becomes a rarity so that only the most bravest of foes will dare usurp kings years from now.

  //INSTRUCTIONS//
  In order to usurp the previous king, you must pay more than their throne is worth, while still paying tribute to the creator (Postables! :D).
  You can increase your throne's warchest after claiming it as much as you want now that you have the creators blessing. With the creators blessing you can increase your war chest as much as you want, without paying additional tribute.

  Should you be usurped, before you have had the chance to supply your warchest, you receive nothing, and swept aside along with the rest of the fools who tried to seek victory. If however you managed to supply your war chest, you will be given riches beyond your wildest imaginations.

  TL;DR non "rp" rules:
    1) Pay a higher tezos amount that the current throne. This must be greater than the current throne plus the greetings and passings tribute.
    2) Attempt to supply your war chest after claiming the throne.
    3) If you manage to supply your warchest before you are usurped, you will be rewarded, equivalent to the war chest size.

    *Initial throne refers to the amount required to usurp the previous king
    *Warchest size is calculated by the difference of the current throne and your initial throne.
*) 
  
(* declare storage variables and their types *)
type storage = {
  greetings_tribute : tez                 ;
  passings_tribute  : tez                 ;
  penalty_tribute   : tez                 ;
  total_tributes    : tez                 ;
  king_key_hash     : key_hash            ;
  king_address      : address             ;
  creator_key_hash  : key_hash            ;
  creator_address   : address             ;
  throne            : tez                 ;
  war_chest         : tez                 ;
  banished          : (address, bool) map ;
}

let%init storage 
    (creator_key       : key_hash )
    (greetings_tribute : tez      ) 
    (passings_tribute  : tez      ) 
    (penalty_tribute   : tez      ) =
  {
    greetings_tribute = greetings_tribute                                         ;
    passings_tribute  = passings_tribute                                          ;
    penalty_tribute   = penalty_tribute                                           ;
    total_tributes    = (greetings_tribute + passings_tribute) + penalty_tribute  ;
    king_key_hash     = creator_key                                               ;
    king_address      = (Current.source())                                        ; 
    creator_key_hash  = creator_key                                               ;
    creator_address   = (Current.source())                                        ;
    throne            = 1tz                                                       ;
    war_chest         = 0tz                                                       ;
    banished          = (Map [KT1GE2AZhazRxGsAjRVkQccHcB2pvANXQWd7, false])       ;
  }

let%entry main (parameter : key_hash) (storage : storage) =
  let king_address = Current.source() in
  (* WIP: perform banish check *)
  let king_key_hash = parameter in
  if king_key_hash = storage.king_key_hash && king_address = storage.king_address then
    Current.failwith "temporary"
  else
    let throne_bid = Current.amount() in
    if throne_bid < storage.total_tributes then
      (* TODO: banish them *)
      Current.failwith "temporary"
    else
      let throne_bid_minus_tributes = throne_bid - storage.total_tributes in
      if throne_bid_minus_tributes <= storage.throne then
        Current.failwith "pitiful attempt to overthrow the thrown. pay more"
      else
      if storage.war_chest > 0tz then
        (* get the war chest *)
        let old_war_chest = storage.war_chest in
        (*update the war chest in storage*)
        let storage = storage.war_chest <- 0tz in
        (* get old throne size *)
        let old_throne = storage.throne in
        (* update the throne size in storaze *)
        let storage = storage.throne <- throne_bid_minus_tributes in
        (* get the old king key hash *)
        let old_king_key_hash = storage.king_key_hash in
        (* update the king address in storage *)
        let storage = storage.king_address <- king_address in
        (* update the king key hash in storage *)
        let storage = storage.king_key_hash <- king_key_hash in
        (* calculate old king refund amount *)
        let old_king_refund_amount = old_war_chest + old_throne in
        (* calculate creator refund amount *)
        let creator_refund_amount = storage.passings_tribute + storage.greetings_tribute in
        (* create sendable address for old king *)
        let old_king_sendable_address = Account.default old_king_key_hash in
        (* create sendable address for creator *)
        let creator_sendable_address = Account.default storage.creator_key_hash in
        (* create refund op for old king *)
        let old_king_refund_op = Contract.call old_king_sendable_address old_king_refund_amount () in
        (* create the refund op for creator *)
        let creator_refund_op = Contract.call creator_sendable_address creator_refund_amount () in
        ( [old_king_refund_op; creator_refund_op], storage)
      else
        (* get throne minus penalty *)
        let throne_minus_penalty = storage.throne - storage.penalty_tribute in
        (*update the throne with the new kings throne bid*)
        let storage = storage.throne <- throne_bid_minus_tributes in
        (* get the old king key hash *)
        let old_king_key_hash = storage.king_key_hash in
        (* update king_key_hash in storage *)
        let storage = storage.king_key_hash <- king_key_hash in
        (* update the king_address in storage *)
        let storage = storage.king_address <- king_address in
        (* create creator refund amount *)
        let creator_refund_amount = storage.total_tributes in
        (* create a sendable address for creator *)
        let creator_sendable_address = Account.default storage.creator_key_hash in
        (* create a refund op for creator *)
        let creator_refund_op = Contract.call creator_sendable_address creator_refund_amount () in
        (* create sendable addres for old king*)
        let old_king_sendable_address = Account.default old_king_key_hash in
        (* create refund op for old king *)
        let old_king_refund_op = Contract.call old_king_sendable_address throne_minus_penalty () in
        ( [creator_refund_op; old_king_refund_op], storage)
        
        
        
