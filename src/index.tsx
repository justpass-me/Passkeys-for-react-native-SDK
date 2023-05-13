import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'justpass-me-react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const JustPassMeReactNative = NativeModules.JustPassMeReactNative
  ? NativeModules.JustPassMeReactNative
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export const register = async (
  authenticationURL: string,
  extraClientHeaders?: { [key: string]: string }
) => {
  return JustPassMeReactNative.startRegistration(
    authenticationURL,
    extraClientHeaders
  );
};

export const authenticate = async (
  authenticationURL: string,
  extraClientHeaders?: { [key: string]: string }
) => {
  return JustPassMeReactNative.startAuthentication(
    authenticationURL,
    extraClientHeaders
  );
};
