%lang starknet
# Import the serialize_word() function.
from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin,)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_equal

from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import (
    verify_ecdsa_signature,
)

struct ActionType:
    member firstValue: felt
    member secondValue: felt
    member thirdValue: felt
end

struct MatchStruct:
    member ship : felt
    member boat : felt
    member healthShip : felt
    member healthBoat : felt
    member roundNumber : felt
    member action1 : ActionType
    member action2 : ActionType
    member isStart : felt
end




########################################################################STORAGE#############################################################################
@storage_var
func roomToMatch(roomId : felt) -> (match : MatchStruct):
end

@storage_var
func roomId() -> (roomId : felt):
end

@storage_var
func nullAddress() -> (roomId : felt):
end


########################################################################EVENTS#############################################################################
@event
func MatchWasStarted(
    _roomId: felt, _roundNumber: felt
):
end

@event
func MatchWasEnded(
    _roomId: felt, _healthShip: felt, _healthBoat: felt, roundNumber: felt
):
end

@event
func RoundWasEnded(
    _roomId: felt, shipPart: felt, boatPart:felt, _healthShip: felt, _healthBoat: felt, _roundNumber: felt
):
end


@external
func createRoom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    senderAddress : felt
) -> (roomId : felt):

    let (_roomId) = roomId.read()
    let (caller_address) = get_caller_address()
    

    roomToMatch.write(
        _roomId,
        MatchStruct(
            ship=caller_address,
            boat='0x0',
            healthShip=3,
            healthBoat=3,
            roundNumber=1,
            action1=ActionType(0, 0, 0),
            action2=ActionType(0, 0, 0),
            isStart=0,
        )
    )
    
    roomId.write(_roomId + 1)

    return (roomId=_roomId)
end

@external
func joinRoom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _roomId : felt
    ):
    
    let (caller_address) = get_caller_address()

    let (session) = roomToMatch.read(_roomId)

    with_attr error_message("Incorrect room ID"):
        assert session.ship = '0x0'
    end

    with_attr error_message("Match already start"):
        assert_not_equal(session.isStart, 1)
    end

    roomToMatch.write(
        _roomId,
        MatchStruct(
            ship=session.ship,
            boat=caller_address,
            healthShip=3,
            healthBoat=3,
            roundNumber=1,
            action1=ActionType(0, 0, 0),
            action2=ActionType(0, 0, 0),
            isStart=1,
        )
    )
    
    MatchWasStarted.emit(_roomId=_roomId, _roundNumber=session.roundNumber)

    return ()
end

@external
func doMove{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _roomId : felt, signatures: ActionType
    ):
    
    alloc_locals

    let (caller_address) = get_caller_address()

    

    let (local session) = roomToMatch.read(_roomId)

    # with_attr error_message("Incorrect room ID"):
    #     assert session.ship = '0x0'
    # end

    
    # assert session.ship = caller_address 
    # assert session.boat = caller_address 
    

    # if session.ship == caller_address:
    
    #     if session.action1.firstValue == 0:
    #         if session.action1.secondValue == 0:
    #             if session.action1.thirdValue == 0:                 
    #                         roomToMatch.write(
    #                             _roomId,
    #                             MatchStruct(
    #                                 ship=session.ship,
    #                                 boat=session.boat,
    #                                 healthShip=session.healthShip,
    #                                 healthBoat=session.healthBoat,
    #                                 roundNumber=session.roundNumber,
    #                                 action1=signatures,
    #                                 action2=session.action2,
    #                                 isStart=session.isStart
    #                             )
    #                         )
    #             end
    #         end
    #     end
    
    # else:
    #     if session.action2.firstValue == 0:
    #         if session.action2.secondValue == 0:
    #             if session.action2.thirdValue == 0:                 
    #                         roomToMatch.write(
    #                             _roomId,
    #                             MatchStruct(
    #                                 ship=session.ship,
    #                                 boat=session.boat,
    #                                 healthShip=session.healthShip,
    #                                 healthBoat=session.healthBoat,
    #                                 roundNumber=session.roundNumber,
    #                                 action1=session.action1,
    #                                 action2=signatures,
    #                                 isStart=session.isStart
    #                             )
    #                         )         
    #             end
    #         end
                           
    #     else:
    #             assert 0 = 1
    #     end    
    # end 



    if session.ship == caller_address: 
        jmp caseSenderShip 
    end
    if caller_address == session.boat:
        jmp caseSenderBoat
    end

    assert 0 = 1
   

   
    
    caseSenderShip: 

        if session.action1.firstValue != 0:
            jmp caseDrop 
        end

        if session.action1.secondValue != 0:
            jmp caseDrop 
        end

        if session.action1.thirdValue != 0:
            jmp caseDrop 
        end

        

        roomToMatch.write(
                                _roomId,
                                MatchStruct(
                                    ship=session.ship,
                                    boat=session.boat,
                                    healthShip=session.healthShip,
                                    healthBoat=session.healthBoat,
                                    roundNumber=session.roundNumber,
                                    action1=signatures,
                                    action2=session.action2,
                                    isStart=session.isStart
                                )
                            )
        return()

    caseSenderBoat:
        jmp caseDrop if session.action2.firstValue != 0

        jmp caseDrop if session.action2.secondValue != 0

        jmp caseDrop if session.action2.thirdValue != 0

        roomToMatch.write(
                                _roomId,
                                MatchStruct(
                                    ship=session.ship,
                                    boat=session.boat,
                                    healthShip=session.healthShip,
                                    healthBoat=session.healthBoat,
                                    roundNumber=session.roundNumber,
                                    action1=signatures,
                                    action2=session.action2,
                                    isStart=session.isStart
                                )
                            )
        return()
        

    

    caseDrop:
      assert 0 = 1
    
    return()   
end


@external
func confirmMove{syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr : SignatureBuiltin*}(
    _roomId : felt
) -> ():

    
    alloc_locals

    let (caller_address) = get_caller_address()

    

    let (local session) = roomToMatch.read(_roomId)

    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(_roomId, 0)




    if session.boat == caller_address:
      jmp caseBoat  
    end
    if session.ship == caller_address:
        jmp caseShip
    end
    jmp caseFail

    caseShip:

    caseBoat:

    caseFail:


    roomToMatch.write(
        _roomId,
        MatchStruct(
            ship=caller_address,
            boat='0x0',
            healthShip=3,
            healthBoat=3,
            roundNumber=1,
            action1=ActionType(0, 0, 0),
            action2=ActionType(0, 0, 0),
            isStart=0,
        )
    )
    
    roomId.write(_roomId + 1)


    if validActionShip == validActionBoat:
        
        roomToMatch.write(
            _roomId,
            MatchStruct(
                ship=session.ship,
                boat=session.boat,
                healthShip=session.healthShip,
                healthBoat=session.healthBoat,
                roundNumber=session.roundNumber+1,
                action1=ActionType(0, 0, 0),
                action2=ActionType(0, 0, 0),
                isStart=session.isStart,
        )
    )

        RoundWasEnded.emit(_roomId, 1, 1, session.healthShip, session.healthBoat, session.roundNumber)

        return()
         
    end

    alloc_locals

    let (local _sessionRoundNumber) = session.roundNumber / 2  

    if session.roundNumber * 2 == _sessionRoundNumber:
        roomToMatch.write(
            _roomId,
            MatchStruct(
                ship=session.ship,
                boat=session.boat,
                healthShip=session.healthShip - 1,
                healthBoat=session.healthBoat,
                roundNumber=session.roundNumber+1,
                action1=ActionType(0, 0, 0),
                action2=ActionType(0, 0, 0),
                isStart=session.isStart,
            )
        )


    else:
        roomToMatch.write(
            _roomId,
            MatchStruct(
                ship=session.ship,
                boat=session.boat,
                healthShip=session.healthShip,
                healthBoat=session.healthBoat - 1,
                roundNumber=session.roundNumber+1,
                action1=ActionType(0, 0, 0),
                action2=ActionType(0, 0, 0),
                isStart=session.isStart,
        )
    )
    end

    if session.healthBoat == 0:
        jmp caseGameEnded
    end
    if session.healthShip == 0:
        jmp caseGameEnded
    end
    
    RoundWasEnded.emit(_roomId, 1, 1, session.healthShip, session.healthBoat, session.roundNumber)

    return()

    caseGameEnded:
        MatchWasEnded.emit(_roomId, session.healthShip, session.healthBoat, session.roundNumber)

    return ()
end


