import type { AxiosInstance } from 'axios';
import axios from 'axios';
import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

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

const AmwalNativeEventEmitter = new NativeEventEmitter(AmwalAuthReactNative);

export interface CredentialCreationPublicKey {
  challenge: string;
  user: {
    id: string;
    name: string;
    displayName: string;
  };
  rp: {
    id: string;
    name: string;
  };
  attestation?: string;
  authenticatorSelection?: {
    userVerification?: string;
    authenticatorAttachment?: string;
    residentKey?: string;
    requireResidentKey?: boolean;
  };
}

export interface CredentialAssertionPublicKey {
  challenge: string;
  rpId: string;
  userVerification?: string;
}

export interface RegistrationCredentialJSON {
  id: string;
  rawId: string;
  type: 'public-key';
  response: {
    clientDataJSON: string;
    attestationObject: string;
  };
}

export interface AuthenticationCredentialJSON {
  id: string;
  rawId: string;
  type: 'public-key';
  response: {
    authenticatorData: string;
    clientDataJSON: string;
    signature: string;
    userHandle: string;
  };
}

export const isAvailable: boolean = AmwalAuthReactNative?.isAvailable ?? false;

export const startRegistration = isAvailable
  ? async (creationOptionsJSON: CredentialCreationPublicKey) => {
      return AmwalAuthReactNative.startRegistration(
        creationOptionsJSON
      ) as Promise<RegistrationCredentialJSON>;
    }
  : undefined;

export const startAuthentication = isAvailable
  ? async (
      requestOptionsJSON: CredentialAssertionPublicKey,
      autoFill: boolean
    ) => {
      return AmwalAuthReactNative.startAuthentication(
        requestOptionsJSON,
        autoFill
      ) as Promise<AuthenticationCredentialJSON>;
    }
  : undefined;

export const presentAuthenticationModal = isAvailable
  ? async (
      requestOptionsJSON: CredentialAssertionPublicKey,
      modalContent: string
    ) => {
      return AmwalAuthReactNative.presentAuthenticationModal(
        requestOptionsJSON,
        modalContent
      ) as Promise<AuthenticationCredentialJSON>;
    }
  : undefined;

export const registerNotification: () => Promise<string> =
  AmwalAuthReactNative.registerNotification;

export const onNotificationMessage = (callback: (message: any) => void) => {
  let unsubscribe = false;
  const repeatCallback = () => {
    AmwalAuthReactNative.setNotificationMessageCallback((message: any) => {
      if (!unsubscribe) {
        callback(message);
        repeatCallback();
      }
    });
  };
  repeatCallback();
  const subscription = AmwalNativeEventEmitter.addListener(
    'AmwalAuthNotificationEvent',
    callback
  );
  return () => {
    subscription.remove();
    unsubscribe = true;
  };
};

export class AmwalAuthClient {
  private authServiceURL: string;
  private apiClient: AxiosInstance;

  constructor(clientURL: string, authServiceURL: string) {
    this.authServiceURL = authServiceURL;
    this.apiClient = axios.create({
      baseURL: clientURL,
      withCredentials: true,
    });
  }

  async register() {
    const startRegistrationResponse = await this.apiClient.get(
      '/oidc/authenticate/',
      {
        headers: {
          'AMWAL-PLATFORM': 'app',
        },
      }
    );
    const { publicKey } = startRegistrationResponse.data;
    if (startRegistration && publicKey) {
      const registrationCredential = await startRegistration(publicKey);
      const registrationResponse = await this.apiClient.post(
        this.authServiceURL + '/fido2/reg_complete/',
        registrationCredential
      );
      if (registrationResponse.data.status === 'ERR') {
        throw new Error(registrationResponse.data.message);
      }
      const backReponse = await this.apiClient.get(
        this.authServiceURL + '/back_to_client/',
        {
          headers: {
            'AMWAL-PLATFORM': 'app',
          },
        }
      );
      return backReponse.data;
    } else {
      throw new Error('No publicKey found');
    }
  }

  async authenticate() {
    const startAuthResponse = await this.apiClient.get('/oidc/authenticate/', {
      headers: {
        'AMWAL-PLATFORM': 'app',
      },
    });
    const { publicKey } = startAuthResponse.data;
    if (startAuthentication && publicKey) {
      const authCredential = await startAuthentication(publicKey, false);
      const authResponse = await this.apiClient.post(
        this.authServiceURL + '/fido2/complete_auth/',
        authCredential
      );
      console.log('authResponse.data', authResponse.data);
      if (authResponse.data.status === 'OK') {
        const bankResp = await this.apiClient.get(
          this.authServiceURL + '/back_to_client/',
          {
            headers: {
              'AMWAL-PLATFORM': 'app',
            },
          }
        );
        return bankResp.data;
      } else {
        throw new Error(authResponse.data.message);
      }
    } else {
      throw new Error('No publicKey found');
    }
  }
}
