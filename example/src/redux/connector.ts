import { connect, ConnectedProps } from 'react-redux';
import { UserState } from './reducers/user';
import { AnyAction, bindActionCreators } from 'redux';

import * as user_actions from './actions/user';
import { Dispatch } from 'redux';

export interface RootState {
  userState: UserState;
}

const mapStateToProps = (state: RootState) => ({
  currentUser: state.userState.currentUser,
  userData: state.userState.userData,
  autoSignIn: state.userState.autoSignIn,
});

const mapDispatchToProps = (dispatch: Dispatch<AnyAction>) => ({
  user_actions: bindActionCreators(user_actions, dispatch),
});

export const connector = connect(mapStateToProps, mapDispatchToProps);

export type BankReduxProps = ConnectedProps<typeof connector>;
