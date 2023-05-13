/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * Generated with the TypeScript template
 * https://github.com/react-native-community/react-native-template-typescript
 *
 * @format
 */

import React from 'react';

import { NativeBaseProvider } from 'native-base';

import { NavigationContainer } from '@react-navigation/native';

import AuthStackNavigator from './screens/login';
import MainDrawerNavigator from './screens/main';

import { Provider } from 'react-redux';
import { createStore, applyMiddleware, Middleware } from 'redux';
import rootReducer from './redux/reducers';
import thunk from 'redux-thunk';
import { persistStore, persistReducer } from 'redux-persist';
import { PersistGate } from 'redux-persist/integration/react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createLogger } from 'redux-logger';
import auth, { FirebaseAuthTypes } from '@react-native-firebase/auth';

import { RootState, connector, BankReduxProps } from './redux/connector';

const persistConfig = {
  // Root?
  key: 'root',
  // Storage Method (React Native)
  storage: AsyncStorage,
  // Whitelist (Save Specific Reducers)
  whitelist: ['localState'],
  // Blacklist (Don't Save Specific Reducers)
  blacklist: ['userState'],
  debug: true,
};

let middleware: Middleware<
  {}, // Most middleware do not modify the dispatch return value
  RootState
>[] = [thunk];

if (__DEV__) {
  const logger = createLogger({ collapsed: true });
  middleware = [...middleware, logger];
} else {
  middleware = [...middleware];
}

const store = createStore(
  persistReducer(persistConfig, rootReducer),
  applyMiddleware(...middleware)
);

let persistor = persistStore(store);

const RootSelector = (props: BankReduxProps) => {
  // Handle user state changes
  React.useEffect(() => {
    const subscriber = auth().onAuthStateChanged(
      (user: FirebaseAuthTypes.User | null) => {
        console.log(user);
        props.user_actions.fetchUser();
      }
    );
    return subscriber; // unsubscribe on unmount
  }, [props.user_actions]);

  return props.currentUser ? <MainDrawerNavigator /> : <AuthStackNavigator />;
};

const BankRoot = connector(RootSelector);

const App = () => {
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <NavigationContainer>
          <NativeBaseProvider>
            <BankRoot />
          </NativeBaseProvider>
        </NavigationContainer>
      </PersistGate>
    </Provider>
  );
};

export default App;
