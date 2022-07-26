
type storage = int

type result = (operation list) * storage

type swap_x_to_y_param = {
    (* Amount of X tokens to sell for Y *)
    amount : nat ;
    (* Token address for X *)
    x_contract_address : address;
    (* Token address for Y *)
    y_contract_address: address;
    (* Order (full or partial) will be cancelled past this point *)
    deadline : timestamp ;
}
