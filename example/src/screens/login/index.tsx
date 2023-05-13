import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import Signin from './Signin';
import CreateAccount from './CreateAccount';

export type AuthStackParamList = {
  Signin: undefined;
  CreateAccount: undefined;
};

const AuthStack = createStackNavigator<AuthStackParamList>();

const AuthStackNavigator: React.FC = () => {
  return (
    <AuthStack.Navigator>
      <AuthStack.Screen
        name="Signin"
        component={Signin}
        options={{ title: 'Login' }}
      />
      <AuthStack.Screen
        name="CreateAccount"
        component={CreateAccount}
        options={{ title: 'Create Account' }}
      />
    </AuthStack.Navigator>
  );
};

export default AuthStackNavigator;
