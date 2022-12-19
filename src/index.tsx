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

export const registerNotification = AmwalAuthReactNative.registerNotification;
