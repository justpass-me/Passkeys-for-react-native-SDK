import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'amwal-auth-react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const AmwalAuthReactNative = NativeModules.AmwalAuthReactNative
  ? NativeModules.AmwalAuthReactNative
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export class AmwalAuthClient {
  private clientURL: string;
  private authServiceURL: string;

  constructor(clientURL: string, authServiceURL: string) {
    this.clientURL = clientURL;
    this.authServiceURL = authServiceURL;
  }

  async register() {
    return AmwalAuthReactNative.startRegistration(
      this.clientURL,
      this.authServiceURL
    );
  }

  async authenticate(autoFill: boolean = false) {
    return AmwalAuthReactNative.startAuthentication(
      this.clientURL,
      this.authServiceURL,
      autoFill
    );
  }
}
