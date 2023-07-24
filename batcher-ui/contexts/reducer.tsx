import { AppState } from ".";
import { Actions } from "./actions";

const reducer = (state: AppState, action: Actions): AppState => {
  switch (action.type) {
    case "CONNECT_WALLET":
      return state;
    case "DISCONNECT_WALLET":
      return state;
    default:
      return {
        wallet: undefined,
        userAddress: undefined,
        userAccount: null,
        settings: null,
      };
  }
};

export default reducer;
