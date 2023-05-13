import React from 'react';

import {
  DrawerNavigationState,
  ParamListBase,
  useTheme,
} from '@react-navigation/native';
import {
  createDrawerNavigator,
  DrawerContentScrollView,
  DrawerItemList,
  DrawerItem,
} from '@react-navigation/drawer';
import { createStackNavigator } from '@react-navigation/stack';

import MaterialIcons from 'react-native-vector-icons/MaterialIcons';

import Home from './Home';

import { connector, BankReduxProps } from '../../redux/connector';

import { NavigatorScreenParams } from '@react-navigation/native';
import {
  DrawerDescriptorMap,
  DrawerNavigationHelpers,
} from '@react-navigation/drawer/lib/typescript/src/types';

export type MainDrawerParamsList = {
  Home: undefined;
};

export type RootStackParamList = {
  Dashboard: NavigatorScreenParams<MainDrawerParamsList>;
  Register: undefined;
};

const Drawer = createDrawerNavigator<MainDrawerParamsList>();
const RootStack = createStackNavigator<RootStackParamList>();

const CustomDrawerContent = (
  props: {
    state: DrawerNavigationState<ParamListBase>;
    descriptors: DrawerDescriptorMap;
    navigation: DrawerNavigationHelpers;
  } & BankReduxProps
) => {
  return (
    <DrawerContentScrollView>
      <DrawerItemList {...props} />
      <DrawerItem
        label={'Sign Out'}
        labelStyle={{ alignSelf: 'flex-start' }}
        onPress={() => {
          props.user_actions.signOut();
        }}
        icon={({ color, size }) => (
          <MaterialIcons color={color} size={size} name="logout" />
        )}
      />
    </DrawerContentScrollView>
  );
};

const MainDrawerContent = connector(CustomDrawerContent);

const MainDrawerNavigator = connector(() => {
  const { colors } = useTheme();

  return (
    <Drawer.Navigator
      drawerContent={(props: any) => <MainDrawerContent {...props} />}
      screenOptions={{
        headerTintColor: colors.primary,
        drawerLabelStyle: {
          alignSelf: 'flex-start',
        },
      }}
    >
      <Drawer.Screen
        name="Home"
        component={Home}
        options={{
          drawerIcon: ({ color, size }) => (
            <MaterialIcons name="home" size={size} color={color} />
          ),
          title: 'Home',
        }}
      />
    </Drawer.Navigator>
  );
});

const RootStackScreen: React.FC<BankReduxProps> = () => {
  return (
    <RootStack.Navigator screenOptions={{ headerTruncatedBackTitle: 'Back' }}>
      <RootStack.Screen
        name="Dashboard"
        component={MainDrawerNavigator}
        options={{ headerShown: false }}
      />
    </RootStack.Navigator>
  );
};

export default connector(RootStackScreen);
