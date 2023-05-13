import { UserActions, UserActionsDispatch } from '../reducers/user';
import auth from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';
import { IUserData } from '../models/user';

const usersDataCollection = firestore().collection<IUserData>('users');

type UserDispatchFunction = (a: UserActionsDispatch) => void;

export function clearData() {
  return (dispatch: UserDispatchFunction) => {
    dispatch({ type: UserActions.CLEAR_DATA });
  };
}

export const fetchUser = () => async (dispatch: UserDispatchFunction) => {
  try {
    const { currentUser } = auth();
    if (currentUser) {
      const docRef = usersDataCollection.doc(currentUser.uid);
      const userDataSnapshot = await docRef.get();
      const userData = userDataSnapshot.exists
        ? userDataSnapshot.data()
        : {
            balance: 0,
          };
      if (userData) {
        if (!userDataSnapshot.exists) {
          await docRef.set(userData, {
            merge: true,
          });
        }
        dispatch({
          type: UserActions.USER_STATE_CHANGE,
          updateUser: currentUser,
          updateData: userData,
        });
      }
    }
  } catch (e) {
    console.trace(e);
  }
};

export const signOut = () => async (dispatch: UserDispatchFunction) => {
  await auth().signOut();
  dispatch({
    type: UserActions.CLEAR_DATA,
  });
};
