import { FirebaseAuthTypes } from '@react-native-firebase/auth';

export interface IUserData {
  balance?: number;
}

export interface IUser {
  currentUser: FirebaseAuthTypes.User;
  userData: IUserData;
}
