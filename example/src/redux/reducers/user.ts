import { FirebaseAuthTypes } from '@react-native-firebase/auth';
import { IUserData } from '../models/user';

export enum UserActions {
  CLEAR_DATA = 'CLEAR_DATA',
  USER_STATE_CHANGE = 'USER_STATE_CHANGE',
  SIGN_OUT = 'SIGN_OUT',
}

export type UserState = {
  currentUser?: FirebaseAuthTypes.User;
  userData?: IUserData;
};

export type UserActionsDispatch = {
  type: UserActions;
  updateUser?: FirebaseAuthTypes.User;
  updateData?: IUserData;
};

const initialState: UserState = {
  currentUser: undefined,
  userData: undefined,
};

export const user = (state = initialState, action: UserActionsDispatch) => {
  console.log(action);
  switch (action.type) {
    case UserActions.USER_STATE_CHANGE:
      return {
        ...state,
        currentUser: action.updateUser,
        userData: action.updateData,
      };

    case UserActions.CLEAR_DATA:
      return initialState;

    default:
      return state;
  }
};
